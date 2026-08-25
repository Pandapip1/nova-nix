/* The declarations gnulib's replacement headers would have contributed.
 *
 * gnulib does not only supply .c files.  For each system header it touches
 * it also generates a replacement -- gl/lib/unistd.h from unistd.in.h,
 * gl/lib/time.h from time.in.h, and so on -- which #include_next's the real
 * one and adds gnulib's own names on top.  This build generates none of
 * them: the sources see ntlibc's headers directly, which is possible because
 * ntlibc needs no rpl_* renaming for anything findutils uses.
 *
 * What that leaves is a short list of things gnulib's replacements ADD
 * rather than replace, and this header is that list.  It is included from
 * the end of config.h, so every compiled file sees it exactly where it would
 * have seen the generated headers.  Each entry says which .in.h it comes
 * from and who reads it.
 */
#ifndef _GL_NT_MISSING_DECLS_H
#define _GL_NT_MISSING_DECLS_H

#include <time.h>
#include <sys/stat.h>

/* From time.in.h, module time_rz.  gl/lib/time_rz.c is compiled and defines
   all four; gl/lib/parse-datetime.h declares parse_datetime2 with a
   timezone_t parameter, so find/parser.c needs the type too.  Without it the
   error is `invalid type' on a prototype, which is an obscure way to be told
   a header was not generated. */
typedef struct tm_zone *timezone_t;
extern timezone_t tzalloc (char const *__name);
extern void tzfree (timezone_t __tz);
extern struct tm *localtime_rz (timezone_t __tz, time_t const *__timer,
                                struct tm *__result);
extern time_t mktime_z (timezone_t __tz, struct tm *__tm);

/* From locale.in.h, module setlocale-null.  gl/lib/hard-locale.c sizes a
   buffer with SETLOCALE_NULL_MAX and calls setlocale_null_r, and reaches
   both of them only through gnulib's <locale.h>.  The two constants are
   gnulib's own values, copied from gl/lib/setlocale_null.h, which this
   build does compile the .c side of. */
#include "setlocale_null.h"

/* From fcntl.in.h.  O_SEARCH is POSIX-2008 and ntlibc has no separate
   search-only open mode; gnulib's replacement header defines it to O_RDONLY
   on every system in the same position, which is what save-cwd.c,
   chdir-long.c and openat-proc.c want it for -- opening a directory in
   order to fchdir back to it. */
#ifndef O_SEARCH
# define O_SEARCH O_RDONLY
#endif

/* From sys_stat.in.h.  Not specified by POSIX, but gnulib's modechange.c
   uses it for the `a' in a symbolic mode like `a+rw'. */
#ifndef S_IRWXUGO
# define S_IRWXUGO (S_IRWXU | S_IRWXG | S_IRWXO)
#endif
#ifndef S_IXUGO
# define S_IXUGO (S_IXUSR | S_IXGRP | S_IXOTH)
#endif

/* Also from sys_stat.in.h: the file types no modern system has.  gnulib
   defines each to 0 where the system does not, and gl/lib/filemode.c and
   find/pred.c test all of them when deciding what letter to print for a
   file -- so on this target these are not a portability nicety, they are
   what stops the link failing with eight unresolved references.  NT has
   none of these object types and neither does ntlibc. */
#ifndef S_ISCTG
# define S_ISCTG(m) 0    /* contiguous file, Masscomp */
#endif
#ifndef S_ISDOOR
# define S_ISDOOR(m) 0   /* Solaris door */
#endif
#ifndef S_ISMPB
# define S_ISMPB(m) 0    /* V7 multiplexed block special */
#endif
#ifndef S_ISMPC
# define S_ISMPC(m) 0    /* V7 multiplexed character special */
#endif
#ifndef S_ISMPX
# define S_ISMPX(m) 0    /* AIX multiplexed */
#endif
#ifndef S_ISNWK
# define S_ISNWK(m) 0    /* HP-UX network special */
#endif
#ifndef S_ISPORT
# define S_ISPORT(m) 0   /* Solaris event port */
#endif
#ifndef S_ISWHT
# define S_ISWHT(m) 0    /* BSD whiteout */
#endif
#ifndef S_ISOFD
# define S_ISOFD(m) 0    /* Cray offline, with data */
#endif
#ifndef S_ISOFL
# define S_ISOFL(m) 0    /* Cray offline, with no data */
#endif

/* From wchar.in.h.  gnulib zeroes an mbstate_t with this rather than with
   memset, because on some libcs only a prefix of the struct has to be zero;
   ntlibc's mbstate_t is a two-word struct with no such subtlety, so zeroing
   all of it is both correct and what gnulib's own definition reduces to
   there.  quotearg.c and mbswidth.c call it. */
#include <wchar.h>
#include <string.h>
#ifndef mbszero
# define mbszero(ps) ((void) memset ((ps), 0, sizeof (mbstate_t)))
#endif

/* The four functions gnulib ADDS to <string.h> and <wchar.h> that findutils
   calls.  Each is defined by a gnulib .c file this build compiles; what the
   generated header contributed was only the prototype.  Without these the
   compiler falls back to the implicit `int' declaration and the failure is
   quiet: lib/buildcmd.c:102 assigns mbsstr's result to a char *, which on
   this 32-bit target happens to survive, and would not on a 64-bit one.
   They are declared here rather than left to chance for exactly that
   reason.

     mbsstr    (string.in.h)  lib/buildcmd.c and find/parser.c, to find {}
                              in an -exec argument in a multibyte-safe way
     mbslen    (string.in.h)  gl/lib/mbsstr.c
     wmempcpy  (wchar.in.h)   gl/lib/fnmatch_loop.c
     wcwidth   (wchar.in.h)   lib/qmark.c, and shim/uchar.h's c32width */
extern char *mbsstr (const char *haystack, const char *needle);
extern size_t mbslen (const char *string);
extern wchar_t *wmempcpy (wchar_t *dest, const wchar_t *src, size_t n);
extern int wcwidth (wchar_t wc);

#endif /* _GL_NT_MISSING_DECLS_H */
