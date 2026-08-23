/* <langinfo.h> for ntlibc, which does not have one.
 *
 * This is not a "gawk asked and the answer was no" case, which is why it is
 * a file rather than a withheld HAVE_LANGINFO_CODESET.  support/regcomp.c --
 * the glibc regex compiler gawk vendors, reached through support/regex.c --
 * includes <langinfo.h> from support/regex_internal.h unconditionally, and
 * calls nl_langinfo(CODESET) in re_compile_internal outside every #ifdef,
 * to decide whether the current locale is UTF-8.  There is no configure
 * switch that turns that off; the header and the function simply have to
 * exist.
 *
 * gawk itself has the same problem on MS-Windows and answers it the same
 * way: pc/langinfo.h is this file with the same two lines in it, and
 * pc/gawkmisc.pc supplies the function.  That file is about the Microsoft C
 * runtime and is not compiled here, so the pair is reproduced -- see
 * nt-missing.c for the other half.
 *
 * It lands in the source root, which -I. already covers, so no include path
 * moves for it.  gawk has no langinfo.h of its own outside pc/.
 */
#ifndef NT_LANGINFO_H
#define NT_LANGINFO_H

#define CODESET 1

extern char *nl_langinfo(int);

#endif
