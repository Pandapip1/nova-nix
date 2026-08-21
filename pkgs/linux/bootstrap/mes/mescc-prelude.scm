;;; The two definitions scripts/mescc.scm.in expects to already exist.
;;;
;;; That file is a template: ./configure substitutes @mes_cpu@ and
;;; @mes_kernel@ into it, and every other @NAME@ in it is guarded by a
;;; string-prefix? test that falls back to an environment variable, so an
;;; unsubstituted copy works for all of them but these two -- under Mes the
;;; cond-expand branch that would define them is empty, and the file refers to
;;; them as though something else had.
;;;
;;; Nothing here runs configure, so this is prepended to the template with
;;; catm rather than substituted into it: the same result, without needing a
;;; patch to match upstream's text exactly.
(define %arch "x86")
(define %kernel "linux")
