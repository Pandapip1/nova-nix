/* src/paths.h, which ./configure would have written from src/paths.h.in by
 * substituting @DEFAULT_DIFF_PROGRAM@ and @localedir@.  The tarball ships no
 * generated copy -- unlike src/version.c's inputs, paths.h.in is processed by
 * config.status alone, with nothing upstream pre-building it into the
 * release -- so it has to be written here instead of merely found.
 *
 * DEFAULT_DIFF_PROGRAM is what sdiff and diff3 execvp when no --diff-program
 * is given (src/sdiff.c, src/diff3.c); "diff" is configure's own default and
 * is found through $PATH exactly the way build.kaem's self-test relies on --
 * see the WINEPATH note there.
 *
 * LOCALEDIR feeds bindtextdomain(), which is a no-op here: ENABLE_NLS is
 * left undefined in config.h because this chain has no gettext, so
 * bindtextdomain expands to nothing and the value is never read.  It is
 * given anyway, as configure's own default would, rather than left to an
 * accidental empty definition.
 */
#define DEFAULT_DIFF_PROGRAM "diff"
#define LOCALEDIR "/share/locale"
