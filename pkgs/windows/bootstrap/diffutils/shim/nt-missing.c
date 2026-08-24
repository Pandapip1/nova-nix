/* The three functions diffutils 3.8 references that neither ntlibc has nor
 * gnulib can supply here.
 *
 * Everything else diffutils asks for is either in libc.a or is a gnulib
 * replacement named on the compile list in build.kaem.  These three are
 * neither: each is called from a file that must be compiled, from code that
 * is not behind a HAVE_ #ifdef, and in each case gnulib's own replacement
 * either does not exist for this target or would drag in a subsystem this
 * chain does not have.
 *
 * None of the three collides with anything: `nm' over ntlibc's 878 globals
 * finds none of these names, so these definitions add symbols rather than
 * shadowing them.
 */

#include <config.h>
#include <wchar.h>
#include <wctype.h>
#include <langinfo.h>
#include "progname.h"

/* nl_langinfo --- lib/regcomp.c calls this, unconditionally, once per
 * compiled regexp, to find out whether the locale is UTF-8.  ntlibc's
 * setlocale has one locale, "C", so the answer is a constant and this is the
 * whole truth rather than a stub: MB_CUR_MAX is 1 here, the name is the
 * portable spelling of US-ASCII that glibc also returns for the C locale,
 * and regcomp's is_utf8 test on it correctly comes out false.
 *
 * This is the same file, for the same reason, as the one beside the gawk
 * 5.3.2 package; see langinfo.h.
 */
char *
nl_langinfo (int item)
{
  static char codeset[] = "ANSI_X3.4-1968";

  if (item == CODESET)
    return codeset;

  /* Every other item is a strftime name -- day and month names, the date
     and time formats, AM/PM.  diffutils asks for none of them; the empty
     string is the shape callers expect for "no answer". */
  return codeset + sizeof (codeset) - 1;
}

/* wcwidth --- src/side.c calls it to lay out the columns of `diff -y'.
 *
 * gnulib ships lib/wcwidth.c and it is NOT compiled here.  Its body is `if
 * the locale is UTF-8, return uc_width (wc, "UTF-8"), else fall back' -- and
 * reaching that first branch drags in localcharset's UTF-8 test, uniwidth/
 * width.c with its Unicode tables and unistr/u8-mbtoucr.c.  None of it can
 * ever run in this chain: ntlibc's setlocale has one locale, "C", so
 * is_locale_utf8() is false by construction and gnulib would take its own
 * else-branch every time.  This IS that else-branch, written out, with
 * #if HAVE_WCWIDTH answered no -- which it is.
 */
int
wcwidth (wchar_t wc)
{
  return wc == 0 ? 0 : iswprint (wc) ? 1 : -1;
}

/* getprogname --- what lib/error.c prefixes every diagnostic with, and what
 * lib/argmatch.c and lib/c-stack.c name the program by.
 *
 * gnulib's lib/getprogname.c is not compiled here, and this is the one place
 * where that is not a choice: it ends in `#error "getprogname module not
 * ported to this OS"' unless the C library has getprogname (BSD),
 * program_invocation_short_name or program_invocation_name (glibc), or
 * __argv (MSVC).  ntlibc has none of the four -- checked with nm -- and
 * there is no fifth branch to enable.
 *
 * This simply forwards program_name, which is the right answer here because
 * of where the trimming happens: patches/nt-program-name.patch shortens
 * program_name itself, in lib/progname.c's set_program_name, to the last
 * path component.  src/diff.c, src/cmp.c, src/diff3.c and src/sdiff.c reach
 * for `program_name' DIRECTLY in eleven places -- "Usage: %s", "Try '%s
 * --help'", "%s: diff failed: " -- as well as through error() and
 * getprogname(), so trimming has to happen at the one place all of those
 * read from, not here.  See that patch for why the NT loader's argv[0]
 * needs it and gnulib's own upstream reasoning does not apply on this
 * target.
 */
char const *
getprogname (void)
{
  return program_name;
}
