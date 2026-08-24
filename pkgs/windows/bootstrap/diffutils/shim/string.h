/* <string.h> for GNU diffutils on ntlibc: ntlibc's, plus four names.
 *
 * The counterpart of gnulib's lib/string.in.h, cut to the four names it has
 * to add.  ntlibc's <string.h> is otherwise complete for diffutils -- memchr,
 * mempcpy, stpcpy, strdup, strndup, strnlen, strcasecmp and strncasecmp are
 * all there and all real -- so this wrapper adds four declarations and defers
 * everything else, rather than substituting the 1100-line template.
 *
 *   rawmemchr   src/cmp.c and src/io.c call it to find the newline that the
 *               sentinel byte after the buffer guarantees is there.  gnulib's
 *               lib/rawmemchr.c is compiled and supplies it.
 *   mbsstr      lib/propername.c, looking for an author's ASCII name inside
 *               its translation.  lib/mbsstr.c.
 *   mbslen      lib/mbsstr.c itself, counting characters rather than bytes.
 *               lib/mbslen.c.
 *   mbscasecmp  lib/exclude.c, comparing an --exclude pattern case-blind.
 *               lib/mbscasecmp.c.
 *
 * The last three are multibyte-aware string functions that no C library has;
 * they are gnulib's own, and their declarations live in gnulib's <string.h>
 * because that is where a caller would look for them.  Withholding any of
 * the four would not have failed to compile: tcc falls back on an implicit
 * `int' return, which is the right width for a pointer on i386 and would
 * silently stop being so anywhere else.
 */

#ifndef _GL_DIFFUTILS_STRING_H
#define _GL_DIFFUTILS_STRING_H

#include_next <string.h>

extern void *rawmemchr (const void *__s, int __c);
extern char *mbsstr (const char *__haystack, const char *__needle);
extern size_t mbslen (const char *__string);
extern int mbscasecmp (const char *__s1, const char *__s2);

#endif /* _GL_DIFFUTILS_STRING_H */
