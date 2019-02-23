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
	:spickipedia.permissions
        :mito
	:sxql
	:ironclad
	:sanitize
	:bcrypt
	:cl-base64)
  (:export :*web*))
(in-package :spickipedia.web)

(declaim (optimize (debug 3)))

(defparameter *default-cost* 13
  "The default value for the COST parameter to HASH.")

(defclass <web> (<app>) ())
(defvar *web* (make-instance '<web>))
(clear-routing-rules *web*)

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

(defmacro make-keyword (name) (values (intern (string name) "KEYWORD")))

(defun params-form (params-symb lambda-list)
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

(defmacro my-defroute (method path permissions params content-type &body body)
  (let ((params-var (gensym "PARAMS")))
    `(setf (ningle/app:route *web* ,path :method ,method)
	   (lambda (,params-var)
	     (setf (getf (response-headers *response*) :content-type) ,content-type)
	     (destructuring-bind (&key ,@params &allow-other-keys) ,(params-form params-var params)
	       (with-connection (db)
		 ,(if permissions
		      `(with-user
			 (with-group ',permissions
			   ,@body))
		      `(progn ,@body))))))))

(my-defroute :GET "/api/wiki/:title" (:admin :user :anonymous) (title) "text/html"
  (let* ((article (mito:find-dao 'wiki-article :title title)))
    (if (not article)
        (throw-code 404))
    (let ((revision (mito:select-dao 'wiki-article-revision (where (:= :article article)) (order-by (:desc :id)) (limit 1))))
      (if (not revision)
	  (throw-code 404))
      (clean (wiki-article-revision-content (car revision)) *sanitize-spickipedia*))))

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
  (let* ((article (mito:find-dao 'wiki-article :title title)))
    (if (not article)
	(setf article (mito:create-dao 'wiki-article :title title)))
    (mito:create-dao 'wiki-article-revision :article article :author user :summary |summary| :content |html|)
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
  (let* ((filepath (nth 0 |file|))
	 ;; (filetype (nth 2 (hunchentoot:post-parameter "file")))
	 (filehash (byte-array-to-hex-string (digest-file :sha512 filepath)))	 ;; TODO whitelist mimetypes TODO verify if mimetype is correct
	 (newpath (merge-pathnames (concatenate 'string "uploads/" filehash) *default-pathname-defaults*)))
	 (print newpath)
	 (copy-file filepath newpath :overwrite t)
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

;; noauth cache
(my-defroute :GET "/api/file/:name" (:admin :user :anonymous) (name) "text/html"
  (handle-static-file (merge-pathnames (concatenate 'string "uploads/" name))))

(my-defroute :GET "/js/:file" nil (file) "application/javascript"
  (file-js-gen (concatenate 'string "js/" (subseq file 0 (- (length file) 3)) ".lisp")))

;; this is used to get the most used browsers to decide for future features (e.g. some browsers don't support new features so I won't use them if many use such a browser)
(defun track ()
  (with-open-file (str "track.json"
                     :direction :output
                     :if-exists :append
                     :if-does-not-exist :create)
  (format str "~a~%" (json:encode-json-to-string (acons "user" (my-session-user *session*) (headers-in*))))))

(defparameter *template-registry* (make-hash-table :test 'equal))

(defun render (template-path &optional &rest env)
  (let ((template (gethash template-path *template-registry*)))
    (unless template
      (setf template (djula:compile-template* (princ-to-string template-path)))
      (setf (gethash template-path *template-registry*) template))
    (apply #'djula:render-template*
           template nil
           env)))

(defroute ("/.*" :regexp t :method :GET) ()
  (render #P"index.html" :js-files (js-files)))

;; Error pages

(defmethod on-exception ((app <web>) (code (eql 404)))
  (declare (ignore app))
  (merge-pathnames #P"_errors/404.html"
                   *template-directory*))
