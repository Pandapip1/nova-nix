;;; The two definitions scripts/mescc.scm.in expects to already exist.
;;;
;;; The counterpart of ../../../linux/bootstrap/mes/mescc-prelude.scm, and
;;; different from it in one word.  That word decides a great deal: %kernel is
;;; what mescc.scm puts in the environment, what module/mescc.scm reads back
;;; as the kernel option, and therefore which subdirectory of lib/ MesCC looks
;;; in for the header and footer that make its output an executable -- a PE32
;;; one here rather than an ELF.
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
(define %kernel "windows")
