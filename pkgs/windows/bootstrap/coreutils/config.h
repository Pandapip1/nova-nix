/* What ./configure would have discovered about ntlibc, written out.
 *
 * The Linux build of this package gets the same answers as one -D per line
 * on the make command line, because live-bootstrap's makefile puts them in
 * CFLAGS.  That does not work here: make on this side runs its recipes
 * without a shell -- there is none yet -- and falls back to the shell the
 * moment a command line contains a shell metacharacter.  `-DDIR_TO_FD\(D\)'
 * and `-DPACKAGE=\"coreutils\"' are full of them.  A header has no quoting
 * problem at all, and coreutils' own sources include <config.h> anyway.
 *
 * Everything here is an answer, not a workaround; where an answer differs
 * from the Linux build's the reason is beside it.
 */

#define PACKAGE "coreutils"
#define PACKAGE_NAME "GNU coreutils"
#define GNU_PACKAGE "GNU coreutils"
#define PACKAGE_BUGREPORT "bug-coreutils@gnu.org"
#define PACKAGE_VERSION "5.0"
#define VERSION "5.0"

/* Headers.  ntlibc has all of these; the Linux build claims far fewer
   because Mes's C library does not.  <unistd.h> in particular is worth
   naming: it is what defines _POSIX_VERSION, and test.c reaches for
   <sys/file.h> when _POSIX_VERSION is not defined.  */
#define STDC_HEADERS 1
#define HAVE_ALLOCA_H 1
#define HAVE_DIRENT_H 1
#define HAVE_FCNTL_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_LIMITS_H 1
#define HAVE_LOCALE_H 1
#define HAVE_MEMORY_H 1
#define HAVE_STDBOOL_H 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_STRINGS_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_WAIT_H 1
#define HAVE_UNISTD_H 1
#define HAVE_UTIME_H 1
#define HAVE_WCHAR_H 1
#define TIME_WITH_SYS_TIME 1

/* <wctype.h> is deliberately absent: ntlibc has no such header, and
   quotearg.c's fallback for a missing iswprint -- treat every wide
   character as printable -- is the right answer for a library with no
   locale beyond "C".  */

#define HAVE_STRUCT_TIMESPEC 1
#define HAVE_STRUCT_UTIMBUF 1

/* intmax_t is long long here, so the branch of lib/strtoimax.c that hands
   off to strtoll is the one that has to be taken; the other branch is a
   compile-time assertion that intmax_t is long, and fails.  The unsigned
   half of the same file tests the second name.  */
#define HAVE_LONG_LONG 1
#define HAVE_UNSIGNED_LONG_LONG 1

#define HAVE_DECL_FREE 1
#define HAVE_DECL_MALLOC 1
#define HAVE_DECL_REALLOC 1
#define HAVE_DECL_GETENV 1
#define HAVE_DECL_MEMCHR 1
#define HAVE_DECL_STRTOL 1
#define HAVE_DECL_STRTOLL 1
#define HAVE_DECL_STRTOUL 1
#define HAVE_DECL_STRTOULL 1
#define HAVE_DECL_STRERROR 1
#define HAVE_DECL_DIRFD 1

/* Not declared anywhere in ntlibc, and gnulib's __fpending.c falls back to
   a portable guess when told so.  PENDING_OUTPUT_N_BYTES is that guess.  */
#define HAVE_DECL___FPENDING 0
#define PENDING_OUTPUT_N_BYTES 1

/* wcwidth is not there either; the callers then assume one column per
   character, which is all a C locale ever needed.  */
#define HAVE_DECL_WCWIDTH 0

#define HAVE_MALLOC 1
#define HAVE_REALLOC 1
#define HAVE_GETCWD 1
#define HAVE_RMDIR 1
#define HAVE_STRERROR 1
#define HAVE_SETLOCALE 1
#define HAVE_MBRTOWC 1
#define HAVE_MBSINIT 1
#define HAVE_DIRFD 1
#define HAVE_UTIME 1
#define HAVE_UTIMES 1
#define HAVE_NANOSLEEP 1
#define HAVE_LSTAT 1
#define HAVE_READLINK 1
#define HAVE_SYMLINK 1
#define HAVE_MEMCPY 1
#define HAVE_MEMMOVE 1
#define HAVE_MEMSET 1
#define HAVE_STRCHR 1
#define HAVE_STRRCHR 1

/* rmdir on a non-empty directory reports ENOTEMPTY, as POSIX says.  The
   Linux build writes the numbers 39 and 1 here because Mes's C library
   does not define the names.  */
#define RMDIR_ERRNO_NOT_EMPTY ENOTEMPTY

/* NT resolves a trailing slash on a symlink to the target, so lstat("l/")
   behaves like stat.  */
#define LSTAT_FOLLOWS_SLASHED_SYMLINK 1

/* No translations are installed, so there is no directory to look in.  */
#define LOCALEDIR NULL

/* Where gnulib's localcharset.c looks for a charset.alias table.  Nothing
   installs one; the lookup fails and the C locale's charset is used, which
   is the only one this bootstrap has.  */
#define LIBDIR "/no-charset-alias"

/* An upper bound on the descriptors the utilities keep open at once.  */
#define UTILS_OPEN_MAX 1000

/* Renames, not discoveries: coreutils' strftime and mkstemp replacements
   would otherwise collide with ntlibc's.  */
#define my_strftime nstrftime
#define mkstemp rpl_mkstemp

/* NT has no device numbers to take apart; the types only have to be wide
   enough to print.  */
#define major_t unsigned
#define minor_t unsigned
