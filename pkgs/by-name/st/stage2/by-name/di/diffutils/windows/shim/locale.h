/* <locale.h> for GNU diffutils on ntlibc: ntlibc's, plus setlocale_null.
 *
 * The counterpart of gnulib's lib/locale.in.h, cut to the one thing it has
 * to add.  ntlibc's setlocale is real -- LC_ALL, LC_CTYPE, LC_COLLATE,
 * LC_NUMERIC, LC_MONETARY, LC_TIME, LC_MESSAGES -- and localeconv is there
 * too, so nothing else in the template applies.
 *
 * What gnulib adds is setlocale_null_r and the SETLOCALE_NULL_MAX buffer
 * size it writes into: `setlocale (category, NULL)' returns a pointer into
 * static storage that another thread's setlocale may overwrite, and gnulib
 * copies it out under a lock instead.  lib/hard-locale.c is the only caller
 * here, and it is the one that decides whether diff sorts directory entries
 * with strcoll or with strcmp.  gnulib's locale.in.h pulls setlocale_null.h
 * in the same way, from the same directory.
 */

#ifndef _GL_DIFFUTILS_LOCALE_H
#define _GL_DIFFUTILS_LOCALE_H

#include_next <locale.h>

#include "setlocale_null.h"

#endif /* _GL_DIFFUTILS_LOCALE_H */
