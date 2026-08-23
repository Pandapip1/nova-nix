/* <uchar.h>, which ntlibc does not have.
 *
 * gnulib's quotearg, mbswidth, mbsstr, mbslen and the mbuiter iterators all
 * moved from wchar_t to char32_t some releases ago, and they include
 * <uchar.h> unconditionally -- there is no answer that can be withheld to
 * keep them off it.  gnulib generates its own from uchar.in.h with sixty-two
 * substitutions and, on a platform where wchar_t is already 32 bits wide and
 * UCS-4, generates exactly the aliases below.  This build asserts them.
 *
 * Two facts make that exact rather than approximate, and both were checked
 * rather than assumed:
 *
 *   wchar_t is 32 bits here (ntlibc's arch/i386/bits/alltypes.h) and holds
 *   Unicode code points, so char32_t and wchar_t are the same type and
 *   mbrtoc32 and mbrtowc are the same function.  gnulib's own uchar.in.h
 *   takes this branch whenever _GL_WCHAR_T_IS_UCS4.
 *
 *   The only locale this chain has is C, so every one of these is a
 *   single-byte operation and the c32 layer is not doing any work.
 *
 * The one name that is NOT an alias is c32width: it maps to wcwidth, which
 * ntlibc does not have, so gl/lib/wcwidth.c and gl/lib/uniwidth/width.c are
 * compiled to supply it.
 *
 * Nothing here declares mbsrtoc32s, c32snrtombs or the rest of <uchar.h>:
 * findutils references fourteen names and this header covers those fourteen.
 * Adding the others would be inventing an interface nothing calls.
 */
#ifndef _GL_NT_UCHAR_H
#define _GL_NT_UCHAR_H

#include <stddef.h>
#include <wchar.h>
#include <wctype.h>

#ifdef __cplusplus
extern "C" {
#endif

/* This tcc is C99 and has no char32_t of its own. */
typedef wchar_t char32_t;

/* wcwidth, which ntlibc has not got, is declared in shim/gl-missing-decls.h
   with the rest of what gnulib's <wchar.h> would have added;
   gl/lib/wcwidth.c and gl/lib/uniwidth/width.c define it. */

#define mbrtoc32(pwc, s, n, ps) mbrtowc (pwc, s, n, ps)
#define c32rtomb(s, wc, ps)     wcrtomb (s, wc, ps)

#define c32isalnum(c)  iswalnum (c)
#define c32isalpha(c)  iswalpha (c)
#define c32isblank(c)  iswblank (c)
#define c32iscntrl(c)  iswcntrl (c)
#define c32isdigit(c)  iswdigit (c)
#define c32isgraph(c)  iswgraph (c)
#define c32islower(c)  iswlower (c)
#define c32isprint(c)  iswprint (c)
#define c32ispunct(c)  iswpunct (c)
#define c32isspace(c)  iswspace (c)
#define c32isupper(c)  iswupper (c)
#define c32isxdigit(c) iswxdigit (c)
#define c32tolower(c)  towlower (c)
#define c32toupper(c)  towupper (c)
#define c32width(c)    wcwidth (c)

#ifdef __cplusplus
}
#endif

#endif /* _GL_NT_UCHAR_H */
