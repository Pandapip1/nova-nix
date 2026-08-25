/* What ./configure would have discovered about ntlibc, written out.
 *
 * live-bootstrap's makefile hands sed its answers as -D on the compiler
 * command line, and one of them is -DVERSION=\"4.0.9\".  That does not
 * survive here: make on this side runs its recipes without a shell -- there
 * is none below it -- and falls back to one the moment a command line
 * contains a shell metacharacter, which a quoted string is.  A header has no
 * quoting problem, and sed/sed.h includes <config.h> already (guarded by
 * HAVE_CONFIG_H, which is the one -D that stays on the command line).
 *
 * The Linux build gets by with six defines because Mes's C library has
 * almost nothing to declare.  ntlibc does, so most of this file is the
 * "define what the library actually has" half of the porting rule -- and the
 * two conspicuous absences below are the other half.
 */

#ifndef SED_CONFIG_H
#define SED_CONFIG_H

/* The six the Linux build passes on the command line.  ENABLE_NLS is 0
   rather than undefined because sed tests its value, not its definedness. */
#define PACKAGE "sed"
#define VERSION "4.0.9"
#define SED_FEATURE_VERSION "4.0"
#define ENABLE_NLS 0

/* Headers ntlibc has.  <wctype.h> is here and real -- unlike coreutils,
   which had to do without it -- but nothing turns on it, because
   RE_ENABLE_I18N in lib/regex_internal.h wants HAVE_WCSCOLL too and ntlibc
   has no wcscoll.  The regex engine therefore compiles single-byte, which
   is the whole of the C locale this bootstrap has anyway. */
#define STDC_HEADERS 1
#define HAVE_ALLOCA_H 1
#define HAVE_FCNTL_H 1
#define HAVE_LIMITS_H 1
#define HAVE_LOCALE_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1
#define HAVE_WCHAR_H 1
#define HAVE_WCTYPE_H 1

/* Two headers deliberately not claimed, although a name for each exists:
 *
 *   HAVE_STRINGS_H  sed.c, execute.c and compile.c read it as "this system
 *                   keeps the string functions in <strings.h>" and include
 *                   that one INSTEAD of <string.h>.  That was true of V7;
 *                   it is not true of ntlibc, whose <strings.h> holds only
 *                   bcopy, bzero and the strcasecmp family, so claiming it
 *                   would lose every declaration those files need.
 *   HAVE_MEMORY_H   there is no <memory.h> to include.
 *
 * Both are the shape of mistake this port keeps meeting from the other
 * direction: a define that describes the library correctly on paper and
 * makes the source do the wrong thing.
 */

/* Functions ntlibc has.  alloca is a real cdecl function in ntlibc (see its
   <alloca.h>), not a compiler builtin -- tcc has none -- so HAVE_ALLOCA is
   an honest answer and lib/alloca.c is not built.  */
#define HAVE_ALLOCA 1
#define HAVE_FCHMOD 1
#define HAVE_ISASCII 1
#define HAVE_ISATTY 1
#define HAVE_ISBLANK 1
#define HAVE_MBRTOWC 1
#define HAVE_MEMCHR 1
#define HAVE_MEMCPY 1
#define HAVE_MEMMOVE 1
#define HAVE_MKSTEMP 1
#define HAVE_POPEN 1
#define HAVE_SETLOCALE 1
#define HAVE_STRERROR 1
#define HAVE_STRCHR 1
#define HAVE_STRTOUL 1
#define HAVE_STRVERSCMP 1
#define HAVE_VPRINTF 1
#define HAVE_VFPRINTF 1

/* HAVE_MEMPCPY is not claimed although ntlibc defines mempcpy: its
   declaration in <string.h> is behind _GNU_SOURCE, and lib/regcomp.c calls
   the function without asking for it.  The alternative -- defining
   _GNU_SOURCE for the whole build to win back one memcpy -- moves far more
   than it is worth.  */

/* fmt.c uses strchr and memmove and includes no header that declares them;
   it reaches this file through sed.h, which every sed/*.c includes first.
   Left alone, both would be implicit declarations returning int, which
   happens to work on a 32-bit target and would stop working the moment
   anything here were not.  */
#include <string.h>

#endif
