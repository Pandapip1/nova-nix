/* <sys/stat.h> for GNU diffutils on ntlibc: ntlibc's, plus the eleven
 * file-type predicates POSIX never standardised.
 *
 * The counterpart of gnulib's lib/sys_stat.in.h, cut to the part this build
 * uses.  lib/file-type.c names all of these outside any #ifdef -- S_ISCTG for
 * a Masscomp contiguous file, S_ISDOOR for a Solaris door, S_ISMPB/MPC/MPX
 * for V7 and AIX multiplexed files, S_ISNAM for a Xenix named file,
 * S_ISNWK for an HP-UX network special, S_ISOFD/S_ISOFL for Cray offline
 * files, S_ISPORT for a Solaris event port, S_ISWHT for a BSD whiteout --
 * and gnulib answers each `0' on any system that does not have it.  NT has
 * none of them, so all eleven are 0, which is the same answer gnulib reaches
 * on Linux for nine of the eleven.
 *
 * Without this, tcc reads each as an implicit function call and the link
 * fails on eleven undefined symbols.  file-type.c is reached from
 * src/diff.c, which prints "X is a Y while Y is a Z" when the two sides of a
 * comparison are different kinds of file.
 */

#ifndef _GL_DIFFUTILS_SYS_STAT_H
#define _GL_DIFFUTILS_SYS_STAT_H

#include_next <sys/stat.h>

#ifndef S_ISCTG
# define S_ISCTG(m) 0
#endif
#ifndef S_ISDOOR
# define S_ISDOOR(m) 0
#endif
#ifndef S_ISMPB
# define S_ISMPB(m) 0
#endif
#ifndef S_ISMPC
# define S_ISMPC(m) 0
#endif
#ifndef S_ISMPX
# define S_ISMPX(m) 0
#endif
#ifndef S_ISNAM
# define S_ISNAM(m) 0
#endif
#ifndef S_ISNWK
# define S_ISNWK(m) 0
#endif
#ifndef S_ISOFD
# define S_ISOFD(m) 0
#endif
#ifndef S_ISOFL
# define S_ISOFL(m) 0
#endif
#ifndef S_ISPORT
# define S_ISPORT(m) 0
#endif
#ifndef S_ISWHT
# define S_ISWHT(m) 0
#endif

#endif /* _GL_DIFFUTILS_SYS_STAT_H */
