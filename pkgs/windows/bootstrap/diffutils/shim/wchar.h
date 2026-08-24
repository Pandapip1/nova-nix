/* <wchar.h> for GNU diffutils on ntlibc: ntlibc's, plus two names.
 *
 * The counterpart of gnulib's lib/wchar.in.h, cut to the two names it has to
 * add.  ntlibc has btowc, mbrtowc, mbsinit, mbsrtowcs, wcrtomb, wcscat,
 * wctype, iswctype, towlower and wmemchr; it has neither wcwidth nor
 * wmempcpy.
 *
 *   wcwidth   nt-missing.c supplies it -- see its header for why it is that
 *             file and not gnulib's lib/wcwidth.c.  Only src/side.c calls
 *             it, laying out the columns of `diff -y'.
 *   wmempcpy  gnulib's own lib/wmempcpy.c is compiled and supplies it.
 *             lib/fnmatch_loop.c calls it when folding case in a multibyte
 *             bracket expression.
 */

#ifndef _GL_DIFFUTILS_WCHAR_H
#define _GL_DIFFUTILS_WCHAR_H

#include_next <wchar.h>

extern int wcwidth (wchar_t __wc);
extern wchar_t *wmempcpy (wchar_t *__dest, const wchar_t *__src, size_t __n);

#endif /* _GL_DIFFUTILS_WCHAR_H */
