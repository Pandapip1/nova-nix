{
  callPackage,
  platform,
  stage0,
  tinycc,
  tinycc-bootstrap,
  libc,
  gnused,
  gnutar,
  coreutils,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = tinycc;
    musl = libc;
    gnused = gnused;
    gnutar = gnutar;
    coreutils = coreutils;
  }
else
  callPackage ./windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
  }
