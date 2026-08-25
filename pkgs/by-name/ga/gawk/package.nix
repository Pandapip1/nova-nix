{
  callPackage,
  platform,
  stage0,
  tinycc,
  tinycc-bootstrap,
  gnumake,
  gnused,
  gnugrep,
  gnutar-bootstrap,
  gzip,
  bash,
  coreutils-bootstrap,
  gawk-bootstrap,
  libc,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = tinycc;
    gnused = gnused;
    bootGawk = gawk-bootstrap;
    gnutar = gnutar-bootstrap;
    coreutils = coreutils-bootstrap;
  }
else
  callPackage ../gawk5/windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
    bootGawk = gawk-bootstrap;
  }
