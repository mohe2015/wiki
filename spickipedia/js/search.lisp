
(chain
 ($ document)
 (on "input" "#search-query"
     (lambda (e)
       (chain ($ "#button-search") (click)))))
       
(defroute "/search"    
  (chain ($ ".edit-button") (add-class "disabled"))
  (show-tab "#search"))

(defroute "/search/:query"
  (chain ($ ".edit-button") (add-class "disabled"))
  (show-tab "#search")
  (chain ($ "#search-query") (val query)))

(chain
 ($ "#button-search")
 (click
  (lambda ()
    (let ((query (chain ($ "#search-query") (val))))
      (chain ($ "#search-create-article") (attr "href" (concatenate 'string "/wiki/" query "/create")))
      (chain window history (replace-state nil nil (concatenate 'string "/search/" query)))
      (chain ($ "#search-results-loading") (stop) (fade-in))
      (chain ($ "#search-results") (stop) (fade-out))
      (if (not (undefined (chain window search-xhr)))
	  (chain window search-xhr (abort)))
      (setf
       (chain window search-xhr)
       (chain
	$
	(get
	 (concatenate 'string "/api/search/" query)
	 (lambda (data)
	   (chain ($ "#search-results-content") (html ""))
	   (let ((results-contain-query F))
	     (if (not (null data))
		 (loop for page in data do
		      (if (= (chain page title) query)
			  (setf results-contain-query T))
		      (let ((template ($ (chain ($ "#search-result-template") (html)))))
			(chain template (find ".s-title") (text (chain page title)))
			(chain template (attr "href" (concatenate 'string "/wiki/" (chain page title))))
			(chain template (find ".search-result-summary") (html (chain page summary)))
			(chain ($ "#search-results-content") (append template)))))
	     (if results-contain-query
		 (chain ($ "#no-search-results") (hide))
		 (chain ($ "#no-search-results") (show)))
	     (chain ($ "#search-results-loading") (stop) (fade-out))
	     (chain ($ "#search-results") (stop) (fade-in)))))
	(fail (lambda (jq-xhr text-status error-thrown)
		(if (not (= text-status "abort"))
		    (handle-error jq-xhr T))))))))))