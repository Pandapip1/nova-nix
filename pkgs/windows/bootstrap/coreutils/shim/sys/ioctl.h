/* <sys/ioctl.h> for a system that has no ioctl.
 *
 * NT's device control is NtDeviceIoControlFile, which takes a different
 * shape entirely, and ntlibc offers no ioctl() to wrap it.
 *
 * cat.c includes this header whenever _POSIX_SOURCE is not defined -- an
 * unconditional include in practice -- and then uses ioctl(FIONREAD) as an
 * optimisation, but only inside `#ifdef FIONREAD'.  Defining nothing is
 * therefore the whole answer: cat compiles, and takes the branch that just
 * reads.  Nothing else in the set this package builds reaches for ioctl.
 *
 * Defining _POSIX_SOURCE instead would also silence the include, but it
 * would narrow every ntlibc header at the same time, which is a much larger
 * change to make for one optimisation.
 *
 * This goes away when ntlibc grows an ioctl, if it ever does.
 */
#ifndef _SYS_IOCTL_H
#define _SYS_IOCTL_H

#endif /* _SYS_IOCTL_H */
