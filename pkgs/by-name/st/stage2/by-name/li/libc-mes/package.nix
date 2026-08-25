{
  isLinux,
  musl-libc-mes,
  ntlibc,
}:
if isLinux then musl-libc-mes else ntlibc
