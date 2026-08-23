/* <error.h>, which ntlibc does not have.
 *
 * gnulib generates this header from gl/lib/error.in.h by substituting nine
 * @...@ values into it; this build generates none of gnulib's replacement
 * headers, so the four declarations findutils actually uses are written out
 * here instead.  gl/lib/error.c is compiled and supplies all of them.
 *
 * The GCC format attributes on gnulib's versions are dropped: this tcc
 * reads none of them, and lib/system.h calls error() with a runtime format
 * string in several places anyway.
 *
 * getprogname() is declared here for the same reason: error.c calls it and
 * includes nothing but <error.h>, and on a system with no
 * program_invocation_short_name, no __progname and no getprogname of its own
 * -- which ntlibc is -- gnulib's getprogname.c has no branch that compiles.
 * shim/nt-missing.c supplies it from gnulib's own program_name instead,
 * which findutils sets from argv[0] in every main().
 */
#ifndef _GL_NT_ERROR_H
#define _GL_NT_ERROR_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Print a message with 'fprintf (stderr, FORMAT, ...)'; if ERRNUM is
   nonzero, follow it with ": " and strerror (ERRNUM).  If STATUS is
   nonzero, terminate the program with 'exit (STATUS)'.  */
extern void error (int __status, int __errnum, const char *__format, ...);

extern void error_at_line (int __status, int __errnum, const char *__fname,
                           unsigned int __lineno, const char *__format, ...);

/* If NULL, error will flush stdout, then print on stderr the program name,
   a colon and a space.  Otherwise, error will call this function without
   parameters instead.  */
extern void (*error_print_progname) (void);

/* This variable is incremented each time 'error' is called.  */
extern unsigned int error_message_count;

/* Sometimes we want to have at most one error per line.  This variable
   controls whether this mode is selected or not.  */
extern int error_one_per_line;

/* The name the program was invoked as, for error()'s prefix.  */
extern const char *getprogname (void);

#ifdef __cplusplus
}
#endif

#endif /* _GL_NT_ERROR_H */
