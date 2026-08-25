{
  callPackage,
  isLinux,
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
if isLinux then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc;
    gnused = gnused;
    bootGawk = gawk-mes;
    gnutar = gnutar-mes;
    coreutils = coreutils-mes;
  }
else
  callPackage ../gawk5/windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = libc;
    bootGawk = gawk-mes;
  }
