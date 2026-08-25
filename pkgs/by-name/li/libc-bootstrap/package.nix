{
  platform,
  musl-libc-bootstrap,
  ntlibc,
}:
if platform == "linux" then musl-libc-bootstrap else ntlibc
