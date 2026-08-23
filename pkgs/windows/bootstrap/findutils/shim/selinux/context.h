/* <selinux/context.h> for a system that has no SELinux.
 *
 * The companion of ./selinux.h.  gl/lib/selinux-at.h includes it, and
 * nothing findutils compiles calls anything in it -- the context_t
 * manipulation functions are coreutils' business, not find's -- so the
 * header only has to exist and define the type.  gnulib's own stub
 * (gl/lib/se-context.in.h) defines the whole family; this defines the type
 * and stops, because declaring functions no caller has would be inventing an
 * interface.
 */
#ifndef _GL_NT_SELINUX_CONTEXT_H
#define _GL_NT_SELINUX_CONTEXT_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct
{
  void *ptr;
} context_s_t;

typedef context_s_t *context_t;

#ifdef __cplusplus
}
#endif

#endif /* _GL_NT_SELINUX_CONTEXT_H */
