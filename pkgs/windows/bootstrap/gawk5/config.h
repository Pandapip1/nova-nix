/* What gawk 5.3.2's ./configure would have discovered about ntlibc, written
 * out.
 *
 * The Linux build of this same gawk runs gawk's own ./configure under bash
 * and then make.  This side does not: see the head of default.nix for why.
 * So the answers are asserted here, in the shape grep, sed, gzip, tar and
 * gawk 3.0.6 assert theirs.
 *
 * A header rather than a wall of -D, for the reason tar and gawk 3.0.6 have
 * one: kaem runs a command line without a shell, and a -D whose value
 * contains quotes -- DEFPATH, DEFLIBPATH and SHLIBEXT are three, gawk's own
 * Makefile.am spells them -DDEFPATH='$(DEFPATH)' -- cannot be written on
 * one.  HAVE_CONFIG_H and GAWK are the two -D left; see build.kaem for what
 * each is and why GAWK is load-bearing here where it was cargo in 3.0.6.
 *
 * The file ends the way configh.in ends -- the stdbool block and then
 * #include "custom.h" -- and both halves of that tail are load-bearing.  See
 * the comment down there.
 */

#ifndef GAWK_CONFIG_H
#define GAWK_CONFIG_H

/* AC_USE_SYSTEM_EXTENSIONS.  This one is load-bearing and was the second
   thing that had to be got right (the first was bool, below).
   support/regex.h declares the GNU interface underneath the POSIX one --
   struct re_pattern_buffer, struct re_registers, re_compile_pattern,
   re_search, re_set_syntax -- only inside `#ifdef _GNU_SOURCE', and awk.h's
   `typedef struct Regexp' embeds both of those structs BY VALUE.  Without
   this, every file that includes awk.h fails with "field 'regs' has
   incomplete type", which is a confusing way to be told that a feature-test
   macro is missing.  configure emits it from AC_USE_SYSTEM_EXTENSIONS, which
   is why configh.in has it as a #ifndef/#undef pair rather than in the plain
   #undef list. */
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif

/* Identity.  configure fills these from AC_INIT; version.c prints
   PACKAGE_STRING and main.c uses PACKAGE_BUGREPORT in --help. */
#define PACKAGE "gawk"
#define PACKAGE_NAME "GNU Awk"
#define PACKAGE_TARNAME "gawk"
#define PACKAGE_VERSION "5.3.2"
#define PACKAGE_STRING "GNU Awk 5.3.2"
#define PACKAGE_BUGREPORT "bug-gawk@gnu.org"
#define PACKAGE_URL "https://www.gnu.org/software/gawk/"
#define VERSION "5.3.2"

/* The target is ILP32 PE32.  int_array.c and node.c read these to decide
   how an integer subscript is stored and how a pointer is hashed. */
#define SIZEOF_UNSIGNED_INT 4
#define SIZEOF_UNSIGNED_LONG 4
#define SIZEOF_VOID_P 4

/* tcc is an ANSI compiler with the ANSI headers, and its preprocessor is
   conforming -- HAVE_STRINGIZE picks `#' over the K&R `x' comment
   trick, which tcc does not implement and never will. */
#define STDC_HEADERS 1
#define HAVE_STRINGIZE 1

/* Integer types.  <stdint.h> and <inttypes.h> are both real here, so the
   intmax_t/uintmax_t fallback typedefs at the bottom of configh.in are not
   needed and are absent. */
#define HAVE_LONG_LONG_INT 1
#define HAVE_UNSIGNED_LONG_LONG_INT 1
#define HAVE_INTMAX_T 1
#define HAVE_UINTMAX_T 1
#define HAVE_WINT_T 1
#define HAVE_WCTYPE_T 1

/* Headers ntlibc has, of the two dozen gawk asks about.
     HAVE_SYS_WAIT_H     io.c and builtin.c; WIFEXITED and WEXITSTATUS.
     HAVE_SYS_SELECT_H   io.c, for the two-way coprocess timeout.
     HAVE_SYS_IOCTL_H,
     HAVE_TERMIOS_H      io.c; both arrived in ntlibc 2c40c74.
     HAVE_WCHAR_H,
     HAVE_WCTYPE_H       node.c's wide-string cache and support/dfa.c's
                         multibyte path.  Both are real, and the C locale
                         keeps MB_CUR_MAX at 1 so neither path runs, but
                         both must compile.
   Not defined, because the header does not exist here: HAVE_MEMORY_H,
   HAVE_STROPTS_H, HAVE_MCHECK_H, HAVE_LIBINTL_H, HAVE_NETDB_H,
   HAVE_NETINET_IN_H, HAVE_ARPA_INET_H, HAVE_SYS_SOCKET_H, HAVE_SPAWN_H,
   HAVE_SYS_PERSONALITY_H, HAVE_MINIX_CONFIG_H.
   Note there is no HAVE_LANGINFO_CODESET either, and that one is not a
   simple absence -- see langinfo.h and nt-missing.c beside this file. */
#define HAVE_FCNTL_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_LIMITS_H 1
#define HAVE_LOCALE_H 1
#define HAVE_STDBOOL_H 1
#define HAVE_STDDEF_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDIO_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_STRINGS_H 1
#define HAVE_SYS_IOCTL_H 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_SELECT_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_WAIT_H 1
#define HAVE_TERMIOS_H 1
#define HAVE_UNISTD_H 1
#define HAVE_WCHAR_H 1
#define HAVE_WCTYPE_H 1

/* HAVE_STRINGS_H is defined here and was deliberately WITHHELD in the 3.0.6
   sibling, and the difference is in awk.h rather than in ntlibc.  3.0.6's
   awk.h reads <string.h> and <strings.h> as ALTERNATIVES, so admitting the
   second one loses every str* declaration; 5.3.2's awk.h includes each under
   its own #ifdef, one after the other, so the true answer is also the safe
   one.  It was re-read rather than carried over. */

/* Functions ntlibc has.  Most of these are read by exactly one file,
   replace.c, whose entire body is a stack of #ifndefs each pulling in a
   replacement from missing_d/.  Saying yes to all of them is what makes
   replace.c compile to an object with no symbols in it, which is the point:
   every one of those replacements is an old stand-in that would be linked
   ahead of libc.a and would therefore win SILENTLY.  missing_d/strftime.c
   and missing_d/mktime.c are the two that matter most.
   The exceptions, which real code reads rather than replace.c:
     HAVE_FMOD          eval.c, for `%' on doubles.
     HAVE_SETLOCALE     main.c; see the note below.
     HAVE_GETGROUPS     io.c, for /dev/user.
     HAVE_ISWCTYPE,
     HAVE_ISWUPPER,
     HAVE_ISWLOWER,
     HAVE_TOWUPPER,
     HAVE_TOWLOWER,
     HAVE_WCTYPE,
     HAVE_MBRLEN,
     HAVE_MBRTOWC,
     HAVE_WCRTOMB,
     HAVE_BTOWC         node.c and builtin.c, wide-character support.
     HAVE_CLOCK_GETTIME,
     HAVE_GETTIMEOFDAY  builtin.c's systime()/PROCINFO.
     HAVE_ALARM,
     HAVE_SIGPROCMASK,
     HAVE_SETSID,
     HAVE_GETDTABLESIZE,
     HAVE_ATEXIT,
     HAVE_TMPFILE,
     HAVE_MKSTEMP,
     HAVE_LSTAT,
     HAVE_GETGRENT,
     HAVE_ISASCII,
     HAVE_ISBLANK       scattered through io.c, main.c and builtin.c. */
#define HAVE_ALARM 1
#define HAVE_ATEXIT 1
#define HAVE_BTOWC 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_FMOD 1
/* HAVE_FWRITE_UNLOCKED was 1 through the ntlibc pin that shipped
   fwrite_unlocked (and ten sibling _unlocked aliases) in <stdio.h>; that pin
   removed them as part of a 28-symbol deletion batch, having confirmed --
   for every package audited at the time -- that nothing in this chain called
   them. gawk 5.3.2 turned out to be the exception: awk.h `#define fwrite
   fwrite_unlocked' under this flag, unconditionally, so every fwrite() call
   in io.c became a call to a symbol ntlibc no longer defines, and tcc failed
   the link with "unresolved reference to 'fwrite_unlocked'". Left at 0 (i.e.
   not defined here), awk.h's #ifdef leaves `fwrite' as plain fwrite() --
   already declared by ntlibc's <stdio.h> and already linked into every other
   package in this chain -- which is exactly what fwrite_unlocked was an
   unlocking *optimization* over. This bootstrap is single-threaded, so the
   locking fwrite() does costs nothing observable; there is no correctness
   difference, only a foregone micro-optimization. Package-side fix, per the
   ntlibc-coordination convention: ntlibc is not asked to keep a symbol on
   this port's account. */
#define HAVE_GETDTABLESIZE 1
#define HAVE_GETGRENT 1
#define HAVE_GETGROUPS 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_ISASCII 1
#define HAVE_ISBLANK 1
#define HAVE_ISWCTYPE 1
#define HAVE_ISWLOWER 1
#define HAVE_ISWUPPER 1
#define HAVE_LSTAT 1
#define HAVE_MBRLEN 1
#define HAVE_MBRTOWC 1
#define HAVE_MEMCMP 1
#define HAVE_MEMCPY 1
#define HAVE_MEMMOVE 1
#define HAVE_MEMSET 1
#define HAVE_MKSTEMP 1
#define HAVE_MKTIME 1
#define HAVE_SETENV 1
#define HAVE_SETLOCALE 1
#define HAVE_SETSID 1
#define HAVE_SIGPROCMASK 1
#define HAVE_SNPRINTF 1
#define HAVE_STRCASECMP 1
#define HAVE_STRCHR 1
#define HAVE_STRCOLL 1
#define HAVE_STRERROR 1
#define HAVE_STRFTIME 1
#define HAVE_STRNCASECMP 1
#define HAVE_STRSIGNAL 1
#define HAVE_STRTOD 1
#define HAVE_STRTOUL 1
#define HAVE_SYSTEM 1
#define HAVE_TIMEGM 1
#define HAVE_TMPFILE 1
#define HAVE_TOWLOWER 1
#define HAVE_TOWUPPER 1
#define HAVE_TZSET 1
#define HAVE_USLEEP 1
#define HAVE_WAITPID 1
#define HAVE_WCRTOMB 1
#define HAVE_WCTYPE 1

/* HAVE_SETLOCALE is the Linux recipe's `-DLC_ALL=' seen from the other side.
   That flag is a mes-libc workaround that makes setlocale() expand to
   nothing; ntlibc's setlocale is real and its <locale.h> has LC_ALL,
   LC_CTYPE, LC_COLLATE, LC_NUMERIC, LC_TIME and LC_MESSAGES, which are the
   six main.c sets.  Nothing of the sort is translated here, and withholding
   HAVE_SETLOCALE would do the same damage from the other direction. */

/* Types and struct members.
     GETPGRP_VOID       ntlibc's is pid_t getpgrp(void), the POSIX spelling,
                        so io.c must call it with no argument.  This is one
                        of the answers configure cannot reach by running a
                        test program, and one of the two the Linux build has
                        to supply by hand as an ac_cv_.
     GETGROUPS_T        io.c declares GETGROUPS_T groupset[] for /dev/user;
                        ntlibc's getgroups takes gid_t *.
     HAVE_STRUCT_STAT_ST_BLKSIZE
                        struct stat carries st_blksize, so
                        posix/gawkmisc.c's optimal_bufsize reads the file's
                        own answer instead of falling back to BUFSIZ.
     HAVE_TM_ZONE, HAVE_STRUCT_TM_TM_ZONE, HAVE_TZNAME, HAVE_DECL_TZNAME
                        struct tm has tm_zone and tm_gmtoff, and <time.h>
                        declares tzname[].  Read by builtin.c's strftime()
                        wrapper for %Z, and by missing_d/strftime.c, which
                        HAVE_STRFTIME keeps out of the build.
     TIME_T_IN_SYS_TYPES_H
                        <sys/types.h> defines time_t, which is what awk.h
                        checks before reaching for <time.h> itself. */
#define GETPGRP_VOID 1
#define GETGROUPS_T gid_t
#define HAVE_STRUCT_STAT_ST_BLKSIZE 1
#define HAVE_STRUCT_TM_TM_ZONE 1
#define HAVE_TM_ZONE 1
#define HAVE_DECL_TZNAME 1
#define HAVE_TZNAME 1
#define TIME_T_IN_SYS_TYPES_H 1

/* ntlibc's printf understands %a and %F, so gawk may pass them through.
   Without the first, printf.c has no `case 'a'' at all and awk's printf
   treats %a as an unknown format; without the second, printf.c and eval.c
   rewrite %F to %f before handing it over.  Both answers were checked by
   running the built binary against the host gawk -- `printf "%a|%A|%F|%f"'
   and %F of an infinity and a NaN come out byte for byte the same -- rather
   than inferred from the C library's source. */
#define PRINTF_HAS_A_FORMAT 1
#define PRINTF_HAS_F_FORMAT 1

/* The AWKPATH default: the directory list io.c's do_pathopen searches for a
   `-f progfile' that is not already a path.  gawk's Makefile.am makes this
   ".$(PATH_SEPARATOR)$(pkgdatadir)", pointing at an installed awklib of
   shared .awk files.  Nothing installs one here and a store path is
   read-only, so the list is the current directory alone.  DEFLIBPATH and
   SHLIBEXT are the same three lines for AWKLIBPATH and `@load', which
   nothing can use because DYNAMIC is not defined -- they are named so that
   io.c and ext.c have a value rather than a build error.
   These have to be in this file rather than on the command line because
   their values contain the quotes.  Note that posix/gawkmisc.c's envsep
   stays ':', which is only safe because this list has no drive letter. */
#define DEFPATH "."
#define DEFLIBPATH "."
#define SHLIBEXT "dll"

/*
 * Answers deliberately NOT given, and why -- the interesting half of the
 * file.
 *
 *   HAVE_C_BOOL       tcc is C99: `bool' is not a keyword and <stdbool.h>
 *                     is what supplies it.  Withholding this is what makes
 *                     the trailer below include that header, and it is the
 *                     first thing this port had to get right: with
 *                     HAVE_C_BOOL defined, every file fails at
 *                     support/dfa.h:45 with "';' expected (got 'bool')".
 *
 *   HAVE_MPFR         no MPFR and no GMP anywhere in this chain, so -M and
 *                     PREC/ROUNDMODE are absent.  mpfr.c still compiles --
 *                     to a handful of stubs that call fatal().
 *
 *   DYNAMIC           no dlopen in ntlibc, so `@load' and the extension API
 *                     are out.  ext.c compiles to the same kind of stub.
 *
 *   ENABLE_NLS, HAVE_GETTEXT, HAVE_DCGETTEXT, HAVE_LC_MESSAGES
 *                     no libintl.  gettext.h then defines gettext(x) to x,
 *                     which is what an English-only bootstrap wants.
 *
 *   HAVE_LIBREADLINE, HAVE_HISTORY_LIST
 *                     no readline, so gawk's debugger reads its commands
 *                     with fgets.  command.c and debug.c are compiled all
 *                     the same -- awkgram.c references do_debug.
 *
 *   HAVE_SOCKETS, HAVE_GETADDRINFO, HAVE_GAI_STRERROR, HAVE_SOCKADDR_STORAGE
 *                     ntlibc has no sockets at all, so /inet/... is not a
 *                     special file here.  Note HAVE_SOCKETS is also what
 *                     gates missing_d/getaddrinfo.c inside replace.c, so
 *                     withholding it withholds that too.
 *
 *   USE_PERSISTENT_MALLOC
 *                     pma.c wants mmap, which ntlibc does not have.  Without
 *                     it PROCINFO["pma"] is absent and -M's persistent
 *                     arrays are not offered, which is the honest answer.
 *
 *   HAVE_MMAP, HAVE_PERSONALITY, HAVE_ADDR_NO_RANDOMIZE, HAVE_GRANTPT,
 *   HAVE_POSIX_OPENPT, HAVE_ICONV, HAVE_MTRACE, HAVE_MCHECK_H,
 *   HAVE_CFLOCALECOPYPREFERREDLANGUAGES, HAVE_CFPREFERENCESCOPYAPPVALUE,
 *   HAVE__NSGETEXECUTABLEPATH, HAVE___ETOA_L, HAVE_C_VARARRAYS
 *                     none of these exist here; each is read only inside a
 *                     block that is then not compiled.
 *
 *   HAVE_LANGINFO_CODESET
 *                     ntlibc has neither <langinfo.h> nor nl_langinfo, and
 *                     this one is NOT simply a withheld answer: support's
 *                     regcomp.c includes <langinfo.h> and calls
 *                     nl_langinfo(CODESET) unconditionally, outside every
 *                     #ifdef.  Both are supplied by this package instead --
 *                     see langinfo.h and nt-missing.c beside this file.
 *                     Defining HAVE_LANGINFO_CODESET as well would only add
 *                     io.c's charset sniffing, which has nothing to sniff.
 *
 *   NO_LINT           --lint is wanted; it is what a build script above here
 *                     would use to find out that its awk program is wrong.
 *
 *   SUPPLY_INTDIV     an --enable-builtin-intdiv0 flag nobody passes.  A
 *                     bootstrap awk should offer the same builtins the awk
 *                     that built it offered.
 *
 *   USE_EBCDIC        no.
 *
 *   _FILE_OFFSET_BITS, _LARGE_FILES
 *                     ntlibc's off_t is 64-bit already and its <features.h>
 *                     does not read either macro.
 *
 *   const, inline, restrict, size_t, ssize_t, pid_t, uid_t, gid_t,
 *   intmax_t, uintmax_t, socklen_t, __STDC_NO_VLA__
 *                     the compatibility typedefs and keyword fallbacks at
 *                     the bottom of configh.in.  tcc has all the keywords
 *                     and ntlibc has all the types, so every one of these
 *                     is left undefined, which is what configure does when
 *                     the real thing is present.
 *
 *   TM_IN_SYS_TIME    read only by missing_d/strftime.c, which is not built.
 *
 *   HAVE_STRUCT_PASSWD_PW_PASSWD, HAVE_STRUCT_GROUP_GR_PASSWD
 *                     these two are FALSE: ntlibc's struct passwd is name,
 *                     uid, gid, dir, shell and its struct group is name, gid,
 *                     mem -- neither carries a password field, because there
 *                     is no /etc/passwd behind them (src/misc/pwd.c answers
 *                     from the NT token).  Nothing in the files this package
 *                     compiles reads either macro; they are named here
 *                     because they were briefly and wrongly asserted, and
 *                     because the answer is not obvious from a header name.
 */

/* configh.in's own trailer, reproduced, and both halves are load-bearing.
 *
 * The first half is what supplies `bool': see HAVE_C_BOOL above.
 *
 * The second is `#include "custom.h"' -- gawk's "autoconf got it wrong here"
 * file.  In 3.0.6 that file was included by awk.h and nothing in it fired;
 * in 5.3.2 it is included from config.h and it is not optional, because the
 * bottom of it is unconditional and defines FLEXIBLE_ARRAY_MEMBER (which
 * support/dfa.h and support/regex_internal.h declare arrays with),
 * _GL_ATTRIBUTE_PURE, and the xreallocarray/xizalloc/xicalloc/xirealloc/
 * ximalloc aliases the support library allocates through.  Everything ABOVE
 * that in custom.h is guarded on a compiler or OS macro -- VMS_POSIX,
 * __VMS, __QNX__, __APPLE__, hpux, _AIX, __MVS__ -- and this tcc defines
 * none of them.  That was measured: this tcc predefines _WIN32, __STDC__ and
 * __STDC_VERSION__ and essentially nothing else, and in particular not
 * __GNUC__, which is why the _GL_ATTRIBUTE_PURE fallback is the empty one.
 */
#ifndef HAVE_C_BOOL
# if !defined __cplusplus && !defined __bool_true_false_are_defined
#  if HAVE_STDBOOL_H
#   include <stdbool.h>
#  else
#   error "<stdbool.h> does not exist on this platform."
#  endif
# endif
# if !true
#  define true (!false)
# endif
#endif

#include "custom.h"

#endif
