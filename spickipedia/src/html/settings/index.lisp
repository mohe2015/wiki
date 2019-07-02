(in-package :spickipedia.web)

(defun html-settings ()
  `(:div :style "display: none;" :class "container my-tab position-absolute" :id "tab-settings"
     (:h2 :class "text-center" "Einstellungen")

     (:h3 :class "text-center" "Dein Jahrgang")
     (:a :id "add-student-course" :type "button" :class "btn btn-primary norefresh" "Jahrgang hinzufügen")
     (:ul :id "student-courses-list") ;; TODO select


    ,(modal "student-courses" "Kurs hinzufügen"
       `((:BUTTON :TYPE "button" :CLASS "btn btn-secondary" :DATA-DISMISS "modal"
          "Abbrechen")
         (:BUTTON :TYPE "submit" :CLASS "btn btn-primary" :ID "student-courses-add"
          "Hinzufügen"))
       `((:DIV :CLASS "form-group"
           (:LABEL :FOR "course" "Kurs:") " "
           (:select :class "custom-select" :id "student-course" :name "student-course"))))))
