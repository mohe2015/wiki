(import-default "./0_show_tab.js" "showTab")
(import-default "./0_cleanup.js" "cleanup")
(import-default "./0_handle_error.js" "handleError")

(export-default
 (defroute "/wiki/:name"
  (var pathname (chain window location pathname (split "/")))
  (show-tab "#loading")
  (chain ($ ".edit-button") (remove-class "disabled"))
  (chain ($ "#is-outdated-article") (add-class "d-none"))
  (chain ($ "#wiki-article-title") (text (decode-u-r-i-component (chain pathname 2))))
  (cleanup)
  
  (chain
   $
   (get
    (concatenate 'string "/api/wiki/" (chain pathname 2))
    (lambda (data)
      (chain ($ ".closable-badge") (remove))
      (chain ($ "#categories") (html ""))
      (if (chain data categories)
	  (loop for category in (chain data categories) do
	       (chain
		($ "#categories")
		(append
		 (who-ps-html
		  (:span :class "closable-badge" category))))
	       (chain
		($ "#new-category")
		(before
		 (who-ps-html
		  (:span :class "closable-badge"
			 (:span :class "closable-badge-label" category)
			 (:button :type "button" :class "close close-tag" :aria-label "Close"
				  (:span :aria-hidden "true" "&times;"))))))))
      (chain ($ "article") (html (chain data content)))      
      (render-math)
      (show-tab "#page")))
   (fail (lambda (jq-xhr text-status error-thrown)
	   (if (= (chain jq-xhr status) 404)
	       (show-tab "#not-found")
	       (handle-error jq-xhr T)))))))