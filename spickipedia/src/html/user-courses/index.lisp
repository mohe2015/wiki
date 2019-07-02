(in-package :spickipedia.web)

(defun html-user-courses ()
  `((:template :id "student-courses-list-html"
      (:li (:a :type "button" :class "btn btn-primary button-student-course-delete" "-")
           (:span :class "student-courses-list-subject")))

    (:div :style "display: none;" :class "container my-tab position-absolute" :id "list-student-courses"
     (:h2 :class "text-center" "Deine Kurse" (:a :id "add-student-course" :type "button" :class "btn btn-primary norefresh" "+"))
     (:ul :id "student-courses-list"))

    ,(modal "student-courses" "Kurs hinzufügen"
       `((:BUTTON :TYPE "button" :CLASS "btn btn-secondary" :DATA-DISMISS "modal"
          "Abbrechen")
         (:BUTTON :TYPE "submit" :CLASS "btn btn-primary" :ID "student-courses-add"
          "Hinzufügen"))
       `((:DIV :CLASS "form-group"
           (:LABEL :FOR "course" "Kurs:") " "
           (:select :class "custom-select" :id "student-course" :name "student-course"))))))
