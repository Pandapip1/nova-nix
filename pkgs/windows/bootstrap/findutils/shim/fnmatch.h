/* <fnmatch.h> with the GNU flags, which ntlibc's has not got.
 *
 * ntlibc HAS fnmatch, and it is a correct POSIX one -- FNM_PATHNAME,
 * FNM_NOESCAPE, FNM_PERIOD, and it even picks the same bit values.  It is
 * not enough for find:
 *
 *   FNM_CASEFOLD     -iname, -ipath, -iregex's siblings; find/parser.c
 *                    passes it for every case-insensitive name test.
 *   FNM_LEADING_DIR  -path against a directory prefix.
 *   FNM_EXTMATCH     accepted by the flag parser, never set by find.
 *
 * So gl/lib/fnmatch.c is compiled and this header declares what it
 * implements.  gnulib would have generated this from fnmatch.in.h with nine
 * substitutions; the only one that mattered was whether to rename the entry
 * point to rpl_fnmatch, and it is not renamed here -- gnulib's fnmatch.c
 * defines the plain name, the object is named on the link line, and so it is
 * resolved before libc.a is searched and ntlibc's fnmatch.o is never pulled
 * out.  That is a choice rather than a collision; see the nm note in
 * build.kaem, which confirms it from both ends.
 *
 * The bit values are gnulib's, and they agree with ntlibc's for the three
 * POSIX flags -- checked, because a disagreement would be silent: a pattern
 * compiled with one header and matched by the other library's code.
 */
#ifndef _GL_NT_FNMATCH_H
#define _GL_NT_FNMATCH_H

#ifdef __cplusplus
extern "C" {
#endif

#define FNM_PATHNAME    (1 << 0) /* No wildcard can ever match '/'.  */
#define FNM_NOESCAPE    (1 << 1) /* Backslashes don't quote special chars.  */
#define FNM_PERIOD      (1 << 2) /* Leading '.' is matched only explicitly.  */
#define FNM_FILE_NAME   FNM_PATHNAME   /* Preferred GNU name.  */
#define FNM_LEADING_DIR (1 << 3)       /* Ignore '/...' after a match.  */
#define FNM_CASEFOLD    (1 << 4)       /* Compare without regard to case.  */
#define FNM_EXTMATCH    (1 << 5)       /* Use ksh-like extended matching.  */

/* Value returned by 'fnmatch' if STRING does not match PATTERN.  */
#define FNM_NOMATCH     1

/* This value is returned if the implementation does not support
   'fnmatch'.  POSIX leaves it unspecified; gnulib's fnmatch never
   returns it.  */
#define FNM_NOSYS       (-1)

/* Match NAME against the file name pattern PATTERN,
   returning zero if it matches, FNM_NOMATCH if not.  */
extern int fnmatch (const char *__pattern, const char *__name, int __flags);

#ifdef __cplusplus
}
#endif

#endif /* _GL_NT_FNMATCH_H */
