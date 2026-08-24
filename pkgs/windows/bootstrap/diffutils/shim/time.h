/* <time.h> for GNU diffutils on ntlibc: ntlibc's, plus gnulib's timezone_t.
 *
 * The counterpart of gnulib's lib/time.in.h, cut to the one interface it has
 * to add.  ntlibc's <time.h> already has everything else diffutils reaches
 * for -- strftime, mktime, timegm, localtime_r, tzset, tzname, and, under
 * _GNU_SOURCE, tm_gmtoff and tm_zone in struct tm.
 *
 * timezone_t is not a C library type at all: it is gnulib's, and it exists
 * because POSIX has no thread-safe way to format a time in a named zone.
 * lib/time_rz.c implements the four functions below and lib/nstrftime.c
 * calls two of them (mktime_z, localtime_rz) unconditionally, so this is not
 * an interface that can be withheld -- and it is the one place a missing
 * declaration would have been a silent wrong answer rather than a warning:
 * mktime_z returns time_t, which is 64 bits wide in ntlibc, and an implicit
 * `int' return would have truncated every timestamp `diff -u' prints.
 *
 * src/context.c is the only caller in diffutils, through nstrftime, and it
 * always passes a null tz -- the local zone.  The machinery is still real:
 * a null tz is what makes mktime_z fall through to mktime and localtime_rz
 * to localtime_r.
 */

#ifndef _GL_DIFFUTILS_TIME_H
#define _GL_DIFFUTILS_TIME_H

#include_next <time.h>

/* A timezone.  (timezone_t) NULL stands for the local zone; the struct is
   opaque and defined in lib/time-internal.h, which only time_rz.c reads. */
typedef struct tm_zone *timezone_t;

extern timezone_t tzalloc (char const *__name);
extern void tzfree (timezone_t __tz);
extern struct tm *localtime_rz (timezone_t __tz, time_t const *__timer,
                                struct tm *__result);
extern time_t mktime_z (timezone_t __tz, struct tm *__tm);

#endif /* _GL_DIFFUTILS_TIME_H */
