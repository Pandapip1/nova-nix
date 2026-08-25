{
  isLinux,
  musl-libc,
  ntlibc,
}:
if isLinux then musl-libc else ntlibc
