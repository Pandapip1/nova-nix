/* ioctl, for a system whose terminal is not a Unix tty.
 *
 * bash reaches the terminal through shtty.c's ttgetattr/ttsetattr, which
 * are ioctl(TCGETA)/ioctl(TCSETAW).  NT has no such call and ntlibc has no
 * ioctl at all, so this answers "not a terminal" -- bash then leaves the
 * terminal settings alone, which is what a shell running scripts needs and
 * all this bootstrap asks of it.
 */
#include <errno.h>

int
ioctl (int fd, int request, ...)
{
  (void) fd;
  (void) request;
  errno = ENOTTY;
  return -1;
}
