/* What findutils 4.10.0's ./configure would have discovered on this target,
   asserted rather than measured.  See build.kaem and the head of default.nix.

   This is the first package on the Windows side to carry a modern gnulib
   import, and the shape of that import is what this file has to answer for.
   gnulib has two halves: a set of .c files, and a set of REPLACEMENT HEADERS
   that configure generates from gl/lib/*.in.h by substituting a hundred-odd
   @GNULIB_FOO@ values into each.  Nothing here generates those.  Instead the
   sources are compiled against ntlibc's own <stdio.h>, <unistd.h>,
   <string.h>, <dirent.h> and the rest, and the small number of declarations
   gnulib's replacements would have added on top are supplied by the shim
   headers in shim/ (see build.kaem).  That is only possible because ntlibc
   is close enough to POSIX that no gnulib module findutils uses needs a
   renamed rpl_* entry point.  Where a module IS needed because ntlibc lacks
   the function, its .c file is compiled as a plain object and wins the link
   outright; see the nm note in build.kaem.

   Every #define below is read by something this build compiles, and that is
   checked rather than intended: each name was grepped for across the hundred
   sources on build.kaem's list and every header in find/, lib/ and gl/lib/,
   and the eighteen that nothing read were removed.  Both binaries came out
   byte-for-byte identical afterwards, which is the proof that they were
   dead.  config.h.in has 845 knobs in it; this file answers 188 and says
   nothing about the rest, because an answer no one reads is a guess with
   nothing to check it.

   The commented-out #undef lines are not dead in that sense: several are
   the load-bearing half of a decision (HAVE_ERROR, HAVE_NL_LANGINFO, the
   MOUNTED_* family) and the rest are there to record that the question was
   asked.  They cost nothing and they are how this file stays readable
   against config.h.in. */

#ifndef FINDUTILS_CONFIG_H
#define FINDUTILS_CONFIG_H

/* gnulib's own guard.  support/ and gl/lib/ files check it and #error
   without it. */
#define _GL_CONFIG_H_INCLUDED 1

/* Who we are.  version-etc.c, findutils-version.c and every --help string
   read these. */
#define PACKAGE "findutils"
#define PACKAGE_NAME "GNU findutils"
#define PACKAGE_TARNAME "findutils"
#define VERSION "4.10.0"
#define PACKAGE_BUGREPORT "bug-findutils@gnu.org"
#define PACKAGE_BUGREPORT_URL "https://savannah.gnu.org/bugs/?group=findutils"
#define PACKAGE_URL "https://www.gnu.org/software/findutils/"

/* No gettext anywhere in this chain, so gl/lib/gettext.h's `#include
   <libintl.h>' must not be taken -- it is guarded by ENABLE_NLS, which is
   therefore left undefined, and gettext(x) becomes x.  This is not a
   workaround being deleted: the Linux build reaches the same state through
   configure finding no libintl. */
/* #undef ENABLE_NLS */

/* This tcc is C99 with C11 spelling in places, but it has no static_assert
   and no _Static_assert.  gnulib reaches for the one-argument C23 form in
   i-ring.h, malloca.c, mbrtoc32.c and half a dozen other files; on a system
   without it, gnulib's generated <assert.h> supplies the fallback, and that
   is one of the headers this build does not generate.  Every use is a
   compile-time sanity check on a constant that is true here, so making it
   nothing loses nothing this build could have acted on.  Verified by
   checking each one by hand -- they assert 1 <= I_RING_SIZE, that char32_t
   is 32 bits wide, and similar. */
#define static_assert(...) extern int _gl_static_assert_ignored

/* gnulib's own boilerplate -- _GL_GNUC_PREREQ, _Noreturn, _GL_CMP,
   gl_va_copy and the entire _GL_ATTRIBUTE_* vocabulary -- which its m4
   writes into every config.h it generates.  It is not answers, so it is not
   in this file; see shim/gl-common.h.  It comes first because everything
   below and every gnulib header uses it. */
#include "gl-common.h"

/* Two pieces of the same vocabulary that gnulib puts in its GENERATED
   headers rather than in config.h, and that this build therefore has to
   supply here: _GL_ARG_NONNULL (spliced in from arg-nonnull.h, and used
   directly by gl/lib/stdio-safer.h, dirent-safer.h and fcntl--.h) and
   _GL_ATTRIBUTE_FORMAT_PRINTF_STANDARD (from stdio.in.h, used by
   gl/lib/error.c).  Both are hints to GCC and this tcc reads neither. */
#define _GL_ARG_NONNULL(params)
#define _GL_ATTRIBUTE_FORMAT_PRINTF_STANDARD(fmt, first)

/* gnulib's inline vocabulary.  configure writes this block into config.h
   from a template that picks between C99 `extern inline', GCC's pre-C99
   `extern inline' and a plain `static' fallback.  The fallback is taken
   here deliberately rather than the C99 branch that __STDC_VERSION__ would
   select: this tcc accepts `inline' but its handling of C99 extern-inline
   linkage is not something this bootstrap should be resting on, and the
   only cost of `static' is a duplicated copy of a dozen four-line functions
   per object.  _GL_EXTERN_INLINE_IN_USE is left undefined, which is what
   gnulib's headers expect of this branch. */
#define _GL_INLINE static _GL_ATTRIBUTE_MAYBE_UNUSED
#define _GL_EXTERN_INLINE static _GL_ATTRIBUTE_MAYBE_UNUSED
#define _GL_INLINE_HEADER_BEGIN
#define _GL_INLINE_HEADER_END

/* No GCC, so no __builtin_expect.  gnulib's regex and fts use it on every
   other line through their own macros. */
#ifndef HAVE___BUILTIN_EXPECT
# define __builtin_expect(e, c) (e)
#endif

/* find/defs.h refuses to compile unless it can see that <config.h> came
   first, and this is the flag it looks for. */
#define ALREADY_INCLUDED_CONFIG_H 1

/* gnulib's headers use C23's `bool' as a keyword, without including
   <stdbool.h> anywhere.  On a C23 compiler that is right; this tcc is C99,
   where `bool' is a macro that only exists once <stdbool.h> has been read.
   config.h is the one header every file includes first, so it is read
   here.  Without this the failure is `bool undeclared' in thirty gnulib
   files at once, which reads like a broken libc and is not. */
#include <stdbool.h>

/* The same story for C23's `alignof'.  gl/lib/mbsstr.c uses it bare;
   ntlibc's <stdalign.h> maps it onto _Alignof, which this tcc does
   implement.  Without this the failure is a LINK error -- `unresolved
   reference to alignof' -- because the compiler took it for a function
   call, which is a long way from the cause. */
#include <stdalign.h>

/* Declarations and types.  ntlibc is a musl-shaped C library for NT, so the
   POSIX answers are nearly all yes; what follows is the honest list, and the
   entries answered NO are the interesting ones. */
#define STDC_HEADERS 1
#define HAVE_UNISTD_H 1
#define HAVE_DIRENT_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDINT_H 1
#define HAVE_STRINGS_H 1
#define HAVE_WCHAR_H 1
#define HAVE_WCTYPE_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_UIO_H 1
#define HAVE_SYS_UTSNAME_H 1
#define HAVE_ALLOCA_H 1
#define HAVE_ALLOCA 1
#define HAVE_GETOPT_H 1
#define HAVE_FNMATCH_H 1
#define HAVE_LIBGEN_H 1
#define HAVE_FEATURES_H 1

/* And the headers ntlibc does not have.  Each of these is left undefined
   rather than shimmed, because in every case the code has a portable branch
   behind it:
     <langinfo.h>    localcharset falls back to parsing setlocale(LC_ALL,NULL)
     <libintl.h>     see ENABLE_NLS above
     <stdio_ext.h>   see HAVE_DECL___FPENDING below
     <mntent.h>, <sys/mount.h>, <sys/vfs.h>, <sys/statvfs.h>
                     NT has no mount table at all; see MOUNTED_* below
     <selinux/selinux.h>
                     stubbed in shim/selinux/, as gnulib's own selinux-h
                     module would have generated it
     <uchar.h>       shimmed in shim/uchar.h; gnulib's mbrtoc32 and the
                     c32* modules are compiled to stand behind it
     <error.h>       shimmed in shim/error.h; gnulib's error.c is compiled */
/* #undef HAVE_LANGINFO_H */
/* #undef HAVE_LANGINFO_CODESET */
/* #undef HAVE_LIBINTL_H */
/* #undef HAVE_STDIO_EXT_H */
/* #undef HAVE_MNTENT_H */
/* #undef HAVE_SYS_MOUNT_H */
/* #undef HAVE_SYS_VFS_H */
/* #undef HAVE_SYS_SOCKET_H */
/* #undef HAVE_SELINUX_SELINUX_H */
/* #undef HAVE_UCHAR_H */
/* #undef HAVE_ERROR_H */
/* #undef HAVE_OS_H */
/* #undef HAVE_CRTDEFS_H */
/* #undef HAVE_XLOCALE_H */
/* #undef HAVE_SDKDDKVER_H */
/* #undef HAVE_WINSOCK2_H */
/* #undef HAVE_WS2TCPIP_H */
/* #undef HAVE_THREADS_H */
/* #undef HAVE_SYS_SYSMACROS_H */
/* #undef HAVE_RANDOM_H */
/* #undef HAVE_BP_SYM_H */
/* #undef HAVE_SYS_BITYPES_H */
/* #undef HAVE_SYS_INTTYPES_H */
/* #undef HAVE_SYS_MKDEV_H */
/* #undef HAVE_SYS_MNTENT_H */
/* #undef HAVE_SYS_MNTIO_H */
/* #undef HAVE_SYS_MNTTAB_H */
/* #undef HAVE_SYS_FS_TYPES_H */
/* #undef HAVE_SYS_UCRED_H */
/* #undef HAVE_UNISTRING_WOE32DLL_H */
/* #undef HAVE_CFPREFERENCESCOPYAPPVALUE */

/* Functions ntlibc has.  Checked against `nm' on the built libc.a rather
   than assumed. */
#define HAVE_ATOLL 1
#define HAVE_BTOWC 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_CLOSEDIR 1
#define HAVE_OPENDIR 1
#define HAVE_READDIR 1
#define HAVE_REWINDDIR 1
#define HAVE_DECL_DIRFD 1
#define HAVE_ENDGRENT 1
#define HAVE_ENDPWENT 1
#define HAVE_FACCESSAT 1
#define HAVE_FCHDIR 1
#define HAVE_DECL_FCHDIR 1
#define HAVE_FCNTL 1
#define HAVE_FDOPENDIR 1
#define HAVE_DECL_FDOPENDIR 1
#define HAVE_FSTATAT 1
#define HAVE_FTRUNCATE 1
#define HAVE_GETDTABLESIZE 1
#define HAVE_GETGROUPS 1
#define HAVE_GETHOSTNAME 1
#define HAVE_GETPAGESIZE 1
#define HAVE_GETRLIMIT 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_ISBLANK 1
#define HAVE_DECL_ISBLANK 1
#define HAVE_ISWBLANK 1
#define HAVE_ISWCNTRL 1
#define HAVE_LSTAT 1
#define HAVE_MBRTOWC 1
#define HAVE_MBSINIT 1
#define HAVE_MBSRTOWCS 1
#define HAVE_MBTOWC 1
#define HAVE_MEMPCPY 1
#define HAVE_OPENAT 1
#define HAVE_PIPE 1
#define HAVE_RAWMEMCHR 1
#define HAVE_READLINK 1
#define HAVE_READLINKAT 1
#define HAVE_REALPATH 1
#define HAVE_DECL_SETENV 1
#define HAVE_DECL_UNSETENV 1
#define HAVE_SETLOCALE 1
#define HAVE_SLEEP 1
#define HAVE_DECL_SNPRINTF 1
#define HAVE_STPCPY 1
#define HAVE_STRCASECMP 1
#define HAVE_DECL_STRNCASECMP 1
#define HAVE_STRCASESTR 1
#define HAVE_DECL_STRDUP 1
#define HAVE_DECL_STRNDUP 1
#define HAVE_DECL_STRNLEN 1
#define HAVE_STRTOL 1
#define HAVE_STRTOLL 1
#define HAVE_STRTOUL 1
#define HAVE_STRTOULL 1
#define HAVE_DECL_STRTOUMAX 1
#define HAVE_SYMLINK 1
#define HAVE_SYMLINKAT 1
#define HAVE_TIMEGM 1
#define HAVE_UNAME 1
#define HAVE_UNLINKAT 1
#define HAVE_USLEEP 1
#define HAVE_WCRTOMB 1
#define HAVE_WCSLEN 1
#define HAVE_DECL_GETLINE 1
#define HAVE_DECL_GETDELIM 1
#define HAVE_DECL_FSEEKO 1
#define HAVE_DECL_FTELLO 1
#define HAVE_DECL_LOCALTIME_R 1
#define HAVE_DECL_MEMRCHR 1
#define HAVE_DECL_INITSTATE 1
#define HAVE_DECL_SETSTATE 1
#define HAVE_INITSTATE 1
#define HAVE_SETSTATE 1
#define HAVE_STRERROR_R 1
#define HAVE_DECL_STRERROR_R 1
#define HAVE_TIMESPEC_GET 1
#define MALLOC_0_IS_NONNULL 1

/* Functions ntlibc does NOT have, and what stands in for each.  This is the
   real content of the port: every one of these turns on a gnulib .c file
   that build.kaem then names.
     error, error_at_line   gl/lib/error.c + shim/error.h
     euidaccess             gl/lib/euidaccess.c   (-readable/-writable/
                            -executable, and see the note in default.nix
                            about what those can mean on NT)
     rpmatch                gl/lib/rpmatch.c      (xargs -p)
     mbrtoc32, c32*         gl/lib/mbrtoc32.c and the c32*.c files
     wcwidth                gl/lib/wcwidth.c + uniwidth/width.c
     nl_langinfo            not replaced: see HAVE_LANGINFO_CODESET
     canonicalize_file_name gl/lib/canonicalize-lgpl.c is NOT compiled;
                            ntlibc has realpath, which is what find needs
     getprogname            gl/lib/progname.c defines program_name itself
     re_compile_pattern &c  ntlibc's <regex.h> is musl's, POSIX only.  find
                            needs the GNU interface, so gl/lib/regex.c is
                            compiled; see the duplicate-symbol note in
                            build.kaem. */
/* #undef HAVE_ERROR */
/* #undef HAVE_EUIDACCESS */
/* #undef HAVE_EACCESS */
/* #undef HAVE_RPMATCH */
/* #undef HAVE_WCWIDTH */
/* #undef HAVE_DECL_WCWIDTH */
/* #undef HAVE_WORKING_MBRTOC32 */
/* #undef HAVE_NL_LANGINFO */
/* #undef HAVE_CANONICALIZE_FILE_NAME */
/* #undef HAVE_GETPROGNAME */
/* #undef HAVE_GETEXECNAME */
/* #undef HAVE_VAR___PROGNAME */
/* #undef HAVE_DECL_PROGRAM_INVOCATION_NAME */
/* #undef HAVE_DECL_PROGRAM_INVOCATION_SHORT_NAME */
/* #undef HAVE_SECURE_GETENV */
/* #undef HAVE_QSORT_R */
/* #undef HAVE_RANDOM_R */
/* #undef HAVE_STRUCT_RANDOM_DATA */
/* #undef HAVE_REALLOCARRAY */
/* #undef HAVE_DECL_EXECVPE */
/* #undef HAVE_MBSLEN */
/* #undef HAVE_WMEMPCPY */
/* #undef HAVE_DECL_WCSDUP */
/* #undef HAVE_DECL_WCTOB */
/* #undef HAVE_CATGETS */
/* #undef HAVE_NEWLOCALE */
/* #undef HAVE_DUPLOCALE */
/* #undef HAVE_FREELOCALE */
/* #undef HAVE_GOOD_USELOCALE */
/* #undef HAVE_GETLOCALENAME_L */
/* #undef HAVE_NAMELESS_LOCALES */
/* #undef HAVE_LC_MESSAGES */
/* #undef HAVE_DECL_TZNAME */
/* #undef HAVE_TZNAME */
/* #undef HAVE_SETMNTENT */
/* #undef HAVE_ENDMNTENT */
/* #undef HAVE_HASMNTOPT */
/* #undef HAVE_FSTATFS */
/* #undef HAVE_GETMNTENT */

/* The unlocked stdio aliases.  ntlibc has none of them, and gnulib's
   unlocked-io module is not in this import, so every HAVE_DECL_*_UNLOCKED is
   0 and the code uses the locked form.  Single-threaded, so nothing is
   lost. */
#define HAVE_DECL_CLEARERR_UNLOCKED 0
#define HAVE_DECL_FEOF_UNLOCKED 0
#define HAVE_DECL_FERROR_UNLOCKED 0
#define HAVE_DECL_FFLUSH_UNLOCKED 0
#define HAVE_DECL_FGETS_UNLOCKED 0
#define HAVE_DECL_FPUTC_UNLOCKED 0
#define HAVE_DECL_FPUTS_UNLOCKED 0
#define HAVE_DECL_FREAD_UNLOCKED 0
#define HAVE_DECL_FWRITE_UNLOCKED 0
#define HAVE_DECL_GETCHAR_UNLOCKED 0
#define HAVE_DECL_GETC_UNLOCKED 0
#define HAVE_DECL_PUTCHAR_UNLOCKED 0
#define HAVE_DECL_PUTC_UNLOCKED 0
/* #undef HAVE_FLOCKFILE */
/* #undef HAVE_FUNLOCKFILE */

/* The stdio internals gnulib reaches into on a libc it recognises.  ntlibc's
   FILE is its own struct -- not glibc's, not musl's, not BSD's -- so
   gl/lib/stdio-impl.h has no branch for it and __fpending, __freading,
   __freadahead and __fpurge are all unreachable.  What that costs, and what
   is done about it, is in shim/nt-missing.c: only close_stream reads
   __fpending, and only to decide whether an fclose failure that reported
   EBADF should be treated as data loss. */
#define HAVE_DECL___FPENDING 0
/* #undef HAVE___FPURGE */
/* #undef HAVE_DECL_FPURGE */
/* #undef HAVE___FREADING */
/* #undef HAVE___FREADAHEAD */
/* #undef HAVE_DECL_FCLOSEALL */
/* #undef HAVE_DECL_GETW */
/* #undef HAVE_DECL_PUTW */
/* #undef HAVE_DECL_ECVT */
/* #undef HAVE_DECL_FCVT */
/* #undef HAVE_DECL_GCVT */
/* #undef HAVE_DECL_STRMODE */
/* #undef HAVE_DECL___ARGV */
/* #undef HAVE_DECL__SNPRINTF */
/* #undef HAVE_DECL__FSEEKI64 */
/* #undef HAVE__FSEEKI64 */
/* #undef HAVE__FTELLI64 */
/* #undef HAVE_MSVC_INVALID_PARAMETER_HANDLER */

/* Types and layout.  32-bit x86, little-endian, and this tcc's idea of the
   basic types is the ordinary ILP32 one. */
/* #undef WORDS_BIGENDIAN */
#define HAVE_WCHAR_T 1
#define HAVE_WINT_T 1
#define BITSIZEOF_WCHAR_T 32
#define BITSIZEOF_WINT_T 32
#define BITSIZEOF_SIG_ATOMIC_T 32
#define BITSIZEOF_SIZE_T 32
#define BITSIZEOF_PTRDIFF_T 32
#define HAVE_SIGNED_WCHAR_T 1
#define HAVE_SIGNED_WINT_T 1
#define HAVE_SIGNED_SIG_ATOMIC_T 1
#define SIG_ATOMIC_T_SUFFIX
#define WCHAR_T_SUFFIX
#define WINT_T_SUFFIX
#define SIZE_T_SUFFIX u
#define PTRDIFF_T_SUFFIX
#define TIME_T_IS_SIGNED 1
#define PROMOTED_MODE_T mode_t
#define HAVE_COMPOUND_LITERALS 1
#define FLEXIBLE_ARRAY_MEMBER /**/
#define HAVE_STRUCT_UTSNAME 1
#define HAVE_STRUCT_DIRENT_D_TYPE 1
#define D_INO_IN_DIRENT 1
#define HAVE_STRUCT_STAT_ST_BLOCKS 1
#define HAVE_STRUCT_STAT_ST_RDEV 1
#define HAVE_STRUCT_STAT_ST_ATIM_TV_NSEC 1
#define TYPEOF_STRUCT_STAT_ST_ATIM_IS_STRUCT_TIMESPEC 1
/* #undef HAVE_STRUCT_STAT_ST_ATIMESPEC_TV_NSEC */
/* #undef HAVE_STRUCT_STAT_ST_ATIMENSEC */
/* #undef HAVE_STRUCT_STAT_ST_ATIM_ST__TIM_TV_NSEC */
/* #undef HAVE_STRUCT_STAT_ST_BIRTHTIMESPEC_TV_NSEC */
/* #undef HAVE_STRUCT_STAT_ST_BIRTHTIMENSEC */
/* #undef HAVE_STRUCT_STAT_ST_BIRTHTIM_TV_NSEC */
/* #undef HAVE_STRUCT_TM_TM_ZONE */
/* #undef HAVE_TM_GMTOFF */
/* #undef HAVE_TIMEZONE_T */
/* #undef HAVE_STRUCT_STATFS_F_TYPE */
/* #undef HAVE_STRUCT_STATFS_F_FSTYPENAME */
/* #undef HAVE_STRUCT_FSSTAT_F_FSTYPENAME */
/* #undef HAVE___FSWORD_T */
/* #undef HAVE_SA_FAMILY_T */
/* #undef HAVE_STRUCT_SOCKADDR_STORAGE */
/* #undef HAVE_STRUCT_LCONV_DECIMAL_POINT */
/* #undef MAJOR_IN_MKDEV */
/* #undef MAJOR_IN_SYSMACROS */
/* #undef STAT_MACROS_BROKEN */

/* gnulib's bug switches: the corner cases in which some libc somewhere gets
   a POSIX call wrong, each of which turns on a workaround.  None is declared
   here, and that is the DEFAULT rather than a measurement -- these were not
   tested one at a time against ntlibc, and saying so is more useful than
   implying otherwise.  Not declaring a bug is the safe direction: it leaves
   the plain call in place, so a bug that is really there shows up as wrong
   behaviour that can be found, rather than as a workaround silently papering
   over something else.  The one knob in this group that IS answered is
   HAVE_WORKING_O_NOFOLLOW below, because fts.c reads it in a C expression
   and it cannot be left undefined. */
/* #undef ACCESS_TRAILING_SLASH_BUG */
/* #undef OPEN_TRAILING_SLASH_BUG */
/* #undef FOPEN_TRAILING_SLASH_BUG */
/* #undef READLINK_TRAILING_SLASH_BUG */
/* #undef READLINK_TRUNCATE_BUG */
/* #undef UNLINK_PARENT_BUG */
/* #undef FCNTL_DUPFD_BUGGY */
/* #undef GETGROUPS_ZERO_BUG */
/* #undef LSEEK_PIPE_BROKEN */
/* #undef CLOSEDIR_VOID */
/* #undef VOID_UNSETENV */
/* #undef DOUBLE_SLASH_IS_DISTINCT_ROOT */
/* #undef HAVE_MINIMALLY_WORKING_GETCWD */
/* #undef HAVE_PARTLY_WORKING_GETCWD */
/* #undef HAVE_WORKING_FSTATAT_ZERO_FLAG */

/* O_NOFOLLOW.  ntlibc DEFINES it and open() honours it -- by passing
   FILE_OPEN_REPARSE_POINT, which opens the link itself rather than failing.
   That is the NT answer, and it is not the POSIX one: POSIX requires
   open(O_NOFOLLOW) on a symbolic link to fail with ELOOP, and gl/lib/fts.c
   reads this knob to decide whether diropen's O_NOFOLLOW alone is enough to
   prove it did not cross a link.  Answering yes here would let fts skip the
   fstat that proves it.  Note the spelling: fts.c uses this one in an
   ordinary C expression, not in #if, so it must be 0 or 1 and cannot be
   left undefined. */
#define HAVE_WORKING_O_NOFOLLOW 0
/* #undef FTELLO_BROKEN_AFTER_SWITCHING_FROM_READ_TO_WRITE */
/* #undef FTELLO_BROKEN_AFTER_UNGETC */
/* #undef FUNC_REALPATH_WORKS */

/* Multibyte.  The C locale is the only locale this chain has, so mbrtowc
   never returns a multibyte sequence and the c32 layer is exact.  The two
   "MAYBE_EILSEQ" answers are gnulib asking whether the libc rejects bytes
   0x80..0xff in the C locale; ntlibc does not -- it passes them through as
   themselves, which is what gnulib wants -- so neither bug is declared. */
/* #undef MBRTOWC_NULL_ARG2_BUG */
/* #undef MBRTOWC_RETVAL_BUG */
/* #undef MBRTOWC_NUL_RETVAL_BUG */
/* #undef MBRTOWC_EMPTY_INPUT_BUG */
/* #undef MBRTOWC_STORES_INCOMPLETE_BUG */
/* #undef MBRTOWC_IN_C_LOCALE_MAYBE_EILSEQ */
/* #undef MBRTOC32_EMPTY_INPUT_BUG */
/* #undef MBRTOC32_IN_C_LOCALE_MAYBE_EILSEQ */
/* #undef MBRTOC32_MULTIBYTE_LOCALE_BUG */
/* #undef WCRTOMB_C_LOCALE_BUG */
/* #undef WCRTOMB_RETVAL_BUG */
#define HAVE_DECL_MBSWIDTH_IN_WCHAR_H 0

/* No mount table.  NT has no /etc/mtab, no getmntent, no statfs and no
   statvfs, and ntlibc offers none of them, so gnulib's mountlist compiles
   with no MOUNTED_* strategy selected: read_file_system_list() returns NULL
   and sets ENOSYS.  What that means for find is `-fstype' -- see the
   default.nix note.  Declaring one of these instead would be the mes-libc
   mistake in reverse: an answer that is false here. */
/* #undef MOUNTED_GETMNTENT1 */
/* #undef MOUNTED_GETMNTENT2 */
/* #undef MOUNTED_GETMNTINFO */
/* #undef MOUNTED_GETMNTINFO2 */
/* #undef MOUNTED_GETFSSTAT */
/* #undef MOUNTED_FS_STAT_DEV */
/* #undef MOUNTED_FREAD_FSTYP */
/* #undef MOUNTED_GETEXTMNTENT */
/* #undef MOUNTED_INTERIX_STATVFS */
/* #undef MOUNTED_VMOUNT */

/* Threads: none.  ntlibc has no pthreads, and nothing in this build is
   threaded, so gnulib's locking degenerates to nothing and the two
   setlocale_null entry points are trivially safe. */
/* #undef HAVE_PTHREAD_API */
/* #undef USE_WINDOWS_THREADS */
/* #undef HAVE_WEAK_SYMBOLS */
#define AVOID_ANY_THREADS 1
#define GNULIB_LOCK 1
#define SETLOCALE_NULL_ALL_MTSAFE 1
#define SETLOCALE_NULL_ONE_MTSAFE 1

/* SELinux: none.  gnulib's selinux-h module generates a stub
   <selinux/selinux.h> when the real one is missing; this build ships that
   stub in shim/selinux/ instead of generating it, and the four macro names
   below are the ones find/pred.c and gl/lib/selinux-at.c reference. */
/* #undef HAVE_SELINUX_SELINUX_H */
/* #undef getfilecon */
/* #undef lgetfilecon */
/* #undef fgetfilecon */
/* #undef getfilecon_raw */
/* #undef lgetfilecon_raw */
/* #undef fgetfilecon_raw */

/* gnulib module switches.  Each of these turns on a piece of a gnulib
   header that this build does compile the .c file for.  GNULIB_FNMATCH_GNU
   is the load-bearing one: ntlibc's fnmatch is POSIX and stops at
   FNM_PATHNAME/FNM_NOESCAPE/FNM_PERIOD, while find's -iname needs
   FNM_CASEFOLD and -path needs FNM_LEADING_DIR, so gl/lib/fnmatch.c is
   compiled and shim/fnmatch.h declares the GNU flags. */
#define GNULIB_FNMATCH_GNU 1
#define GNULIB_DIRNAME 1
#define GNULIB_FCNTL_SAFER 1
#define GNULIB_FD_SAFER_FLAG 1
#define GNULIB_FOPEN_SAFER 1
#define GNULIB_OPENAT_SAFER 1
#define GNULIB_AREADLINKAT 1
#define GNULIB_FACCESSAT 1
#define GNULIB_FDOPENDIR 1
#define GNULIB_OPENAT 1
#define GNULIB_XALLOC 1
#define GNULIB_XALLOC_DIE 1
#define GNULIB_GETCWD 1
#define GNULIB_STRERROR 1
/* #undef GNULIB_FFLUSH */
/* #undef GNULIB_FOPEN_GNU */
/* #undef GNULIB_MSVC_NOTHROW */
/* #undef GNULIB_REALLOCARRAY */
/* #undef GNULIB_PRINTF_ATTRIBUTE_FLAVOR_GNU */
/* #undef GNULIB_NO_VLA */

/* gnulib's fts is compiled, so its six entry points are renamed the way
   configure renames them when the system has an fts of its own.  ntlibc has
   none, so this is belt and braces -- but it is also what keeps a future
   ntlibc fts from being linked in by accident, which is exactly the silent
   direction of the duplicate-symbol problem. */
#define fts_children rpl_fts_children
#define fts_close rpl_fts_close
#define fts_cross_check rpl_fts_cross_check
#define fts_open rpl_fts_open
#define fts_read rpl_fts_read
#define fts_set rpl_fts_set
#define LEAF_OPTIMISATION 1

/* mktime.  ntlibc has mktime and timegm, so gl/lib/mktime.c is not
   compiled and NEED_MKTIME_* stay off. */
/* #undef NEED_MKTIME_INTERNAL */
/* #undef NEED_MKTIME_WINDOWS */
/* #undef NEED_MKTIME_WORKING */
/* #undef HAVE_LOCALTIME_INFLOOP_BUG */

/* strerror_r.  ntlibc's is the POSIX int-returning one. */
/* #undef STRERROR_R_CHAR_P */
/* #undef HAVE___XPG_STRERROR_R */
/* #undef REPLACE_STRERROR_0 */
#define GNULIB_STRERROR_R_POSIX 1

/* Compiler.  This tcc is not GCC and advertises none of GCC's extensions:
   it predefines __STDC__ and __STDC_VERSION__ and neither __GNUC__ nor
   __builtin_expect. */
/* #undef HAVE___BUILTIN_EXPECT */
/* #undef HAVE_VISIBILITY */
#define HAVE_INLINE 1
#define HAVE___INLINE 1
#define restrict
/* #undef inline */
/* #undef __restrict__ */

/* Feature-test macros.  _GNU_SOURCE is asked for by gnulib as a matter of
   course; ntlibc reads it in <features.h> to expose strdup, strndup,
   mempcpy, rawmemchr, stpcpy, getline, fseeko and euidaccess's neighbours,
   all of which findutils uses. */
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif
/* __STDC_WANT_IEC_60559_BFP_EXT__ is NOT set here although configure sets
   it: gl/lib/libc-config.h sets it itself, and setting it twice is a
   redefinition warning on every regex object. */

/* findutils' own knobs.  DEFAULT_ARG_SIZE is xargs' and find -exec's
   command-line budget; the value is configure's default. */
#define DEFAULT_ARG_SIZE (128*1024)

/* This port's own, and not a knob configure has: the target's PATH is
   ';'-separated and its absolute paths start with a drive letter.  Only
   find/parser.c's check_path_safety reads it, which is what -execdir and
   -okdir go through; see patches/nt-execdir-path-syntax.patch for what it
   costs to get this wrong (the answer is that -execdir does not run at
   all).  It is NOT spelled _WIN32 on purpose: this build compiles with
   -U_WIN32, because to gnulib _WIN32 means "the Microsoft C runtime is
   underneath", which is false here, and path syntax is a different
   question from which C runtime is underneath. */
#define NT_PATH_SYNTAX 1

/* Large files: this tcc has a 64-bit off_t already and ntlibc has no
   separate _LARGEFILE64 interface, so nothing is requested. */
/* #undef _FILE_OFFSET_BITS */
/* #undef _LARGE_FILES */

/* And the declarations gnulib's generated headers would have added on top
   of the system ones.  Included from here, at the end, so that every
   compiled file sees them: config.h is the one header they all include
   first.  See that file for what is in it and why. */
#include "gl-missing-decls.h"

#endif /* FINDUTILS_CONFIG_H */
