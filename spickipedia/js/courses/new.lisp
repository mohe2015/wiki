(var __-p-s_-m-v_-r-e-g)

(i "../show-tab.lisp" "showTab")
(i "../read-cookie.lisp" "readCookie")
(i "../fetch.lisp" "checkStatus" "json" "html" "handleFetchError")
(i "../template.lisp" "getTemplate")
(i "../state-machine.lisp" "pushState")
(i "../utils.lisp" "all" "one" "clearChildren")

(defroute "/courses/new"
 (let ((select (chain document (query-selector "#teachers-select"))))
   (setf (chain select inner-h-t-m-l) "")
   (chain (fetch "/api/teachers") (then check-status) (then json)
    (then
     (lambda (data)
       (chain console (log data))
       (loop for teacher in data
             do (let ((element (chain document (create-element "option"))))
                  (setf (chain element inner-text) (chain teacher name))
                  (setf (chain element value) (chain teacher id))
                  (chain select (append-child element))))))
    (catch handle-fetch-error))
   (show-tab "#create-course-tab")))

(on ("submit" (one "#create-course-form") event)
  (let* ((formelement
          (chain document (query-selector "#create-course-form")))
         (formdata (new (-form-data formelement))))
    (chain formdata (append "_csrf_token" (read-cookie "_csrf_token")))
    (chain (fetch "/api/courses" (create method "POST" body formdata))
     (then check-status) (then json)
     (then
      (lambda (data)
        (push-state "/courses")
        (setf (chain (one "#course-subject") value) "")
        (setf (chain (one "#course-type") value) "")
        (setf (chain (one "#teachers-select") value) "")
        (setf (chain (one "#is-tutorial") value) "")
        (setf (chain (one "#course-class") value) "")
        (setf (chain (one "#course-topic") value) "")))
     (catch handle-fetch-error)))
  f)
