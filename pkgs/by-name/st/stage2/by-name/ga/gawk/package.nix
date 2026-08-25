{
  callPackage,
  platform,
  stage0,
  tinycc,
  stage1,
  gnumake,
  gnused,
  gnugrep,
  gnutar-mes,
  gzip,
  bash,
  coreutils-mes,
  gawk-mes,
  libc,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc-mes;
    gnused = gnused;
    bootGawk = gawk-mes;
    gnutar = gnutar-mes;
    coreutils = coreutils-mes;
  }
else
  callPackage ../gawk5/windows {
    tinycc = tinycc;
    ntlibc = libc;
    bootGawk = gawk-mes;
  }
