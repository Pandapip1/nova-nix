args@{
  platform,
  gcc,
  binutils,
  bash,
  coreutils,
  gnused,
  gnugrep,
  gawk5,
  findutils,
  diffutils,
  gnumake,
  gnupatch,
  gzip,
  gnutar,
  tinycc,
  tinycc-bootstrap,
  libc,
  stage0,
  callPackage,
}:
if platform == "windows" then
  import ./windows (
    builtins.removeAttrs args [
      "platform"
      "libc"
      "tinycc-bootstrap"
    ]
    // {
      tinycc = tinycc-bootstrap;
      ntlibc = libc;
    }
  )
else
  null
