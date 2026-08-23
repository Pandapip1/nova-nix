/* Installed into the build tree as sys/ioctl.h -- see build.kaem. */
/* <sys/ioctl.h> for a system whose terminal is not a Unix tty.
 *
 * See termio.h beside this: bash's terminal handling goes through ioctl on
 * a struct termio, NT has no such call, and the honest answer is one that
 * declines.  ntlibc has no ioctl at all, so the declaration is here and a
 * program that calls it fails to link -- which is louder, and better, than
 * a stub that silently reports success.
 */
#ifndef _SYS_IOCTL_H
#define _SYS_IOCTL_H

#include <termio.h>

int ioctl (int, int, ...);

#endif /* _SYS_IOCTL_H */
