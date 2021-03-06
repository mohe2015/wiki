(defpackage schule.libc
  (:use :cl :cffi)
  (:export :strptime))

(in-package :schule.libc)

(define-foreign-library libc
  (:unix (:or "libc.so.6" "libc.so"))
  (:t (:default "libc")))

(use-foreign-library libc)

(defcstruct tm
  (tm-sec :int)
  (tm-min :int)
  (tm-hour :int)
  (tm-mday :int)
  (tm-mon :int)
  (tm-year :int)
  (tm-wday :int)
  (tm-yday :int)
  (tm-isdst :int))

;;; http://man7.org/linux/man-pages/man3/strptime.3.html
(defcfun ("strptime" strptime%) :string
  (string :string)
  (format :string)
  (time-struct (:pointer (:struct tm))))

(defcfun mktime :uint32
  (time-struct (:pointer (:struct tm))))

;; https://stackoverflow.com/questions/6256179/how-can-i-find-the-value-of-lc-xxx-locale-integr-constants-so-that-i-can-use-the/6561967#6561967

;;  1561355700
;; date 1561676400

(defcenum lc_symbol
  (:lc-all 6))

(defcfun setlocale :string
  (category lc_symbol)
  (locale :string))

(setlocale 6 "de_DE.UTF-8")

(defun strptime (string format)
  (with-foreign-strings ((c-string string)
                         (c-format format))
    (with-foreign-object (time '(:pointer (:struct tm)))
      (with-foreign-slots ((tm-sec tm-min tm-hour tm-mday tm-mon tm-year tm-wday tm-yday tm-isdst) time (:struct tm))
       (setf tm-sec 0)
       (setf tm-min 0)
       (setf tm-hour 0)
       (setf tm-mday 0)
       (setf tm-mon 0)
       (setf tm-year 0)
       (setf tm-wday 0)
       (setf tm-yday 0)
       (setf tm-isdst -1)
       (let ((ret (strptime% c-string c-format time)))
          (unless ret
             (error "failed to parse date")))
       (setf tm-isdst -1)
       (mktime time)))))
