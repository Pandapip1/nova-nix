/* <pwd.h> for a system with no passwd database.
 *
 * GNU make's read.c and gnulib's glob.c both include this unconditionally
 * on any target that is not WINDOWS32, to expand `~user' -- and this build
 * is deliberately not WINDOWS32: make's own w32 backend wants a Windows C
 * runtime, where what is wanted here is the POSIX one ntlibc provides.
 *
 * NT has no passwd database to answer from, so getpwnam and getpwuid say
 * "no such user".  make treats that as `~user' naming nobody and leaves the
 * word alone, which is the truthful answer rather than a guess at a home
 * directory that does not exist.
 *
 * Here rather than in ntlibc because it is not a C library's job to invent
 * a user database for a system that has none; if ntlibc grows a real
 * <pwd.h> this file goes away and the -I with it.
 */
#ifndef _PWD_H
#define _PWD_H

#include <sys/types.h>

struct passwd
{
  char *pw_name;
  char *pw_passwd;
  uid_t pw_uid;
  gid_t pw_gid;
  char *pw_gecos;
  char *pw_dir;
  char *pw_shell;
};

static struct passwd *
getpwnam (const char *name)
{
  (void) name;
  return 0;
}

static struct passwd *
getpwuid (uid_t uid)
{
  (void) uid;
  return 0;
}

static void
endpwent (void)
{
}

#endif /* _PWD_H */
