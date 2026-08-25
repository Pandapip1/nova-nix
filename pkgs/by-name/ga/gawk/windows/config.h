/* What ./configure would have discovered about ntlibc, written out.
 *
 * The Linux build of this same gawk runs gawk's own ./configure under bash.
 * This side does not: see the head of default.nix for why.  So the answers
 * are asserted here instead, in the shape grep, sed, gzip and tar use.
 *
 * A header rather than a wall of -D, for the reason tar has one: kaem runs a
 * command line without a shell, and a -D whose value contains quotes -- and
 * DEFPATH is one, gawk's own Makefile.in spells it -DDEFPATH='$(DEFPATH)' --
 * cannot be written on one.  HAVE_CONFIG_H and GAWK are the two -D left; see
 * build.kaem for what each is.
 *
 * awk.h includes this file and then custom.h, which is gawk's own "autoconf
 * got it wrong here" file.  Nothing in custom.h fires: every one of its
 * blocks is guarded on a compiler or OS macro (__host_mips, VMS_POSIX,
 * __QNX__, __amigaos__, _SEQUENT_, __dest_os) and this tcc defines none of
 * them.  It was measured, not assumed -- this tcc predefines _WIN32,
 * __STDC__ and __STDC_VERSION__ and essentially nothing else.
 */

#ifndef GAWK_CONFIG_H
#define GAWK_CONFIG_H

/* tcc is an ANSI compiler with the ANSI headers.  Three separate things in
   awk.h hang off this, and all three are wanted:
     - <stdlib.h> is included rather than gawk's own protos.h, which is a
       1993 list of K&R prototypes (`extern char *malloc();') that would
       contradict the real declarations;
     - ISASCII(c) becomes the constant 1 rather than isascii(c), which is
       what the ctype macros above it want on an 8-bit-clean library;
     - the const and volatile keywords are left alone.  Without __STDC__ or
       STDC_HEADERS awk.h does `#define const' to nothing, and awk.h's own
       `const char *filespec' parameters then stop matching their callers. */
#define STDC_HEADERS 1
#define PROTOTYPES 1

/* awk.h uses `#' to stringize a macro argument in its lint messages.  tcc
   has a conforming preprocessor; the fallback path is the K&R `x' comment
   trick, which tcc's preprocessor does not implement and never will. */
#define HAVE_STRINGIZE 1

/* Headers ntlibc has, of the eight gawk asks about.
     HAVE_STDARG_H  chooses <stdarg.h> over <varargs.h>, which does not exist
                    here and would not work with this compiler if it did.
     HAVE_STRING_H  chooses <string.h>.  Note that HAVE_STRINGS_H is NOT
                    defined below even though ntlibc has <strings.h>: awk.h
                    reads them as alternatives, and taking the <strings.h>
                    branch loses every str* declaration.  The answer is true
                    and still withheld.
     HAVE_SYS_PARAM_H, HAVE_SYS_WAIT_H
                    io.c includes both; sys/wait.h is what gives it WIFEXITED
                    and WEXITSTATUS for the exit status of a `cmd' | getline
                    pipeline and of system().
     HAVE_LIMITS_H  awk.h; INT_MAX and friends.
     HAVE_LOCALE_H  awk.h; see HAVE_SETLOCALE below.
     HAVE_UNISTD_H  awk.h; read, write, lseek, isatty, getpid.
   Not defined, because the header does not exist here: HAVE_MEMORY_H (which
   awk.h reads as NEED_MEMORY_H anyway) and HAVE_SIGNUM_H. */
#define HAVE_LIMITS_H 1
#define HAVE_LOCALE_H 1
#define HAVE_STDARG_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_WAIT_H 1
#define HAVE_UNISTD_H 1

/* alloca is a real cdecl function in ntlibc -- arch/i386/src/alloca.S, which
   exists precisely so that a compiler with no __builtin_alloca can call it --
   and its <alloca.h> declares it.  Both answers are honest, so C_ALLOCA and
   STACK_DIRECTION are absent and gawk's alloca.c is not compiled. */
#define HAVE_ALLOCA 1
#define HAVE_ALLOCA_H 1

/* Functions ntlibc has.  Nine of these ten are read by exactly one file,
   missing.c, whose entire body is ten #ifndefs each pulling in a replacement
   from missing/.  Saying yes to all of them is what makes missing.c compile
   to an object with no symbols in it, which is the point: every one of those
   replacements is a 1980s stand-in that would be linked ahead of libc.a and
   would therefore win silently.  missing/strftime.c is the one that matters
   most -- it is a 700-line reimplementation with its own timezone handling.
   HAVE_FMOD is the exception: eval.c reads it, and without it gawk computes
   `%' by hand with a subtraction loop. */
#define HAVE_FMOD 1
#define HAVE_MEMCMP 1
#define HAVE_MEMCPY 1
#define HAVE_MEMSET 1
#define HAVE_STRCHR 1
#define HAVE_STRERROR 1
#define HAVE_STRFTIME 1
#define HAVE_STRNCASECMP 1
#define HAVE_STRTOD 1
#define HAVE_SYSTEM 1
#define HAVE_TZSET 1

/* Without this awk.h rewrites vfprintf as _doprnt, a System V internal.
   gawk's msg.c and builtin.c both go through vfprintf. */
#define HAVE_VPRINTF 1

/* ntlibc's setlocale is real and its <locale.h> has LC_CTYPE and LC_COLLATE,
   which are the two main.c sets.  The Linux recipe's counterpart of this is
   `-DLC_ALL=' -- a mes-libc workaround that makes setlocale() expand to
   nothing.  Nothing of the sort is needed or wanted here; withholding
   HAVE_SETLOCALE would do the same damage, since awk.h defines setlocale
   away when it is absent. */
#define HAVE_SETLOCALE 1

/* struct stat here carries st_blksize, so posix/gawkmisc.c's optimal_bufsize
   reads the file's own answer instead of falling back to BUFSIZ. */
#define HAVE_ST_BLKSIZE 1

/* ntlibc's is pid_t getpgrp(void), the POSIX spelling, so io.c must call it
   with no argument.  This is one of the two answers the Linux build has to
   set by hand (ac_cv_func_getpgrp_void=yes) because configure cannot work it
   out by running a test program. */
#define GETPGRP_VOID 1

/* io.c declares GETGROUPS_T groupset[NGROUPS_MAX] for /dev/user.  ntlibc's
   getgroups takes gid_t *, and its <limits.h> has NGROUPS_MAX. */
#define GETGROUPS_T gid_t

/* signal handlers here return void; main.c casts catchsig to
   RETSIGTYPE (*)(int) before installing it. */
#define RETSIGTYPE void

/* Only read from protos.h, which STDC_HEADERS keeps out of the build.  Named
   anyway so that the answer is not a matter of luck if that ever changes. */
#define SPRINTF_RET int

/* The AWKPATH default: the directory list io.c's do_pathopen searches for a
   `-f progfile' that is not already a path.  gawk's Makefile.in makes this
   ".:$(datadir)", pointing at an installed awklib of shared .awk files.
   Nothing installs one here and a store path is read-only, so the list is the
   current directory alone.  It has to be in this file rather than on the
   command line because its value contains the quotes.
   Note that envsep stays ':' (posix/gawkmisc.c), which is only safe because
   this list has no drive letter in it. */
#define DEFPATH "."

/* Six answers deliberately NOT given, five of them true:
 *
 *   HAVE_STRINGS_H   ntlibc has the header.  See HAVE_STRING_H above: awk.h
 *                    treats the two as alternatives and takes the wrong one.
 *
 *   HAVE_MMAP        ntlibc has no mmap, and it would not matter if it did:
 *                    io.c undefines HAVE_MMAP on its own line 27, with the
 *                    comment "for now, probably forever".  HAVE_GETPAGESIZE
 *                    and HAVE_MADVISE are absent for the same reason --
 *                    nothing reads them outside the mmap blocks.
 *
 *   HAVE_TM_ZONE,    ntlibc's struct tm has tm_zone and tm_gmtoff, and
 *   HAVE_TZNAME      tzname[] as well.  Both are read only by
 *                    missing/strftime.c, which HAVE_STRFTIME keeps out of
 *                    the build.
 *
 *   TIME_WITH_SYS_TIME, TM_IN_SYS_TIME
 *                    the first is read by nothing in this tree at all, the
 *                    second only by missing/strftime.c.
 *
 *   REGEX_MALLOC     gawk's regex.c would then malloc its working buffers
 *                    instead of alloca'ing them.  ntlibc's alloca is a real
 *                    stack adjustment (see HAVE_ALLOCA), so the default path
 *                    is correct and is also the faster one.
 *
 * And two that are about features rather than about the library: BITOPS and
 * NONDECDATA, gawk 3.0.6's two undocumented extensions.  configure only
 * defines them for --enable-switch-style flags nobody passes, and a
 * bootstrap awk should behave the way the awk that built it did.
 */

#endif
