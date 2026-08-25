/* <grp.h> for a system that has no group database.
 *
 * NT identifies an account by a SID, not by a numeric gid, and has nothing
 * that answers "what is group 1000 called".  ntlibc has <pwd.h> because a
 * process does have a user it can name; it has no <grp.h> because there is
 * no corresponding group to name.
 *
 * coreutils includes this header unconditionally in id, ls and install, and
 * in lib/idcache.c and lib/userspec.c, so it has to exist.  Answering "no
 * such group" is what those callers already handle: idcache falls back to
 * printing the number, `ls -l' shows the numeric group, and userspec
 * reports that a chown-style GROUP argument is not a known group -- which
 * on this system is true of every group.
 *
 * This goes away when ntlibc grows a <grp.h> of its own, if it ever does.
 */
#ifndef _GRP_H
#define _GRP_H

#include <sys/types.h>

struct group
{
  char *gr_name;
  char *gr_passwd;
  gid_t gr_gid;
  char **gr_mem;
};

/* static, so each translation unit that includes this gets its own copy
   and nothing has to be added to the link line.  */
static struct group *
getgrgid (gid_t gid)
{
  (void) gid;
  return 0;
}

static struct group *
getgrnam (const char *name)
{
  (void) name;
  return 0;
}

static struct group *
getgrent (void)
{
  return 0;
}

static void
setgrent (void)
{
}

static void
endgrent (void)
{
}

#endif /* _GRP_H */
