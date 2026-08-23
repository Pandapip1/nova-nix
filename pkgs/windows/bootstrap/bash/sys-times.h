/* Installed into the build tree as sys/times.h -- see build.kaem. */
/* <sys/times.h> for a system with no times(2).
 *
 * bash's ulimit builtin includes this for struct tms and CLK_TCK; it uses
 * neither unless the shell is asked for process times, which this
 * bootstrap never does.  Declared and not defined: a program that does
 * call times() fails to link rather than getting a made-up answer.
 */
#ifndef _SYS_TIMES_H
#define _SYS_TIMES_H

#include <sys/types.h>

struct tms
{
  clock_t tms_utime;
  clock_t tms_stime;
  clock_t tms_cutime;
  clock_t tms_cstime;
};

clock_t times (struct tms *);

#endif /* _SYS_TIMES_H */
