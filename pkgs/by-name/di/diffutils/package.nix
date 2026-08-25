{
  callPackage,
  platform,
  stage0,
  tinycc,
  tinycc-bootstrap,
  gnused,
  coreutils,
  libc,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = tinycc;
    gnused = gnused;
    coreutils = coreutils;
  }
else
  callPackage ./windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
  }
