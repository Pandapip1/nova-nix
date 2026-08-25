{
  platform,
  musl-libc,
  ntlibc,
}:
if platform == "linux" then musl-libc else ntlibc
