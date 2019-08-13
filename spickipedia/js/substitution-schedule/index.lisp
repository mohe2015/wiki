(var __-p-s_-m-v_-r-e-g)

(i "/js/show-tab.lisp" "showTab")
(i "/js/cleanup.lisp" "cleanup")
(i "/js/fetch.lisp" "checkStatus" "json" "html" "handleFetchError" "cacheThenNetwork")
(i "/js/utils.lisp" "all" "one" "clearChildren")
(i "/js/template.lisp" "getTemplate")
(i "/js/read-cookie.lisp" "readCookie")
(i "/js/state-machine.lisp" "pushState")

(defun group-by (xs key)
  (chain
   xs
   (reduce
    (lambda (rv x)
      (chain (setf (getprop rv (getprop x key)) (or (getprop rv (getprop x key)) (array))) (push x))
      rv)
    (create))))

(defun substitution-to-string (substitution)
  (concatenate
   'string
   (chain substitution hour)
   "."
   (if (and (chain substitution new-room) (not (equal (chain substitution old-room) (chain substitution new-room))))
       (concatenate 'string " | " (chain substitution old-room) " -> " (chain substitution new-room))
       "")
   (if (and (chain substitution new-subject) (not (equal (chain substitution old-subject) (chain substitution new-subject))))
       (concatenate 'string " | " (chain substitution old-subject) " -> " (chain substitution new-subject))
       "")
   (if (and (chain substitution new-teacher) (not (equal (chain substitution old-teacher) (chain substitution new-teacher))))
       (concatenate 'string " | " (chain substitution old-teacher) " -> " (chain substitution new-teacher))
       "")
   (if (chain substitution notes)
       (concatenate 'string " | " (chain substitution notes))
       "")))

(defun urlBase64ToUint8Array (base64String)
  (let* ((padding (chain "=" (repeat (% (- 4 (% base64String.length 4)) 4))))
         (base64  (chain (+ base64String padding) (replace (regex "/\\-/g") "+") (replace (regex "/_/g") "/")))
	 (rawData (chain window (atob base64)))
	 (outputArray (new (-Uint8-Array (chain rawData length)))))
    (loop for i from 0 to (- (chain rawData length) 1) do
         (setf (getprop outputArray i) (chain rawData (char-Code-At i))))
    outputArray))

(if (and (chain navigator service-worker) (chain window -push-manager))
    (chain
     window
     (add-event-listener
      "load"
      (lambda (event)
	(chain
	 navigator
	 service-worker
	 (register "/sw.lisp")
	 (then
	  (lambda (registration)
	    (chain
	     registration
	     push-manager
	     (get-subscription)
	     (then
	      (lambda (subscription)
		(let ((is-subscribed (not (null subscription))))
		  (if is-subscribed
		      (setf (inner-text (one "#settings-enable-notifications")) "Benachrichtigungen deaktivieren")
		      (setf (inner-text (one "#settings-enable-notifications")) "Benachrichtigungen aktivieren"))))))))
	 (catch
	     (lambda (error)
	       (alert error))))
	(progn
	  (setf (inner-text (one "#settings-enable-notifications")) "Benachrichtigungen werden von deinem Gerät nicht unterstützt")
	  (setf (disabled (one "#settings-enable-notifications")) t))))))

(defroute "/substitution-schedule"
  (show-tab "#loading")
  (cache-then-network
   "/api/substitutions"
   (lambda (data)
     (loop :for (k v) :of (chain data schedules) :do
	  (let ((template (get-template "template-substitution-schedule")))
	    (setf (inner-text (one ".substitution-schedule-date" template)) (chain (new (-date (* k 1000))) (to-locale-date-string "de-DE")))
	    (if (chain v substitutions)
		(loop :for (clazz substitutions) :of (group-by (chain v substitutions) "class") :do
		     (let ((class-template (get-template "template-substitution-for-class")))
		       (setf (inner-text (one ".template-class" class-template)) clazz)
		       (loop for substitution in substitutions do
			    (let ((substitution-template (get-template "template-substitution")))
			      (setf (inner-text (one "li" substitution-template)) (substitution-to-string substitution))
			      (append (one "ul" class-template) substitution-template)))
		       (append template class-template))))
	    (append (one "#substitution-schedule-content") template)))
     (show-tab "#substitution-schedule"))))

(on ("click" (one "#settings-enable-notifications") event)
  (chain event (prevent-default))
  (chain event (stop-propagation))
  (chain
   registration
   push-manager
   (subscribe
    (create
     user-visible-only t
     application-server-key (urlBase64ToUint8Array "BJNDT9kF9YzCy_ExMEUXumYXhfigSmPruzP7ZEkZBZDTldbVrHRo99eid1M_58O-eD-Kbl6Zp0-NfFUROKhlTY8=")))
   (then
    (lambda (push-registration)
      (chain console (log push-registration))))
   (catch
       (lambda (error)
	 (alert error))))
  nil)
