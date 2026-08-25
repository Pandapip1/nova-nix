{
  callPackage,
  isLinux,
  stage0,
  tinycc,
  stage1,
  gnused,
  gnumake,
  gnugrep,
  gnutar-mes,
  gzip,
  gawk-mes,
  bash,
  coreutils-mes,
  libc,
}:
if isLinux then
  callPackage ./linux/musl.nix {
    inherit (stage0) system platforms;
    inherit tinycc gnused;
    gnutar = gnutar-mes;
    coreutils = coreutils-mes;
  }
else
  callPackage ./windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = libc;
  }
