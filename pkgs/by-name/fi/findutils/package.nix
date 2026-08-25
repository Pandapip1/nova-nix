{
  callPackage,
  platform,
  stage0,
  tinycc,
  tinycc-bootstrap,
  gnused,
  gnutar,
  coreutils,
  libc,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = tinycc;
    gnused = gnused;
    gnutar = gnutar;
    coreutils = coreutils;
  }
else
  callPackage ./windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
  }
