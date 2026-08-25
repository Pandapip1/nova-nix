/* The two functions gnulib needs that neither ntlibc nor gnulib itself can
 * supply on this target.  Both are small, and both are here rather than in a
 * patch because they are additions, not corrections.
 */
#include <config.h>
#include <stddef.h>
#include <stdio.h>
#include <langinfo.h>
#include "progname.h"
#include "fpending.h"
#include "freadahead.h"

/* getprogname().
 *
 * gl/lib/error.c calls it and includes nothing but <error.h>.  gnulib has a
 * getprogname module, but every branch of gl/lib/getprogname.c is keyed to a
 * platform: glibc's program_invocation_short_name, Solaris' getexecname,
 * mingw's __argv, OpenBSD's __progname, AIX, HP-UX, IRIX, Cygwin.  ntlibc is
 * none of those and has no equivalent of its own, so that file does not
 * compile here at all and is not on build.kaem's list.
 *
 * findutils calls gnulib's set_program_name (argv[0]) in every main() --
 * find/ftsfind.c, xargs/xargs.c and locate's -- so gnulib's own program_name
 * is the right answer and is already there.  It is a full path by the time
 * it gets here on some systems, which is why gl/lib/progname.c is patched
 * (see patches/nt-program-name.patch): the NT loader hands over argv[0] as a
 * backslashed store path.
 */
const char *
getprogname (void)
{
  return program_name != NULL ? program_name : "find";
}

/* __fpending().
 *
 * gnulib's close-stream module asks how many bytes are sitting in a FILE's
 * write buffer, and gets the answer by reaching into the libc's private FILE
 * struct: gl/lib/stdio-impl.h has a branch for glibc, one for musl, one for
 * the BSDs, one for Solaris and one for mingw, and #errors otherwise.
 * ntlibc's FILE is its own struct -- src/stdio/stdio_impl.h -- so no branch
 * fits, and there is no public way to ask.
 *
 * Returning 0 is not free, and this is exactly what it costs.  gnulib's
 * close_stream reads:
 *
 *     bool some_pending = (__fpending (fp) != 0);
 *     bool prev_fail    = (ferror (fp) != 0);
 *     bool fclose_fail  = (fclose (fp) != 0);
 *     if (prev_fail || (fclose_fail && (some_pending || errno != EBADF)))
 *       ... report failure ...
 *
 * A write error that has already been recorded is caught by ferror, and a
 * failing fclose is caught by fclose_fail; ntlibc's fclose flushes and
 * reports the flush's error, so neither of those is weakened.  The single
 * case this loses is an fclose that fails with EBADF while the buffer still
 * held data -- data silently lost on a file descriptor that was closed out
 * from under the stream.  find and xargs never close a descriptor behind
 * their own FILE, so there is nothing here that can produce it.
 *
 * This goes away the day ntlibc grows __fpending or a public equivalent; it
 * is a gap in what the library exposes, not in what it does.
 */
size_t
__fpending (FILE *fp)
{
  (void) fp;
  return 0;
}

/* freadahead().
 *
 * The other half of the same problem as __fpending, and it has a better
 * answer.  gnulib's close_stdin asks how many bytes stdin has read ahead of
 * what the program consumed, and if the answer is nonzero it does
 *
 *     if (fseeko (stdin, 0, SEEK_CUR) == 0 && fflush (stdin) != 0) ...
 *
 * to put the file descriptor back where the program actually got to, so
 * that a shell sharing the descriptor reads the rest.  gl/lib/freadahead.c
 * computes it from the FILE's private buffer pointers, which ntlibc's FILE
 * does not expose.
 *
 * Returning a nonzero constant is the RIGHT answer here rather than a
 * conservative one, because ntlibc's fflush already does exactly the
 * resynchronisation gnulib is asking for -- src/stdio/buf.c's
 * __fflush_locked seeks the descriptor back by (rend - rpos) on a readable
 * stream, citing the same POSIX paragraph.  So this makes close_stdin do
 * the fseeko/fflush unconditionally, which is correct whether or not there
 * was anything buffered, and costs one lseek.  On a pipe the fseeko fails
 * and the branch is skipped, which is what gnulib intends.
 *
 * Returning 0 would have been the tempting shape and would have been a
 * silent behaviour change: xargs would leave stdin's descriptor past the
 * data it had not used.
 */
size_t
freadahead (FILE *fp)
{
  (void) fp;
  return 1;
}

/* nl_langinfo().
 *
 * gl/lib/regcomp.c calls this once per compiled regexp, unconditionally, to
 * find out whether the locale is UTF-8 -- and find compiles a regexp for
 * every -regex, -iregex and -name that is not a literal.  ntlibc's setlocale
 * has one locale, "C", so the answer is a constant and this is the whole
 * truth rather than a stub: MB_CUR_MAX is 1 here, the name below is the
 * portable spelling of US-ASCII that glibc also returns for the C locale,
 * and regcomp's is_utf8 test on it correctly comes out false.  The same
 * answer, and the same reasoning, as the gawk 5.3.2 sibling's.
 */
char *
nl_langinfo (int item)
{
  static char codeset[] = "ANSI_X3.4-1968";

  if (item == CODESET)
    return codeset;

  /* Every other item is a strftime name -- day and month names, the date
     and time formats, AM/PM.  Nothing here asks for them; the empty string
     is the shape callers expect for "no answer". */
  return codeset + sizeof (codeset) - 1;
}
