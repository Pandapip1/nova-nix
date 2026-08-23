/* <termio.h> for a system whose terminal is not a Unix tty.
 *
 * bash reaches the terminal through shtty.c's ttgetattr/ttsetattr, which
 * are ioctl(TCGETA)/ioctl(TCSETAW) on a struct termio.  NT has no such
 * ioctl, so those calls fail and bash carries on with its terminal
 * settings unchanged -- which is what a shell running scripts needs, and
 * all this bootstrap asks of it.  The same answer Mes's C library gives.
 *
 * The numbers are Linux's, because they are what bash was written against
 * and nothing here reinterprets them: the struct is only ever handed
 * straight back to an ioctl that declines.
 */
#ifndef _TERMIO_H
#define _TERMIO_H

#define TIOCGWINSZ 0x5413
#define TCGETA     0x5405
#define TCSETAW    0x5407

#define VTIME 5
#define VMIN  6

#define ISIG   0000001
#define ICANON 0000002
#define ECHO   0000010
#define ECHOK  0000040
#define ECHONL 0000100

#define ISTRIP 0000040
#define INLCR  0000100
#define ICRNL  0000400

#define CS8    0000060
#define PARENB 0000400

struct winsize
{
  unsigned short ws_row;
  unsigned short ws_col;
  unsigned short ws_xpixel;
  unsigned short ws_ypixel;
};

struct termio
{
  unsigned short c_iflag;
  unsigned short c_oflag;
  unsigned short c_cflag;
  unsigned short c_lflag;
  unsigned char c_line;
  unsigned char c_cc[8];
};

#endif /* _TERMIO_H */
