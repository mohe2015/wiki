(in-package :schule.argon2)

(define-foreign-library libargon2
  (:unix (:or "libargon2.so.1" "libargon2.so"))
  (:t (:default "libargon2")))

(use-foreign-library libargon2)

(defctype size :unsigned-int)

(defcenum argon2_errorcodes
  (:argon2_ok 0)
  (:argon2_output_ptr_null -1)
  (:argon2_output_too_short -2)
  (:argon2_output_too_long -3)
  (:argon2_pwd_too_short -4)
  (:argon2_pwd_too_long -5)
  (:argon2_salt_too_short -6)
  (:argon2_salt_too_long -7)
  (:argon2_ad_too_short -8)
  (:argon2_ad_too_long -9)
  (:argon2_secret_too_short -10)
  (:argon2_secret_too_long -11)
  (:argon2_time_too_small -12)
  (:argon2_time_too_large -13)
  (:argon2_memory_too_little -14)
  (:argon2_memory_too_much -15)
  (:argon2_lanes_too_few -16)
  (:argon2_lanes_too_many -17)
  (:argon2_pwd_ptr_mismatch -18)
  (:argon2_salt_ptr_mismatch -19)
  (:argon2_secret_ptr_mismatch -20)
  (:argon2_ad_ptr_mismatch -21)
  (:argon2_memory_allocation_error -22)
  (:argon2_free_memory_cbk_null -23)
  (:argon2_allocate_memory_cbk_null -24)
  (:argon2_incorrect_parameter -25)
  (:argon2_incorrect_type -26)
  (:argon2_out_ptr_mismatch -27)
  (:argon2_threads_too_few -28)
  (:argon2_threads_too_many -29)
  (:argon2_missing_args -30)
  (:argon2_encoding_fail -31)
  (:argon2_decoding_fail -32)
  (:argon2_thread_fail -33)
  (:argon2_decoding_length_fail -34)
  (:argon2_verify_mismatch -35))

(defcenum argon2_type
  (:argon2_d 0)
  (:argon2_i 1)
  (:argon2_id 2))

(defcfun "argon2_encodedlen" size
  (t-cost :uint32)
  (m-cost :uint32)
  (parallelism :uint32)
  (saltlen size)
  (hashlen size)
  (type argon2_type))

(defcfun "argon2id_hash_encoded" argon2_errorcodes
  (t-cost :uint32)
  (m-cost :uint32)
  (parallelism :uint32)
  (pwd :pointer)
  (pwdlen size)
  (salt :pointer)
  (saltlen size)
  (hashlen size)
  (encoded :pointer)
  (encodedlen size))

(defcfun "argon2id_verify" argon2_errorcodes
  (encoded :pointer)
  (pwd :pointer)
  (pwdlen size))

(defparameter *hashlen* 32)

(defparameter *saltlen* 16)

(defun hash (password)
  (with-foreign-array
      (salt (random-data *saltlen*) `(:array :uint8 ,*saltlen*))
    (with-foreign-string ((pwd pwdlen) password)
      (let ((t-cost 2) (m-cost (ash 1 16)) (parallelism 1))
        (with-foreign-pointer (encoded (argon2-encodedlen t-cost m-cost parallelism *saltlen* *hashlen* :argon2_id) encodedlen)
          (assert (eq :argon2_ok (argon2id-hash-encoded t-cost m-cost parallelism pwd pwdlen salt *saltlen* *hashlen* encoded encodedlen)))
          (foreign-string-to-lisp encoded))))))

(defun verify (password hash)
  (with-foreign-string ((pwd pwdlen) password)
    (with-foreign-string (encoded hash)
      (eq :argon2_ok (argon2id-verify encoded pwd pwdlen)))))
