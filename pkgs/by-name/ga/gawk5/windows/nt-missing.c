/* The one function gawk 5.3.2 references that ntlibc does not have.
 *
 * Everything else gawk asks for is either in libc.a or is a gawk replacement
 * from missing_d/ that config.h keeps out of the build.  nl_langinfo is
 * neither: it is called from a file that must be compiled, from code that
 * is not behind a HAVE_ #ifdef, so there is nothing to withhold and no
 * replacement to enable.  It was found by `nm', and by tcc's
 * implicit-declaration warnings, before the link was attempted.
 *
 * This file used to carry two more, putwc and wcscoll, on the strength of
 * `nm' over ntlibc's globals at the time finding neither.  That reading was
 * correct when it was made and is no longer: the ntlibc pin bump to
 * ac08c2f0 (see ../ntlibc/bootstrap-sources.nix) brought wide stdio with it
 * -- src/stdio/wide.c compiles to a wide.o defining fgetwc, fputwc, getwc,
 * getwchar, putwc, putwchar, ungetwc, fgetws, fputws and fwide, and a
 * separate wcscoll.o defines wcscoll.  Both of this file's own definitions
 * therefore became duplicates rather than additions, and the link stopped
 * with `libc.a: error: link symbol 'putwc' defined twice'.  Measured
 * directly against both archives, not inferred from the error text: the
 * 2026-08-24 libc.a's armap has no putwc, no wcscoll and no fwide entry at
 * all, the 2026-08-25 one has putwc and fwide in wide.o and wcscoll in
 * wcscoll.o, and nl_langinfo is absent from both.  So the two that ntlibc
 * grew are deleted here and the one it still lacks stays.
 *
 * The eleven names that DO overlap ntlibc deliberately are gawk's own
 * getopt and regex -- see build.kaem.
 *
 * This file is compiled with the rest and lands in the source root, which
 * -I. already covers.
 */

#include <wchar.h>
#include <stdio.h>
#include <limits.h>
#include <langinfo.h>

/* nl_langinfo --- support/regcomp.c calls this, unconditionally, once per
 * compiled regexp, to find out whether the locale is UTF-8.  ntlibc's
 * setlocale has one locale, "C", so the answer is a constant and this is the
 * whole truth rather than a stub: MB_CUR_MAX is 1 here, the name is the
 * portable spelling of US-ASCII that glibc also returns for the C locale,
 * and regcomp's is_utf8 test on it correctly comes out false.
 *
 * This is the same answer pc/gawkmisc.pc gives on MS-Windows when
 * GetACP() reports a non-UTF-8 code page.
 */
char *nl_langinfo(int item)
{
	static char codeset[] = "ANSI_X3.4-1968";

	if (item == CODESET)
		return codeset;

	/* Every other item is a strftime name -- day and month names, the
	   date and time formats, AM/PM.  gawk asks for none of them; the
	   empty string is the shape callers expect for "no answer". */
	return codeset + sizeof(codeset) - 1;
}
