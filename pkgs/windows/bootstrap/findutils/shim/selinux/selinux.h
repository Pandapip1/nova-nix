/* <selinux/selinux.h> for a system that has no SELinux, which NT is.
 *
 * This is not something ntlibc is missing.  gnulib carries a module for
 * exactly this case -- selinux-h -- whose job is to generate a stub header
 * when the real libselinux is absent, and find needs it because
 * find/defs.h, find/pred.c and gl/lib/selinux-at.h all include the header
 * UNCONDITIONALLY.  gnulib generates its stub from gl/lib/se-selinux.in.h;
 * this build generates none of gnulib's headers, so the stub is written out
 * here.  It is gnulib's, reduced to the six names findutils references and
 * with the GCC attribute and inline machinery dropped, since this tcc reads
 * neither.
 *
 * The consequence for the built program is find's `-context' predicate:
 * is_selinux_enabled() returns 0, so find/parser.c refuses -context with
 * "invalid predicate", which is what GNU find does on any non-SELinux host.
 */
#ifndef _GL_NT_SELINUX_SELINUX_H
#define _GL_NT_SELINUX_SELINUX_H

#include <sys/types.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned short security_class_t;
struct selinux_opt;

#define is_selinux_enabled() 0

static int
getcon (char **con)
  { (void) con; errno = ENOTSUP; return -1; }

static void
freecon (char *con) { (void) con; }

static int
getfilecon (char const *file, char **con)
  { (void) file; (void) con; errno = ENOTSUP; return -1; }

static int
lgetfilecon (char const *file, char **con)
  { (void) file; (void) con; errno = ENOTSUP; return -1; }

static int
fgetfilecon (int fd, char **con)
  { (void) fd; (void) con; errno = ENOTSUP; return -1; }

/* find never sets a context -- only coreutils does -- but
   gl/lib/selinux-at.c defines setfileconat and lsetfileconat
   unconditionally, and they are compiled because getfileconat is what
   find/parser.c's -context reaches for. */
static int
setfilecon (char const *file, char const *con)
  { (void) file; (void) con; errno = ENOTSUP; return -1; }

static int
lsetfilecon (char const *file, char const *con)
  { (void) file; (void) con; errno = ENOTSUP; return -1; }

#ifdef __cplusplus
}
#endif

#endif /* _GL_NT_SELINUX_SELINUX_H */
