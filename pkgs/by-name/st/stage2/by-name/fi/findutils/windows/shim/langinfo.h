/* <langinfo.h> for ntlibc, which does not have one.
 *
 * The same case as the gawk 5.3.2 sibling's, and for the same reason:
 * gl/lib/regex_internal.h includes <langinfo.h> unconditionally, and
 * gl/lib/regcomp.c calls nl_langinfo (CODESET) in re_compile_internal
 * outside every #ifdef, to decide whether the locale is UTF-8.  There is no
 * knob that turns that off -- the header and the function simply have to
 * exist.  Note that HAVE_LANGINFO_H and HAVE_LANGINFO_CODESET are still
 * answered NO in config.h, deliberately: everything else in this build that
 * would use nl_langinfo (gl/lib/localcharset.c) has a portable fallback, and
 * the honest answer for that code is that this platform has no langinfo.
 * This header exists for the one caller that does not ask.
 *
 * shim/nt-missing.c is the other half.
 */
#ifndef _GL_NT_LANGINFO_H
#define _GL_NT_LANGINFO_H

#define CODESET 1

extern char *nl_langinfo (int);

#endif /* _GL_NT_LANGINFO_H */
