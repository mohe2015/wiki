
(in-package :spickipedia.web)
(defun get-html ()
  `(:html :lang "en"
    (:head (:meta :charset "utf-8")
     (:meta :name "viewport" :content
      "width=device-width, initial-scale=1, shrink-to-fit=no")
     (:link :rel "stylesheet" :href "/bootstrap.min.css")
     (:link :rel "stylesheet" :href "/all.css")
     (:link :rel "stylesheet" :href "/index.css") (:title "Spickipedia"))
    (:body
     (:template :id "multiple-choice-answer-html"
      (:div :class "custom-control custom-checkbox" " "
       (:input :type "checkbox" :class "custom-control-input" :id
        "customCheck1")
       (:label :class "custom-control-label" :for "customCheck1"
        "Check this custom")))
     (:template :id "teachers-list-html" (:li :class "teachers-list-name"))
     (:template :id "courses-list-html" (:li :class "courses-list-subject"))
     (:template :id "schedules-list-html"
      (:li (:a :class "schedules-list-grade norefresh")))
     (:template :id "multiple-choice-question"
      (:div :class "multiple-choice-question"
       (:form
        (:div :class "form-group"
         (:input :type "text" :class "form-control question" :placeholder
          "Frage eingeben"))
        (:div :class "responses")
        (:button :type "button" :class
         "btn btn-primary mb-1 add-response-possibility"
         "Antwortmöglichkeit hinzufügen"))
       (:hr)))
     (:template :id "text-question"
      (:div :class "text-question"
       (:form
        (:div :class "form-group"
         (:input :type "text" :class "form-control question" :placeholder
          "Frage eingeben"))
        (:div :class "form-group"
         (:input :type "text" :class "form-control answer" :placeholder
          "Antwort eingeben")))
       (:hr)))
     (:template :id "multiple-choice-response-possibility"
      (:div :class "input-group mb-3"
       (:div :class "input-group-prepend"
        (:div :class "input-group-text"
         (:input :class "multiple-choice-response-correct" :type "checkbox"
          :aria-label "Checkbox for following text input")))
       (:input :type "text" :class "form-control multiple-choice-response-text"
        :aria-label "Text input with checkbox")))
     (:template :id "search-result-template"
      (:a :class "list-group-item list-group-item-action"
       (:div
        (:div (:h5 :class "mt-0 s-title" "Media heading")
         (:div :class "search-result-summary word-wrap")))))
     (:template :id "history-item-template" " "
      (:div :class "list-group-item list-group-item-action"
       (:div :class "d-flex w-100 justify-content-between"
        (:h5 :class "mb-1 history-username" "Moritz Hedtke")
        (:small :class "history-date" "vor 3 Tagen"))
       (:p :class "mb-1 history-summary" "Ein paar wichtige Infos hinzugefügt")
       (:small (:span :class "history-characters" "50.322") " Zeichen"
        (:span :class "text-success d-none" "+ 50 Zeichen"))
       (:div :class "btn-group w-100" :role "group" :aria-label "Basic example"
        (:a :type "button" :class "btn btn-outline-dark history-show"
         (:i :class "fas fa-eye"))
        (:a :type "button" :class "btn btn-outline-dark history-diff"
         (:i :class "fas fa-columns")))))
     (:template :id "articles-entry"
      (:li (:a :class "" :href "#" "Hauptseite")))
     (:nav :class "navbar navbar-expand-md navbar-light bg-light"
      (:a :class "navbar-brand " :href "/wiki/Hauptseite" "Spickipedia ")
      (:div :class "login-hide"
       (:a :class "btn d-inline d-md-none edit-button"
        (:i :class "fas fa-pen"))
       (:a :class "btn d-inline d-md-none search-button " :href "/search"
        (:i :class "fas fa-search"))
       (:button :class "navbar-toggler" :type "button" :data-toggle "collapse"
        :data-target "#navbarSupportedContent" :aria-controls
        "navbarSupportedContent" :aria-expanded "false" :aria-label
        "Toggle navigation" (:span :class "navbar-toggler-icon")))
      (:div :class "collapse navbar-collapse" :id "navbarSupportedContent"
       (:ul :class "navbar-nav mr-auto"
        (:li :class "nav-item d-none d-md-block"
         (:a :class "nav-link search-button " :href "/search" "Suchen"))
        (:li :class "nav-item d-none d-md-block"
         (:a :class "nav-link edit-button" :href "#" "Bearbeiten"))
        (:li :class "nav-item"
         (:a :class "nav-link" :href "/settings" "Einstellungen"))
        (:li :class "nav-item"
         (:a :class "nav-link" :href "/logout" :id "logout" "Abmelden")))))
     (:div
      (:div :style "display: none;" :class
       "container my-tab position-absolution" :id "edit-quiz"
       (:h1 :class "text-center" "Quiz ändern") (:div :id "questions")
       (:button :type "button" :class
        "btn btn-primary mb-1 create-multiple-choice-question"
        "Multiple-Choice-Frage hinzufügen")
       (:button :type "button" :class
        "btn btn-primary mb-1 create-text-question"
        "Frage mit Textantwort hinzufügen")
       (:button :type "button" :class "btn btn-primary mb-1 save-quiz"
        "Speichern")))
     ,(tab "create-course-tab"
           `(:form :method "POST" :action "/api/courses" :id
             "create-course-form"
             ,(text-input "Fach" "course-subject" "subject")
             (:div :class "form-group" (:label "Typ")
              (:select :class "custom-select" :name "type" :id "course-type"
               (:option :selected "true" "GK") (:option "LK")))
             ,(teacher-select "teachers-select")
             ,(checkbox-input "Tutorium?" "is-tutorial" "is-tutorial")
             ,(text-input "Klasse" "course-class" "class")
             ,(text-input "Thema" "course-topic" "topic")
             `(submit-button "Kurs erstellen")))
     (:div :style "display: none;" :class
      "container-fluid my-tab position-absolute" :id "create-teacher-tab"
      (:form :method "POST" :action "/api/teachers" :id "create-teacher-form"
       (:div :class "form-group" (:label "Name")
        (:input :type "text" :class "form-control" :placeholder "Name" :name
         "name" :id "teacher-name"))
       (:div :class "form-group" (:label "Initialien")
        (:input :type "text" :class "form-control" :placeholder "Initialien"
         :name "initial" :id "teacher-initial"))
       (:button :type "submit" :class "btn btn-primary" "LehrerIn erstellen")))
     (:div :style "display: none;" :class "container my-tab position-absolute"
      :id "articles" (:h1 :class "text-center" "Alle Artikel")
      (:ul :id "articles-list"))
     (:div :style "display: none;" :class "container my-tab position-absolute"
      :id "tags" (:h1 :class "text-center" "Tags") (:ul :id "tags-list"))
     (:div :style "display: none;" :class
      "container-fluid my-tab position-absolute" :id "create-schedule-tab"
      (:form :method "POST" :action "/api/schedules" :id "create-schedule-form"
       (:div :class "form-group" (:label "Jahrgang")
        (:input :type "text" :class "form-control" :placeholder "Jahrgang"
         :name "grade" :id "schedule-grade"))
       (:button :type "submit" :class "btn btn-primary"
        "Stundenplan erstellen")))
     ,@(html-settings)
     (:div :style "display: none;" :class "container my-tab position-absolute"
      :id "multiple-choice-question-html"
      (:h2 :class "text-center question-html" "Dies ist eine Testfrage?")
      (:div :class "row justify-content-center"
       (:div :class "col col-sm-10 col-md-6" (:div :id "answers-html")
        (:button :type "button" :class
         "btn btn-primary mt-1 multiple-choice-submit-html" "Absenden")
        (:button :type "button" :style "display: none;" :class
         "btn btn-primary mt-1 next-question" "Nächste Frage"))))
     (:div :style "display: none;" :class "container my-tab position-absolute"
      :id "quiz-results" (:h1 :class "text-center" "Ergebnisse")
      (:p :id "result"))
     (:div :style "display: none;" :class "container my-tab position-absolute"
      :id "list-teachers"
      (:h2 :class "text-center" "Lehrer"
       (:a :href "/teachers/new" :type "button" :class
        "btn btn-primary norefresh" "+"))
      (:ul :id "teachers-list"))
     (:div :style "display: none;" :class "container my-tab position-absolute"
      :id "list-courses"
      (:h2 :class "text-center" "Kurse"
       (:a :href "/courses/new" :type "button" :class
        "btn btn-primary norefresh" "+"))
      (:ul :id "courses-list"))
     ,@(html-user-courses) ,@(html-schedule)
     (:div :style "display: none;" :class "container my-tab position-absolute"
      :id "list-schedules"
      (:h2 :class "text-center" "Stundenpläne"
       (:a :href "/schedules/new" :type "button" :class
        "btn btn-primary norefresh" "+"))
      (:ul :id "schedules-list"))
     (:div :style "display: none;" :class "container my-tab position-absolute"
      :id "text-question-html"
      (:h2 :class "text-center question-html" "Dies ist eine Testfrage?")
      (:div :class "row justify-content-center"
       (:div :class "col col-sm-10 col-md-6"
        (:div :id "answers-html" " "
         (:input :type "text" :class "form-control" :id "text-response"))
        (:button :type "button" :class "btn btn-primary mt-1 text-submit-html"
         "Absenden")
        (:button :type "button" :style "display: none;" :class
         "btn btn-primary mt-1 next-question" "Nächste Frage"))))
     (:div :style "display: none;" :class
      "container my-tab position-absolute col-sm-6 offset-sm-3 col-md-4 offset-md-4 text-center"
      :id "login" (:h1 "Anmelden")
      (:form :id "login-form"
       (:div :class "form-group"
        (:input :type "text" :id "inputName" :class "form-control" :placeholder
         "Name" :required "" :autofocus "" :autocomplete "username"))
       (:div :class "form-group"
        (:input :type "password" :id "inputPassword" :class "form-control"
         :placeholder "Passwort" :required "" :autocomplete
         "current-password"))
       (:button :class "btn btn-primary" :type "submit" :id "login-button"
        "Anmelden")))
     (:div :style "display: none;" :class
      "container-fluid my-tab position-absolute word-wrap" :id "page"
      (:div :class "alert alert-warning mt-1 d-none" :id "is-outdated-article"
       :role "alert"
       " Dies zeigt den Artikel zu einem bestimmten Zeitpunkt und ist somit nicht unbedingt aktuell! "
       (:a :href "#" :id "currentVersionLink" :class "alert-link "
        "Zur aktuellen Version"))
      (:h1 :class "text-center" :id "wiki-article-title" "title")
      (:div :class "article-editor"
       (:div :id "editor" :class "d-none"
        (:a :href "#" :id "format-p" (:span :class "fas fa-paragraph")) " "
        (:a :href "#" :id "format-h2" (:span :class "fas fa-heading")) " "
        (:a :href "#" :id "format-h3" (:span :class "fas fa-heading")) " "
        (:a :href "#" :id "superscript" (:span :class "fas fa-superscript"))
        " " (:a :href "#" :id "subscript" (:span :class "fas fa-subscript"))
        " "
        (:a :href "#" :id "insertUnorderedList"
         (:span :class "fas fa-list-ul"))
        " "
        (:a :href "#" :id "insertOrderedList" (:span :class "fas fa-list-ol"))
        " " (:a :href "#" :id "indent" (:span :class "fas fa-indent")) " "
        (:a :href "#" :id "outdent" (:span :class "fas fa-outdent")) " "
        (:a :href "#" :id "createLink" (:span :class "fas fa-link")) " "
        (:a :href "#" :id "insertImage" (:span :class "fas fa-image")) " "
        (:a :href "#" :id "table" (:span :class "fas fa-table")) " "
        (:a :href "#" :id "insertFormula" (:span :class "fas fa-calculator"))
        " " (:a :href "#" :id "undo" (:span :class "fas fa-undo")) " "
        (:a :href "#" :id "redo" (:span :class "fas fa-redo")) " "
        (:a :href "#" :id "settings" (:span :class "fas fa-cog")) " "
        (:a :href "#" :id "finish" (:span :class "fas fa-check")))
       (:article))
      (:div :id "categories")
      (:div
       (:button :id "show-history" :type "button" :class
        "btn btn-outline-primary" "Änderungsverlauf"))
      (:small "Dieses Werk ist lizenziert unter einer "
       (:a :target "_blank" :rel "license noopener" :href
        "http://creativecommons.org/licenses/by-sa/4.0/deed.de"
        "Creative Commons Namensnennung - Weitergabe unter gleichen Bedingungen 4.0 International Lizenz")
       "."))
     (:div :style "display: none;" :class
      "container-fluid my-tab position-absolute" :id "not-found"
      (:div :class "alert alert-danger" :role "alert"
       " Der Artikel konnte nicht gefunden werden. Möchtest du ihn "
       (:a :id "create-article" :href "#" :class "alert-link" "erstellen")
       "?"))
     (:div :style "display: none;" :class
      "container-fluid my-tab position-absolute" :id "history"
      (:h1 :class "text-center" "Änderungsverlauf")
      (:div :class "list-group" :id "history-list"))
     (:div :style "display: none;" :class
      "container-fluid my-tab position-absolute" :id "search" " " (:br)
      (:div :class "input-group mb-3"
       (:input :type "text" :class "form-control" :id "search-query"
        :placeholder "Suchbegriff")
       (:div :class "input-group-append"
        (:button :class "btn btn-outline-secondary" :type "button" :id
         "button-search" (:i :class "fas fa-search"))))
      (:div
       (:div :style "display: none; left: 50%; margin-left: -1rem;" :class
        "position-absolute" :id "search-results-loading"
        (:div :class "spinner-border" :role "status"
         (:span :class "sr-only" "Loading...")))
       (:div :style "display: none;" :id "search-results"
        (:div :style "display: none;" :class "text-center" :id
         "no-search-results"
         (:div :class "alert alert-warning" :role "alert"
          " Es konnte kein Artikel mit genau diesem Titel gefunden werden. Möchtest du ihn "
          (:a :id "search-create-article" :href "#" :class "alert-link "
           "erstellen")
          "?"))
        (:div :class "list-group" :id "search-results-content"))))
     (:div :class "my-tab position-absolute" :style
      "top: 50%; left: 50%; margin-left: -1rem; margin-top: -1rem;" :id
      "loading"
      (:div :class "spinner-border" :role "status"
       (:span :class "sr-only" "Loading...")))
     (:div :style "display: none;" :class
      "container-fluid my-tab position-absolute" :id "error"
      (:div :class "alert alert-danger" :role "alert"
       (:span :id "errorMessage") " "
       (:a :href "#" :id "refresh" :class "alert-link" "Erneut versuchen")))
     ,(modal "publish-changes" "Änderungen veröffentlichen"
        `((:button :type "button" :class "btn btn-secondary" :data-dismiss
            "modal" "Bearbeitung fortsetzen")
          (:button :type "button" :class "btn btn-primary" :id "publish-changes"
           "Änderungen veröffentlichen")
          (:button :id "publishing-changes" :class "btn btn-primary" :style
           "display: none;" :type "button" :disabled "" " ")
          (:span :class "spinner-border spinner-border-sm" :role "status"
            :aria-hidden "true" " Veröffentlichen... "))
        `((:div :class "form-group" " " (:label "Änderungszusammenfassung:")
           (:br)
           (:textarea :class "form-control" :id "change-summary" :rows "3"))
          (:p
           "Mit dem Veröffentlichen dieses Artikels garantierst du, dass er nicht die Rechte anderer verletzt und bist damit einverstanden, ihn unter der "
           (:a :target "_blank" :rel "noopener" :href
            "https://creativecommons.org/licenses/by-sa/4.0/deed.de"
            "Creative Commons Namensnennung - Weitergabe unter gleichen Bedingungen 4.0 International Lizenz")
           " zu veröffentlichen.")))

     ,(modal "upload-progress" ""
        `()
        `((:div :class "progress"
           (:div :id "uploadProgress" :class
            "progress-bar progress-bar-striped progress-bar-animated" :role
            "progressbar" :aria-valuenow "75" :aria-valuemin "0" :aria-valuemax
            "100" :style "width: 0%"))))
     ,(modal "wiki-link" "Spickipedia-Link einfügen"
       `((:button :type "button" :class "btn btn-primary" :id "publish-changes"
           "Änderungen veröffentlichen"))
       `((:div :class "form-group" (:label "Anzeigetext") (:br)
           (:input :class "form-control" :type "text" :id "article-link-text")
           "<input>")
         (:div :class "form-group" (:label "Spickipedia-Artikel") (:br)
          (:input :class "form-control" :type "text" :id "article-link-title")
          "<input>")))

     ,(modal "settings" "Kategorien"
        `((:button :type "button" :class "btn btn-secondary" :data-dismiss
            "modal" "Fertig"))
        `((:form :class "form-inline" :id "add-tag-form"
            (:input :id "new-category" :class "form-control form-control-sm"
             :type "text" :placeholder "Kategorie..."))))

     ,(modal "link" "Link"
        `((:button :type "button" :class "btn btn-secondary" :data-dismiss
           "modal" "Abbrechen")
          (:button :type "submit" :class "btn btn-primary" :id "update-link"
           "Ok"))
        `((:div :class "form-group" :style
            "position: relative; display: inline-block;")
          (:input :type "text" :id "link" :class "form-control" :autocomplete
           "off")
          (:div :class "dropdown-menu" :style
           "position: absolute; top: 100%; left: 0px; z-index: 100; width: 100%;")))

     ,(modal "table" "Tabelle"
        `((:button :type "button" :class "btn btn-secondary" :data-dismiss
            "modal" "Abbrechen")
          (:button :type "button" :class "btn btn-primary" :id "update-table"
           "Ok"))
        `((:div :class "form-group" (:label :for "table-columns" "Spalten:")
           (:input :type "number" :id "table-columns" :class "form-control"))
          (:div :class "form-group" (:label :for "table-rows" "Zeilen:") " "
           (:input :type "number" :id "table-rows" :class "form-control"))))

     (:div :class "modal fade" :id "image-modal" :tabindex "-1" :role "dialog"
      :aria-labelledby "exampleModalLabel" :aria-hidden "true"
      (:div :class "modal-dialog" :role "document"
       (:div :class "modal-content"
        (:div :class "modal-header"
         (:h5 :class "modal-title" :id "exampleModalLabel" "Bild")
         (:button :type "button" :class "close" :data-dismiss "modal"
          :aria-label "Close" (:span :aria-hidden "true" "×")))
        (:div :class "modal-body"
         (:form
          (:div :class "form-group"
           (:div :class "form-group"
            (:label :for "image-file" "Bild auswählen:")
            (:input :type "file" :accept "image/*" :class "form-control-file"
             :id "image-file"))
           (:div :class "form-group" (:label :for "image-url" "Bild-URL:")
            (:input :type "url" :id "image-url" :class "form-control")))))
        (:div :class "modal-footer"
         (:button :type "button" :class "btn btn-secondary" :data-dismiss
          "modal" "Abbrechen")
         (:button :type "button" :class "btn btn-primary" :id "update-image"
          "Ok")))))
     (:div :class "modal fade" :id "formula-modal" :tabindex "-1" :role
      "dialog" :aria-labelledby "exampleModalLabel" :aria-hidden "true"
      (:div :class "modal-dialog" :role "document"
       (:div :class "modal-content"
        (:div :class "modal-header"
         (:h5 :class "modal-title" :id "exampleModalLabel" "Formel")
         (:button :type "button" :class "close" :data-dismiss "modal"
          :aria-label "Close" (:span :aria-hidden "true" "×")))
        (:div :class "modal-body"
         (:form
          (:div :class "form-group"
           (:div :class "alert alert-warning" :role "alert"
            "Formeln editieren funktioniert nur in Google Chrome zuverlässig!")
           (:span :id "formula" "e=mc^2"))))
        (:div :class "modal-footer"
         (:button :type "button" :class "btn btn-secondary" :data-dismiss
          "modal" "Abbrechen")
         (:button :type "button" :class "btn btn-primary" :id "update-formula"
          "Ok")))))
     (:form :id "schedule-data-form"
      (:div :class "modal fade" :id "schedule-data-modal" :tabindex "-1" :role
       "dialog" :aria-labelledby "schedule-data-modal-label" :aria-hidden
       "true"
       (:div :class "modal-dialog" :role "document"
        (:div :class "modal-content"
         (:div :class "modal-header"
          (:h5 :class "modal-title" :id "schedule-data-modal-label"
           "Unterrichtsstunde")
          (:button :type "button" :class "close" :data-dismiss "modal"
           :aria-label "Close" (:span :aria-hidden "true" "×")))
         (:div :class "modal-body"
          (:input :type "hidden" :id "schedule-data-weekday" :name "weekday"
           :value "monday")
          (:input :type "hidden" :id "schedule-data-hour" :name "hour" :value
           "1")
          (:div :class "form-group"
           (:label :for "week-modulo" "Regelmäßigkeit")
           (:select :class "custom-select" :id "week-modulo" :name
            "week-modulo"
            (:option :selected "selected" :value "0" "Jede Woche")
            (:option :value "1" "Ungerade Woche")
            (:option :value "2" "Gerade Woche")))
          (:div :class "form-group" (:label :for "course" "Kurs:") " "
           (:select :class "custom-select" :id "course" :name "course"))
          (:div :class "form-group" (:label :for "room" "Raum:") " "
           (:input :type "text" :id "room" :name "room" :class
            "form-control")))
         (:div :class "modal-footer"
          (:button :type "button" :class "btn btn-secondary" :data-dismiss
           "modal" "Abbrechen")
          (:button :type "submit" :class "btn btn-primary" :id "update-table"
           "Ok"))))))
     (:script :src "/jquery-3.3.1.js")
     (:link :rel "stylesheet" :href "/mathlive.core.css")
     (:link :rel "stylesheet" :href "/mathlive.css")
     (:script :src "/mathlive.js") (:script :src "/popper.js")
     (:script :src "/bootstrap.min.js") (:script :src "/visual-diff.js")
     (:script :nomodule "" :src "no_module_support.js")
     (:script :type "module" :src "/js/index.lisp"))))
