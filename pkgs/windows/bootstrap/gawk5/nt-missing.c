/* The three functions gawk 5.3.2 references that ntlibc does not have.
 *
 * Everything else gawk asks for is either in libc.a or is a gawk replacement
 * from missing_d/ that config.h keeps out of the build.  These three are
 * neither: each is called from a file that must be compiled, from code that
 * is not behind a HAVE_ #ifdef, so there is nothing to withhold and no
 * replacement to enable.  They were found by `nm', and by tcc's
 * implicit-declaration warnings, before the link was attempted.
 *
 * None of them collides with anything: `nm' over ntlibc's 874 globals finds
 * none of the three, so these definitions add symbols rather than shadowing
 * them.  The eleven names that DO overlap are gawk's own getopt and regex,
 * and both are deliberate -- see build.kaem.
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

/* wcscoll --- eval.c's cmp_strings compares two wide strings with this when
 * the locale is multibyte.  ntlibc has wcscmp but not wcscoll.  In the C
 * locale collation order IS code-point order, so this is exact rather than
 * an approximation -- and with MB_CUR_MAX at 1 the branch that calls it is
 * unreachable in the first place.  The declaration eval.c gets is the
 * implicit one, which for a function returning int with pointer arguments
 * is the same cdecl call this definition provides.
 */
int wcscoll(const wchar_t *a, const wchar_t *b)
{
	return wcscmp(a, b);
}

/* putwc --- node.c's dump_wstr(), a debugging aid marked
 * __attribute__((unused)) and called from nowhere, is the only caller.  tcc
 * emits it regardless, so the symbol has to resolve.  ntlibc has no wide
 * stdio at all, so this is built out of wcrtomb and putc, which it does
 * have.  wint_t is int here, so again the implicit declaration node.c gets
 * agrees with this definition.
 */
wint_t putwc(wchar_t c, FILE *fp)
{
	char buf[MB_LEN_MAX];
	size_t n, i;

	n = wcrtomb(buf, c, (mbstate_t *) 0);
	if (n == (size_t) -1)
		return (wint_t) -1;

	for (i = 0; i < n; i++)
		if (putc(buf[i], fp) == EOF)
			return (wint_t) -1;

	return (wint_t) c;
}
