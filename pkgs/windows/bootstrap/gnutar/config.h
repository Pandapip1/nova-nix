/* What ./configure would have discovered about ntlibc, written out.
 *
 * The Linux build of this same tar runs tar's own ./configure -- it was the
 * first package there to do so, and bash was built to make it possible.
 * This side does not: see the head of default.nix for why.  So the answers
 * are asserted here instead, in the shape live-bootstrap and the other
 * packages on this side use.
 *
 * A header rather than a wall of -D, for the same reason sed has one: make
 * and kaem on this side run a command line without a shell, so a -D whose
 * value contains quotes or spaces -- -DPACKAGE=\"tar\" among them -- cannot
 * be written on one.  HAVE_CONFIG_H is the single -D left, because
 * src/system.h and the lib/*.c files include <config.h> only when told to.
 *
 * Most of this file is the "define what the library actually has" half of
 * porting to a real C library.  The conspicuous absences at the bottom are
 * the other half, and matter more.
 */

#ifndef TAR_CONFIG_H
#define TAR_CONFIG_H

#define PACKAGE "tar"
#define VERSION "1.12"

/* ENABLE_NLS is 0 rather than undefined: system.h tests its value.  There is
   no gettext here and intl/ is not compiled, so _(Text) is Text.  */
#define ENABLE_NLS 0

/* tcc is an ANSI compiler with the ANSI headers, so system.h takes the
   <string.h>/<stdlib.h> branches and PARAMS(Args) keeps the prototypes.  */
#define STDC_HEADERS 1
#define PROTOTYPES 1

/* src/arith.c represents the huge numbers tar has to hold -- a 12-octal-digit
   size field is 36 bits -- with `long long' when there is one, and with an
   array of longs when there is not.  tcc has a 64-bit long long on i386. */
#define SIZEOF_LONG_LONG 8

/* Headers ntlibc has.  <sys/param.h> is real here, which matters because
   system.h includes it unguarded when _POSIX_SOURCE is not defined, and
   lib/pathmax.h takes MAXPATHLEN from it.  <utime.h> is what create.c and
   extract.c reach for to carry an mtime across, and its struct utimbuf is
   there.  */
#define HAVE_DIRENT_H 1
#define HAVE_FCNTL_H 1
#define HAVE_LIMITS_H 1
#define HAVE_LOCALE_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_WAIT_H 1
#define HAVE_UNISTD_H 1
#define HAVE_UTIME_H 1
#define TIME_WITH_SYS_TIME 1

/* alloca is a real cdecl function in ntlibc, declared in its <alloca.h>, not
   a compiler builtin -- tcc has none -- so both answers are honest and
   lib/alloca.c is not compiled.  */
#define HAVE_ALLOCA 1
#define HAVE_ALLOCA_H 1

/* struct stat here carries st_blksize and st_blocks, so ST_BLKSIZE and
   ST_NBLOCKS in system.h read the file's own answers rather than guessing
   DEV_BSIZE and dividing st_size by 512.  */
#define HAVE_ST_BLKSIZE 1
#define HAVE_ST_BLOCKS 1

/* Functions ntlibc has.  Each of these turns off a fallback that would be
   wrong here, rather than turning on a feature:
     HAVE_STRERROR   without it lib/error.c writes its own strerror out of
                     sys_errlist and sys_nerr, which are BSD-era globals
                     POSIX replaced and ntlibc has no reason to carry.
     HAVE_STRSTR     without it system.h declares `char *strstr()' itself,
                     contradicting the real declaration in <string.h>.
     HAVE_MKFIFO     without it system.h defines mkfifo in terms of mknod.
     HAVE_VALLOC     without it valloc becomes malloc.  buffer.c allocates
                     the record buffer with it and compare.c the diff
                     buffer; page alignment is what those want.
     HAVE_VPRINTF    without it lib/error.c and lib/xmalloc.c reach for
                     _doprnt, which is a System V internal.
     HAVE_ISASCII    lib/backupfile.c and lib/getdate.c test it directly.
     HAVE_LCHOWN     extract.c uses it where it must not follow a link.
     HAVE_FSYNC      compare.c flushes with it before reading back.
     HAVE_GETCWD     without it lib/xgetcwd.c calls getwd, which is the V7
                     spelling with no buffer length and which ntlibc, quite
                     rightly, does not have.  It is a link error, not a
                     compile error, and it is the only one this port hit. */
#define HAVE_FSYNC 1
#define HAVE_GETCWD 1
#define HAVE_ISASCII 1
#define HAVE_LCHOWN 1
#define HAVE_MKFIFO 1
#define HAVE_SETLOCALE 1
#define HAVE_STRERROR 1
#define HAVE_STRSTR 1
#define HAVE_VALLOC 1
#define HAVE_VPRINTF 1

/* names.c prints an owner and a group in `tar -tv' if it can look them up.
   ntlibc has getpwuid and getgrgid and they answer, so the columns carry
   names.  What they are names OF is a fiction NT cannot help: the archive's
   numeric uid and gid are the ones the caller's environment reported, and NT
   has security identifiers rather than integer ids.  Extraction restores
   neither -- see the note on chown at the foot of build.kaem.  */
#define HAVE_GETGRGID 1
#define HAVE_GETPWUID 1

/* rtapelib.c is compiled -- buffer.c calls into it for any archive name that
   looks like host:file -- so its two answers have to exist.  REMOTE_SHELL is
   deliberately absent: with no rsh to name, rtapelib refuses a remote
   archive rather than pretending, which is the right answer on a system with
   no remote shell at all.  MTIO_CHECK_FIELD is only reached under
   HAVE_SYS_MTIO_H, which there is no such header for.  */
#define RETSIGTYPE void
#define MTIO_CHECK_FIELD mt_type

/* tar with no -f and no TAPE in the environment writes to standard output
   rather than to a tape device that does not exist here.  */
#define DEFAULT_ARCHIVE "-"
#define DEFAULT_BLOCKING 20

/* Four things ntlibc genuinely has that are still NOT claimed, because
 * claiming them makes tar do the wrong thing:
 *
 *   HAVE_FNMATCH    ntlibc's fnmatch is POSIX and no more: its <fnmatch.h>
 *                   has FNM_PATHNAME, FNM_NOESCAPE and FNM_PERIOD and stops.
 *                   tar needs FNM_LEADING_DIR, the GNU flag that makes a
 *                   pattern match everything under a directory it names --
 *                   it is how `tar -xf a.tar dir' finds dir/sub/file and how
 *                   --exclude excludes a subtree.  So lib/fnmatch.c and
 *                   lib/fnmatch.h are compiled and included instead, which
 *                   is why -I lib comes before ntlibc's include directory on
 *                   the command line.  ntlibc's fnmatch.o is then never
 *                   pulled out of libc.a and there is no collision.
 *
 *   HAVE_MEMORY_H   there is no <memory.h> to include.
 *
 *   HAVE_STPCPY,    and every other AC_REPLACE_FUNCS answer -- basename,
 *   HAVE_MEMSET,    dirname, execlp, ftruncate, memset, mkdir, rename,
 *   ...             rmdir, stpcpy, strstr.  ntlibc has all of them, and the
 *                   only thing configure does with the answers is decide
 *                   whether to add lib/<name>.c to the library.  That
 *                   decision is made in build.kaem by not naming those files
 *                   at all, so the defines would say nothing to anybody.
 *
 * And two the Linux build would have had that are absent because the
 * function is absent: HAVE_MMAP (ntlibc has no mmap; only lib/gmalloc.c
 * wanted it, and gmalloc is not compiled) and HAVE_GETPAGESIZE (used only by
 * lib/getpagesize.h, which only gmalloc.c includes).
 */

#endif
