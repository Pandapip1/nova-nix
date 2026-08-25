/* <fnmatch.h> for GNU diffutils on ntlibc.
 *
 * This is gnulib's lib/fnmatch.in.h with its configure-time substitutions
 * already made, and it is the one header of this port that could not simply
 * be withheld.  ntlibc HAS fnmatch, and a POSIX-correct one -- but its
 * <fnmatch.h> defines only the three POSIX flags (FNM_PATHNAME, FNM_NOESCAPE,
 * FNM_PERIOD), and diffutils needs the three GNU ones.  lib/exclude.c passes
 * FNM_LEADING_DIR and FNM_EXTMATCH, and src/diff.c turns
 * --ignore-file-name-case into FNM_CASEFOLD; exclude.c defines each to 0 when
 * the header does not have it, so withholding the answer would not have
 * failed to compile -- `diff -x PAT --ignore-file-name-case' would just have
 * quietly stopped folding case.  That is the reason gnulib's fnmatch.c is
 * compiled in this build and ntlibc's fnmatch.o is left in libc.a: the
 * implementation has to be the one that matches the header.
 *
 * The substitutions this file bakes in are the ones that follow from that:
 * HAVE_FNMATCH_H is 1 and REPLACE_FNMATCH is 1, i.e. "there is a system
 * header but do not use it".  With REPLACE_FNMATCH set, gnulib's template
 * would rename the function to rpl_fnmatch; that renaming is NOT done here,
 * because there is no need for it -- fnmatch.o is named on the link line
 * ahead of libc.a, so a one-pass linker resolves fnmatch to gnulib's before
 * it ever opens the archive, and the name stays the one diffutils and its
 * own sources call.  See the nm note in build.kaem.
 */

#ifndef _GL_FNMATCH_H
#define _GL_FNMATCH_H

/* Deliberately NOT #include_next <fnmatch.h>: ntlibc's would define the
   three POSIX flags with the same values but leave the GNU three out, and
   the point of this file is to describe the implementation being linked. */

/* Bits set in the FLAGS argument to 'fnmatch'.  */
#define FNM_PATHNAME    (1 << 0) /* No wildcard can ever match '/'.  */
#define FNM_NOESCAPE    (1 << 1) /* Backslashes don't quote special chars.  */
#define FNM_PERIOD      (1 << 2) /* Leading '.' is matched only explicitly.  */

#define FNM_FILE_NAME   FNM_PATHNAME   /* Preferred GNU name.  */
#define FNM_LEADING_DIR (1 << 3)       /* Ignore '/...' after a match.  */
#define FNM_CASEFOLD    (1 << 4)       /* Compare without regard to case.  */
#define FNM_EXTMATCH    (1 << 5)       /* Use ksh-like extended matching. */

/* Value returned by 'fnmatch' if STRING does not match PATTERN.  */
#define FNM_NOMATCH     1

/* Never returned by this implementation, but the conformance test suites
   require the symbol to exist.  */
#ifdef _XOPEN_SOURCE
# define FNM_NOSYS      (-1)
#endif

/* Match NAME against the file name pattern PATTERN,
   returning zero if it matches, FNM_NOMATCH if not.  */
extern int fnmatch (const char *__pattern, const char *__name, int __flags);

#endif /* _GL_FNMATCH_H */
