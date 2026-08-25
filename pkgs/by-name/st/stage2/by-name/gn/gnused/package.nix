{
  callPackage,
  isLinux,
  stage0,
  tinycc,
  stage1,
  gnumake,
  bash,
  coreutils-mes,
  gnugrep,
  gnutar,
  gzip,
  gawk-mes,
  libc,
}:
if isLinux then
  callPackage ./linux/musl.nix {
    inherit (stage0) system platforms;
    inherit tinycc;
    coreutils = coreutils-mes;
  }
else
  callPackage ./windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = libc;
  }
