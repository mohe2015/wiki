(in-package :cl-user)
(defpackage spickipedia.web
  (:use :cl
        :caveman2
        :spickipedia.config
        :spickipedia.view
        :spickipedia.db
        :mito
        :sxql)
  (:export :*web*))
(in-package :spickipedia.web)


(defparameter *default-cost* 13
  "The default value for the COST parameter to HASH.")



;; for @route annotation
(syntax:use-syntax :annot)

;;
;; Application

(defclass <web> (<app>) ())
(defvar *web* (make-instance '<web>))
(clear-routing-rules *web*)

;;
;; Routing rules

(defroute "/" ()
  (render #P"index.html"))

(defroute "/test" (&key |name|)
  (format nil "Welcome, ~A" |name|))

(defun random-base64 ()
  (usb8-array-to-base64-string (random-data 64)))

(defroute ("/api/wiki" :method :GET) ()
  (let* ((title (subseq (script-name* *REQUEST*) 10)) (article (mito:find-dao 'wiki-article :title title)))
    (if (not article)
	(progn
	  (setf (return-code* *reply*) 404)
	  (next-route))) ;; TODO check if that works
    (let ((revision (mito:select-dao 'wiki-article-revision (where (:= :article article)) (order-by (:desc :id)) (limit 1))))
      (if (not revision)
	  (progn
	    (setf (return-code* *reply*) 404)
	    (next-route))) ;; TODO check if that works
      (clean (wiki-article-revision-content (car revision)) *sanitize-spickipedia*))))

(defroute ("/api/revision" :method :GET) ()
  (let* ((id (subseq (script-name* *REQUEST*) 14))
	 (revision (mito:find-dao 'wiki-article-revision :id (parse-integer id))))
    (if (not revision)
	(progn
	  (setf (return-code*) 404)
	  (next-route))) ;; TODO check if that works
    (clean (wiki-article-revision-content revision) *sanitize-spickipedia*)))

;; SELECT article_id FROM wiki_article_revision WHERE id = 8;
;; SELECT id FROM wiki_article_revision WHERE article_id = 1 and id < 8 ORDER BY id DESC LIMIT 1;
;; SELECT id FROM wiki_article_revision WHERE article_id = (SELECT article_id FROM wiki_article_revision WHERE id = 8) and id < 8 ORDER BY id DESC LIMIT 1;
(defroute ("/api/previous-revision" :method :GET) ()
  (let* ((id (parse-integer (subseq (script-name* *REQUEST*) 23)))
	 (query (dbi:prepare *connection* "SELECT id FROM wiki_article_revision WHERE article_id = (SELECT article_id FROM wiki_article_revision WHERE id = ?) and id < ? ORDER BY id DESC LIMIT 1;"))
	 (result (dbi:execute query id id))
	 (previous-id (getf (dbi:fetch result) :|id|)))
    (if previous-id
	(clean (wiki-article-revision-content (mito:find-dao 'wiki-article-revision :id previous-id)) *sanitize-spickipedia*)
	nil)))

(defroute ("/api/wiki" :method :POST) ()
  (let* ((title (subseq (script-name* *REQUEST*) 10)) (article (mito:find-dao 'wiki-article :title title)))
    (if (not article)
	(setf article (mito:create-dao 'wiki-article :title title)))
    (mito:create-dao 'wiki-article-revision :article article :author user :summary (post-parameter "summary") :content (post-parameter "html" *request*))
    nil))

(defroute ("/api/quiz/create" :method :POST) ()
    (format nil "~a" (object-id (mito:create-dao 'quiz :creator user))))

(defroute ("/api/quiz" :method :POST) ()
  (let* ((quiz-id (parse-integer (subseq (script-name*) 10))))
    (format nil "~a" (object-id (create-dao 'quiz-revision :quiz (find-dao 'quiz :id quiz-id) :content (post-parameter "data") :author user)))))

(defroute ("/api/quiz" :method :GET) ()
  (setf (content-type*) "text/json")
  (let* ((quiz-id (parse-integer (subseq (script-name*) 10)))
	 (revision (mito:select-dao 'quiz-revision (where (:= :quiz (find-dao 'quiz :id quiz-id))) (order-by (:desc :id)) (limit 1))))
    (quiz-revision-content (car revision))))
    
    
(defroute ("/api/history" :method :GET) ()
  (setf (content-type*) "text/json")
  (let* ((title (subseq (script-name* *REQUEST*) 13)) (article (mito:find-dao 'wiki-article :title title)))
    (if article
	(json:encode-json-to-string
	 (mapcar #'(lambda (r) `((id   . ,(object-id r))
				 (user . ,(user-name (wiki-article-revision-author r)))
				 (summary . ,(wiki-article-revision-summary r))
				 (created . ,(local-time:format-timestring nil (mito:object-created-at r)))
				 (size    . ,(length (wiki-article-revision-content r)))))
		 (mito:select-dao 'wiki-article-revision (where (:= :article article)) (order-by (:desc :created-at)))))
	(progn
	  (setf (return-code* *reply*) 404)
	  nil))))

(defroute ("/api/search" :method :GET) ()
  (setf (content-type*) "text/json")
  (let* ((searchquery (tsquery-convert (subseq (script-name* *REQUEST*) 12)))
	 (query (dbi:prepare *connection* "SELECT a.title, ts_rank_cd((setweight(to_tsvector(a.title), 'A') || setweight(to_tsvector((SELECT content FROM wiki_article_revision WHERE article_id = a.id ORDER BY id DESC LIMIT 1)), 'D')), query) AS rank, ts_headline(a.title || (SELECT content FROM wiki_article_revision WHERE article_id = a.id ORDER BY id DESC LIMIT 1), to_tsquery(?)) FROM wiki_article AS A, to_tsquery(?) query WHERE query @@ (setweight(to_tsvector(a.title), 'A') || setweight(to_tsvector((SELECT content FROM wiki_article_revision WHERE article_id = a.id ORDER BY id DESC LIMIT 1)), 'D')) ORDER BY rank DESC;"))
	 (result (dbi:execute query searchquery searchquery)))
    (json:encode-json-to-string (mapcar #'(lambda (r) `((title . ,(getf r :|title|))
							(rank  . ,(getf r :|rank|))
							(summary . ,(getf r :|ts_headline|)))) (dbi:fetch-all result)))))

(defroute ("/api/articles" :method :GET) ()
  (setf (content-type*) "text/json")
  (let* ((articles (mito:select-dao 'wiki-article)))
    (json:encode-json-to-string (mapcar 'wiki-article-title articles))))

(defroute ("/api/upload" :method :POST) ()
  (let* ((filepath (nth 0 (hunchentoot:post-parameter "file")))
	 ;; (filetype (nth 2 (hunchentoot:post-parameter "file")))
	 (filehash (byte-array-to-hex-string (digest-file :sha512 filepath)))	 ;; TODO whitelist mimetypes TODO verify if mimetype is correct
	 (newpath (merge-pathnames (concatenate 'string "uploads/" filehash) *default-pathname-defaults*)))
	 (print newpath)
	 (copy-file filepath newpath :overwrite t)
	 filehash))

;; noauth
(defroute ("/api/login" :method :POST) ()
  (let* ((name (post-parameter "name"))
	 (password (post-parameter "password"))
	 (user (mito:find-dao 'user :name name)))
    (if (and user (password= password (user-hash user)))                        ;; TODO prevent timing attack
	(progn
	  (regenerate-session *SESSION*)
	  (setf (my-session-user *SESSION*) user)
	  (mito:save-dao *SESSION*)
	  nil)
	(progn
	  (setf (return-code*) +http-forbidden+)
	  nil))))

;; noauth
(defroute ("/api/logout" :method :POST) ()
  (mito:delete-dao *SESSION*)
  (setf *SESSION* nil))

;; noauth
(defroute ("/api/killswitch" :method :GET) ()
  (sb-ext:quit))

;; noauth cache
(defroute ("/api/file" :method :GET) ()
  (handle-static-file (merge-pathnames (concatenate 'string "uploads/" (subseq (script-name* *REQUEST*) 10)))))

;; this is used to get the most used browsers to decide for future features (e.g. some browsers don't support new features so I won't use them if many use such a browser)
(defun track ()
  (with-open-file (str "track.json"
                     :direction :output
                     :if-exists :append
                     :if-does-not-exist :create)
  (format str "~a~%" (json:encode-json-to-string (acons "user" (my-session-user *session*) (headers-in*))))))




;;(defroute "/*.*" (&key path)
;;  (format nil "~A" path))

;;
;; Error pages

(defmethod on-exception ((app <web>) (code (eql 404)))
  (declare (ignore app))
  (merge-pathnames #P"_errors/404.html"
                   *template-directory*))
