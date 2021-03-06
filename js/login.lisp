(var __-p-s_-m-v_-r-e-g)


(i "./get-url-parameter.lisp" "getUrlParameter")
(i "./read-cookie.lisp" "readCookie")
(i "./state-machine.lisp" "replaceState")
(i "./show-tab.lisp" "showTab")
(i "./utils.lisp" "all" "one" "clearChildren")
(i "./fetch.lisp" "checkStatus" "json" "html" "handleFetchError" "handleLoginError")

(defroute "/login"
    (add-class (all ".edit-button") "disabled")
  (hide-modal (one "#modal-publish-changes"))
  (let ((url-username (get-url-parameter "username"))
        (url-password (get-url-parameter "password")))
    (if (and (not (undefined url-username)) (not (undefined url-password)))
     (progn
              (setf (value (one "#inputName")) (decode-u-r-i-component url-username))
              (setf (value (one "#inputPassword")) (decode-u-r-i-component url-password)))
     (if (not (undefined (chain window local-storage name)))
         (progn (replace-state "/wiki/Hauptseite") (return))))
    (show-tab "#login")
    (setf (display (style (one ".login-hide"))) "none !important")
    (remove-class (one ".navbar-collapse") "show")))

(on ("submit" (one "#login-form") event)
    (chain event (prevent-default))
    (let ((login-button (one "#login-button")))
      (setf (disabled login-button) t)
      (setf (inner-html login-button) "<span class=\"spinner-border spinner-border-sm\" role=\"status\" aria-hidden=\"true\"></span> Anmelden...")
      (login-post f)))

(defun login-post (repeated)
  (let* ((form-element (one "#login-form"))
         (form-data (new (-form-data form-element)))
         (login-button (one "#login-button"))
         (input-name (one "#inputName")))
    (chain form-data (append "_csrf_token" (read-cookie "_csrf_token")))
    (chain
     (fetch "/api/login" (create method "POST" body form-data))
     (then check-status)
     (then
      (lambda (data)
        (setf (disabled login-button) f)
        (setf (inner-html login-button) "Anmelden")
        (setf (value (one "#inputPassword")) "")
        (setf (chain window local-storage name) (value input-name))
        (if (and (not (null (chain window history state)))
                 (not (undefined (chain window history state last-state)))
                 (not (undefined (chain window history state last-url))))
            (replace-state (chain window history state last-url)
             (chain window history state last-state))
            (replace-state "/wiki/Hauptseite"))))
     (catch
      (lambda (error)
              (handle-login-error error repeated))))))
