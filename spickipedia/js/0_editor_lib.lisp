;; TODO only do on edit path
;; TODO hide editor if not editing
;; TODO show editor in fullscreen
(setf (chain document (get-elements-by-tag-name "article") 0 content-editable) T)

(defmacro tool (id &body body)
  `(chain
   document
   (get-element-by-id ,id)
   (add-event-listener
    "click"
    (lambda (event)
      (chain event (prevent-default))
      ,@body
      (chain document (get-elements-by-tag-name "article") 0 (focus))
      F))))

(defmacro stool (id)
  `(tool ,id
	 (chain document (exec-command ,id F))))

(tool "format-p"
    (chain document (exec-command "formatBlock" F "<p>")))

(tool "format-h2"
      (chain document (exec-command "formatBlock" F "<h2>")))

(tool "format-h3"
      (chain document (exec-command "formatBlock" F "<h3>")))

(stool "superscript")
(stool "subscript")
(stool "insertUnorderedList")
(stool "insertOrderedList")
(stool "indent")
(stool "outdent")

;;var engine = new Bloodhound({
;;  local: ['dog', 'pig', 'moose'],
;;  queryTokenizer: Bloodhound.tokenizers.whitespace,
;;  datumTokenizer: Bloodhound.tokenizers.whitespace
;;}).get

(setf
 (chain window engine)
 (new (-bloodhound
      (create
       local ([] "dog" "pig" "moose")
       query-tokenizer (chain -bloodhound tokenizers whitespace)
       datum-tokenizer (chain -bloodhound tokenizers whitespace)
       ))))

(tool "createLink"
      (chain ($ "#link-modal") (modal "show")))

(chain
 ($ "#link")
 (typeahead
  (create
   )
  (create
   name "my-dataset"
   source (chain window engine))))

      
;; TODO image
;; TODO table
;; TODO formula

(stool "undo")
(stool "redo")

;; TODO settings
;; TODO finish
