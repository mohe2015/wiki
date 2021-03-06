(defun get-graph ()
  `((:parenscript-file "js/read-cookie" :depends-on ("js/utils"))
    (:parenscript-file "js/editor" :depends-on ("js/editor-lib" "js/math" "js/read-cookie" "js/state-machine" "js/utils" "js/fetch"))
    (:parenscript-file "js/fetch" :depends-on ("js/state-machine" "js/utils" "js/show-tab"))
    (:parenscript-file "js/categories" :depends-on ("js/show-tab" "js/read-cookie" "js/utils" "js/template"))
    (:parenscript-file "js/file-upload" :depends-on ("js/read-cookie" "js/utils"))
    (:parenscript-file "js/wiki/page" :depends-on ("js/template" "js/show-tab" "js/math" "js/image-viewer" "js/fetch" "js/utils" "js/state-machine"))
    (:parenscript-file "js/search" :depends-on ("js/show-tab" "js/utils" "js/template" "js/fetch"))
    (:parenscript-file "js/quiz" :depends-on ("js/utils"))
    (:parenscript-file "js/logout" :depends-on ("js/show-tab" "js/read-cookie" "js/state-machine" "js/utils" "js/fetch"))
    (:parenscript-file "js/login" :depends-on ("js/get-url-parameter" "js/read-cookie" "js/state-machine" "js/show-tab" "js/utils" "js/fetch"))
    (:parenscript-file "js/root" :depends-on ("js/state-machine" "js/utils"))
    (:parenscript-file "js/history" :depends-on ("js/state-machine" "js/show-tab" "js/cleanup" "js/math" "js/fetch" "js/utils" "js/template"))
    (:parenscript-file "js/wiki/page/edit" :depends-on ("js/cleanup" "js/show-tab" "js/math" "js/editor" "js/utils" "js/fetch" "js/template" "js/state-machine"))
    (:parenscript-file "js/create" :depends-on ("js/state-machine" "js/editor" "js/show-tab" "js/utils" "js/state-machine"))
    (:parenscript-file "js/articles" :depends-on ("js/show-tab" "js/utils"))
    (:parenscript-file "js/show-tab" :depends-on ("js/utils"))
    (:parenscript-file "js/courses/index" :depends-on ("js/show-tab" "js/read-cookie" "js/fetch" "js/template" "js/utils"))
    (:parenscript-file "js/schedule/id" :depends-on ("js/show-tab" "js/cleanup" "js/fetch" "js/utils" "js/template" "js/read-cookie" "js/state-machine"))
    (:parenscript-file "js/schedules/new" :depends-on ("js/show-tab" "js/cleanup" "js/read-cookie" "js/fetch" "js/state-machine" "js/utils"))
    (:parenscript-file "js/schedules/index" :depends-on ("js/show-tab" "js/read-cookie" "js/fetch" "js/template" "js/utils"))
    (:parenscript-file "js/student-courses/index" :depends-on ("js/show-tab" "js/read-cookie" "js/fetch" "js/template" "js/utils"))
    (:parenscript-file "js/settings/index" :depends-on ("js/show-tab" "js/read-cookie" "js/fetch" "js/template" "js/utils" "js/state-machine"))
    (:parenscript-file "js/template" :depends-on ("js/utils"))
    (:parenscript-file "js/cleanup" :depends-on ("js/editor" "js/utils"))
    (:parenscript-file "js/math" :depends-on ("js/utils"))
    (:parenscript-file "js/image-viewer" :depends-on ("js/utils"))
    (:parenscript-file "js/substitution-schedule/index" :depends-on ("js/show-tab" "js/cleanup" "js/fetch" "js/utils" "js/template" "js/read-cookie" "js/state-machine"))
    (:parenscript-file "js/contact/index" :depends-on ("js/show-tab"))
    (:parenscript-file "js/state-machine" :depends-on ("js/utils" "js/template" "js/cleanup" "js/fetch" "js/show-tab"))

    (:parenscript-file "js/editor-lib" :depends-on ("js/file-upload" "js/categories" "js/fetch" "js/utils"))
    (:parenscript-file "js/utils")
    (:parenscript-file "js/index" :depends-on ("js/contact/index" "js/wiki/page" "js/search" "js/quiz" "js/logout" "js/login" "js/root" "js/history" "js/wiki/page/edit" "js/create" "js/articles" "js/categories" "js/courses/index" "js/schedule/id" "js/schedules/new" "js/schedules/index" "js/student-courses/index" "js/settings/index" "js/math" "js/image-viewer" "js/substitution-schedule/index" "js/state-machine" "js/editor-lib" "js/utils"))))

(with-open-file (stream "test.dot" :direction :output :if-exists :supersede)
  (format stream "digraph {~%")
  (loop for file in (get-graph) do
       (loop for dependency in (nth 3 file) do
        (format stream "~s -> ~s;~%" (nth 1 file) dependency)))
  (format stream "}"))

;; dot -Tpng ~/test.dot > output.png
;; sccmap -v ~/test.dot > test.dot
;; dot -Tpng test.dot > output.png
