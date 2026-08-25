{
  callPackage,
  platform,
  stage0,
  tinycc,
  stage1,
  gnused,
  gnumake,
  gnugrep,
  gzip,
  gawk-mes,
  bash,
  coreutils-mes,
  libc,
}:
if platform == "linux" then
  callPackage ./linux/musl.nix {
    inherit (stage0) system platforms;
    inherit tinycc gnused;
    coreutils = coreutils-mes;
  }
else
  callPackage ./windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = libc;
  }
