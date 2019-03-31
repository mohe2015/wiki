(in-package :cl-user)
(defpackage spickipedia.web
  (:use :cl
        :caveman2
        :spickipedia.config
        :spickipedia.view
        :spickipedia.db
	:spickipedia.sanitize
	:spickipedia.tsquery-converter
	:spickipedia.parenscript
        :mito
	:sxql
	:ironclad
	:sanitize
	:bcrypt
	:alexandria
	:cl-who
	:cl-base64)
  (:shadowing-import-from :ironclad :xor)
  (:export :*web*))
(in-package :spickipedia.web)

(declaim (optimize (debug 3)))

(defparameter *default-cost* 13
  "The default value for the COST parameter to HASH.")

(defclass <web> (<app>) ())
(defvar *web* (make-instance '<web>))
(clear-routing-rules *web*)

(djula::def-tag-compiler :file-hash (path)
  (lambda (stream)
    (princ (byte-array-to-hex-string (digest-file :sha512 path)) stream)))

(defmacro with-user (&body body)
  `(if (gethash :user *SESSION*)
       (let ((user (mito:find-dao 'user :id (gethash :user *SESSION*))))
	 ,@body)
       (throw-code 401)))

(defun random-base64 ()
  (usb8-array-to-base64-string (random-data 64)))

(defmacro with-group (groups &body body)
  `(if (member (user-group user) ,groups)
       (progn
	 ,@body)
       (throw-code 403)))

(defmacro params-form (params-symb lambda-list)
  (let ((pair (gensym "PAIR")))
    `(nconc ,@(loop for arg in lambda-list
                 collect (destructuring-bind (arg &optional default specified)
                             (if (consp arg) arg (list arg))
                           (declare (ignore default specified))
                           `(let ((,pair (assoc ,(if (or (string= arg :captures)
                                                         (string= arg :splat))
                                                     (intern (symbol-name arg) :keyword)
                                                     (symbol-name arg))
                                                ,params-symb
                                                :test #'string=)))
                              (if ,pair
                                  (list ,(intern (symbol-name arg) :keyword) (cdr ,pair))
				  nil)))))))

(defparameter *VERSION* "1")

(defun valid-csrf () ;; TODO secure string compare
  (string= (my-session-csrf-token *SESSION*) (assoc "csrf_token" (lack.request:request-query-parameters ningle:*request*))))

(defun hash-contents (content)
  (ironclad:byte-array-to-hex-string 
   (ironclad:digest-sequence 
    :sha256
    (ironclad:ascii-string-to-byte-array content))))

(defun hash-contents-vector (content)
  (ironclad:byte-array-to-hex-string 
   (ironclad:digest-sequence 
    :sha256
    content)))

(defun cache ()
  (setf (getf (response-headers *response*) :cache-control) "public, max-age=3600") ;; one hour
  (setf (getf (response-headers *response*) :vary) "Accept-Encoding"))

(defun cache-forever ()
  (setf (getf (response-headers *response*) :cache-control) "max-age=31556926")
  (setf (getf (response-headers *response*) :vary) "Accept-Encoding")
  (setf (getf (response-headers *response*) :etag) *VERSION*)) ;; TODO fix this dirty implementation

(defmacro with-cache-forever (&body body)
  `(progn
    (cache-forever)
    (if (equal (gethash "if-none-match" (request-headers *request*)) *VERSION*)
	(throw-code 304)
	(progn
	  ,@body))))

(defmacro with-cache (key &body body)
  `(progn
     (cache)
     (let* ((key-hash (hash-contents ,key)))
       (if (equal (gethash "if-none-match" (request-headers *request*)) (concatenate 'string "W/\"" key-hash "\""))
	   (throw-code 304)
	   (progn
	     (setf (getf (response-headers *response*) :etag) (concatenate 'string "W/\"" key-hash "\""))
	     (progn ,@body))))))

(defmacro with-cache-vector (key &body body)
  `(progn
     (cache)
     (let* ((key-hash (hash-contents-vector ,key)))
       (if (equal (gethash "if-none-match" (request-headers *request*)) (concatenate 'string "W/\"" key-hash "\""))
	   (throw-code 304)
	   (progn
	     (setf (getf (response-headers *response*) :etag) (concatenate 'string "W/\"" key-hash "\""))
	     (progn ,@body))))))

(defun basic-headers ()
  (setf (getf (response-headers *response*) :x-frame-options) "DENY")
  (setf (getf (response-headers *response*) :content-security-policy) "default-src 'none'; script-src 'self'; img-src * data: ; style-src 'self' 'unsafe-inline'; font-src 'self'; connect-src 'self'; frame-src www.youtube.com youtube.com; frame-ancestors 'none';") ;; TODO the inline css from the whsiwyg editor needs to be replaced - write an own editor sometime ;; WON'T WORK BECAUSE MATH EDITOR ALSO USES IT
  (setf (getf (response-headers *response*) :x-xss-protection) "1; mode=block")
  (setf (getf (response-headers *response*) :x-content-type-options) "nosniff")
  (setf (getf (response-headers *response*) :referrer-policy) "no-referrer"))

(defmacro my-defroute (method path permissions params content-type &body body)
  (let ((params-var (gensym "PARAMS")))
    `(setf (ningle/app:route *web* ,path :method ,method)
	   (lambda (,params-var)
	     (basic-headers)
	     (destructuring-bind (&key _parsed ,@params &allow-other-keys)
		 (append (list
                           :_parsed
                           (CAVEMAN2.NESTED-PARAMETER:PARSE-PARAMETERS ,params-var))
			 (params-form ,params-var ,params))
	       (declare (ignorable _parsed))
	       (setf (getf (response-headers *response*) :content-type) ,content-type)
	       (with-connection (db)
		 ,(if permissions
		      `(with-user
			 (with-group ',permissions
			   ,@body))
		      `(progn ,@body))))))))

(my-defroute :GET "/api/wiki/:title" (:admin :user :anonymous) (title) "application/json"
  (let* ((article (mito:find-dao 'wiki-article :title title)))
    (if (not article)
        (throw-code 404))
    (let ((revision (mito:select-dao 'wiki-article-revision (where (:= :article article)) (order-by (:desc :id)) (limit 1))))
      (if (not revision)
	  (throw-code 404))
      (json:encode-json-to-string
       `((content . ,(clean (wiki-article-revision-content (car revision)) *sanitize-spickipedia*))
	 (categories . ,(mapcar #'(lambda (v) (wiki-article-revision-category-category v)) (retrieve-dao 'wiki-article-revision-category :revision (car revision)))))))))

(my-defroute :GET "/api/revision/:id" (:admin :user) (id) "text/html"
  (let* ((revision (mito:find-dao 'wiki-article-revision :id (parse-integer id))))
    (if (not revision)
	(throw-code 404))
    (clean (wiki-article-revision-content revision) *sanitize-spickipedia*)))

;; SELECT article_id FROM wiki_article_revision WHERE id = 8;
;; SELECT id FROM wiki_article_revision WHERE article_id = 1 and id < 8 ORDER BY id DESC LIMIT 1;
;; SELECT id FROM wiki_article_revision WHERE article_id = (SELECT article_id FROM wiki_article_revision WHERE id = 8) and id < 8 ORDER BY id DESC LIMIT 1;
(my-defroute :GET "/api/previous-revision/:the-id" (:admin :user) (the-id) "text/html"
  (let* ((id (parse-integer the-id))
	 (query (dbi:prepare *connection* "SELECT id FROM wiki_article_revision WHERE article_id = (SELECT article_id FROM wiki_article_revision WHERE id = ?) and id < ? ORDER BY id DESC LIMIT 1;"))
	 (result (dbi:execute query id id))
	 (previous-id (getf (dbi:fetch result) :|id|)))
    (if previous-id
	(clean (wiki-article-revision-content (mito:find-dao 'wiki-article-revision :id previous-id)) *sanitize-spickipedia*)
	nil)))

(my-defroute :POST "/api/wiki/:title" (:admin :user) (title |summary| |html|) "text/html"
  (let* ((article (mito:find-dao 'wiki-article :title title))
	 (categories (cdr (assoc "categories" _parsed :test #'string=))))
    (if (not article)
	(setf article (mito:create-dao 'wiki-article :title title)))
    (let ((revision (mito:create-dao 'wiki-article-revision :article article :author user :summary |summary| :content |html|)))
      (loop for category in categories do
	   (mito:create-dao 'wiki-article-revision-category :revision revision :category category)))
    nil))

(my-defroute :POST "/api/quiz/create" (:admin :user) () "text/html"
  (format nil "~a" (object-id (mito:create-dao 'quiz :creator user))))

(my-defroute :POST "/api/quiz/:the-quiz-id" (:admin :user) (the-quiz-id |data|) "text/html"
  (let* ((quiz-id (parse-integer the-quiz-id)))
    (format nil "~a" (object-id (create-dao 'quiz-revision :quiz (find-dao 'quiz :id quiz-id) :content |data| :author user)))))

(my-defroute :GET "/api/quiz/:the-id" (:admin :user) (the-id)  "application/json"
  (let* ((quiz-id (parse-integer the-id))
	 (revision (mito:select-dao 'quiz-revision (where (:= :quiz (find-dao 'quiz :id quiz-id))) (order-by (:desc :id)) (limit 1))))
    (quiz-revision-content (car revision))))
    
    
(my-defroute :GET "/api/history/:title" (:admin :user) (title) "application/json"
  (let* ((article (mito:find-dao 'wiki-article :title title)))
    (if article
	(json:encode-json-to-string
	 (mapcar #'(lambda (r) `((id   . ,(object-id r))
				 (user . ,(user-name (wiki-article-revision-author r)))
				 (summary . ,(wiki-article-revision-summary r))
				 (created . ,(local-time:format-timestring nil (mito:object-created-at r)))
				 (size    . ,(length (wiki-article-revision-content r)))))
		 (mito:select-dao 'wiki-article-revision (where (:= :article article)) (order-by (:desc :created-at)))))
	(throw-code 404))))

(my-defroute :GET "/api/search/:query" (:admin :user :anonymous) (query) "application/json"
  (let* ((searchquery (tsquery-convert query))
	 (query (dbi:prepare *connection* "SELECT a.title, ts_rank_cd((setweight(to_tsvector(a.title), 'A') || setweight(to_tsvector((SELECT content FROM wiki_article_revision WHERE article_id = a.id ORDER BY id DESC LIMIT 1)), 'D')), query) AS rank, ts_headline(a.title || (SELECT content FROM wiki_article_revision WHERE article_id = a.id ORDER BY id DESC LIMIT 1), to_tsquery(?)) FROM wiki_article AS A, to_tsquery(?) query WHERE query @@ (setweight(to_tsvector(a.title), 'A') || setweight(to_tsvector((SELECT content FROM wiki_article_revision WHERE article_id = a.id ORDER BY id DESC LIMIT 1)), 'D')) ORDER BY rank DESC;"))
	 (result (dbi:execute query searchquery searchquery)))
    (json:encode-json-to-string (mapcar #'(lambda (r) `((title . ,(getf r :|title|))
							(rank  . ,(getf r :|rank|))
							(summary . ,(getf r :|ts_headline|)))) (dbi:fetch-all result)))))

(my-defroute :GET "/api/articles" (:admin :user :anonymous) () "application/json"
  (let* ((articles (mito:select-dao 'wiki-article)))
    (json:encode-json-to-string (mapcar 'wiki-article-title articles))))

(my-defroute :POST "/api/upload" (:admin :user) (|file|) "text/html"
  (let* ((filecontents (nth 0 |file|))
	 (filehash (byte-array-to-hex-string (digest-stream :sha512 filecontents)))	 ;; TODO whitelist mimetypes TODO verify if mimetype is correct
	 (newpath (merge-pathnames (concatenate 'string "uploads/" filehash) *default-pathname-defaults*)))
   ;; (break)
    (with-open-file (stream newpath :direction :output :if-exists :supersede :element-type '(unsigned-byte 8))
      (write-sequence (slot-value filecontents 'vector) stream))
    filehash))

;; noauth
(my-defroute :POST "/api/login" nil (|name| |password|) "text/html"
  (format t "~A ~A~%" |name| |password|)
  (let* ((user (mito:find-dao 'user :name |name|)))
    (if (and user (password= |password| (user-hash user)))                        ;; TODO prevent timing attack
	(progn
	  ;;(regenerate-session *SESSION*) ;; TODO this is IMPORTANT WE NEED TO FIX THIS THIS IS IMPORTANT WE NEED TO FIX THIS
	  (setf (gethash :user *SESSION*) (object-id user))
	  nil)
	(throw-code 403))))

;; noauth
(my-defroute :POST "/api/logout" (:admin :user :anonymous) () "text/html"
  (setf (gethash :user *SESSION*) nil)
  nil)

;; noauth
(my-defroute :GET "/api/killswitch" nil () "text/html"
  (sb-ext:quit))

(defun starts-with-p (str1 str2)
  "Determine whether `str1` starts with `str2`"
  (let ((p (search str2 str1)))
    (and p (= 0 p))))

(defun get-safe-mime-type (file)
  (let ((mime-type (mimes:mime file)))
    (if (starts-with-p mime-type "image/")
	mime-type
	(progn
	  (format t "Forbidden mime-type: ~a~%" mime-type)
	  "text/plain"))))

;; noauth cache
(my-defroute :GET "/api/file/:name" (:admin :user :anonymous) (name) (get-safe-mime-type (merge-pathnames (concatenate 'string "uploads/" name)))
  (merge-pathnames (concatenate 'string "uploads/" name)))

(my-defroute :GET "/js/:file" nil (file) "application/javascript"
  (with-cache (read-file-into-string (concatenate 'string "js/" file))
    (file-js-gen (concatenate 'string "js/" file)))) ;; TODO local file inclusion

(defparameter *template-registry* (make-hash-table :test 'equal))

(defun render (template-path &optional &rest env)
  (let ((template (gethash template-path *template-registry*)))
    (unless template
      (setf template (djula:compile-template* (princ-to-string template-path)))
      (setf (gethash template-path *template-registry*) template))
    (apply #'djula:render-template*
           template nil
           env)))

(SETF (HTML-MODE) :HTML5)

(defmacro sexp-to-html (file)
  `(with-html-output-to-string (jo nil :prologue t :indent t)
    ,(with-open-file (s file)
	       (read s))))

;; TODO convert this to my-defroute because otherwise we cant use the features of it like  (basic-headers)
(defroute ("/.*" :regexp t :method :GET) ()
  (basic-headers)
  (let ((path (merge-pathnames *static-directory* (lack.request:request-path-info ningle:*request*))))
    (if (and (cl-fad:file-exists-p path) (not (cl-fad:directory-exists-p path)))
	(with-cache-vector (read-file-into-byte-vector path)
	  "path")
	(sexp-to-html "src/index.lisp"))))

;; Error pages

(defmethod on-exception ((app <web>) (code (eql 404)))
  (declare (ignore app))
  (merge-pathnames #P"_errors/404.html"
                   *template-directory*))
