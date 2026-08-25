{
  platform,
  musl-libc-mes,
  ntlibc,
}:
if platform == "linux" then musl-libc-mes else ntlibc
