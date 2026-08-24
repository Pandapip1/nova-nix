/* <langinfo.h> for ntlibc, which does not have one.
 *
 * The same file, for the same reason, as the one beside the gawk 5.3.2
 * package: lib/regex_internal.h -- the glibc regex internals diffutils
 * vendors, reached from lib/regex.c -- includes <langinfo.h> unconditionally,
 * and lib/regcomp.c calls nl_langinfo (CODESET) in re_compile_internal
 * outside every #ifdef, to decide whether the current locale is UTF-8.
 * There is no configure switch that turns that off; the header and the
 * function simply have to exist.
 *
 * HAVE_LANGINFO_CODESET is still answered NO in config.h, and that is not a
 * contradiction: the question configure asks is whether the C LIBRARY has
 * this header, and ntlibc does not.  lib/localcharset.c reads that answer,
 * and taking its setlocale-based path rather than its nl_langinfo path is
 * the honest outcome -- both return "ASCII" here, and only one of them is
 * about a header this port wrote itself.
 */
#ifndef DIFFUTILS_NT_LANGINFO_H
#define DIFFUTILS_NT_LANGINFO_H

#define CODESET 1

extern char *nl_langinfo (int);

#endif
