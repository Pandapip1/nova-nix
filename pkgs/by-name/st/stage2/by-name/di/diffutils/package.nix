{
  callPackage,
  platform,
  stage0,
  tinycc,
  stage1,
  gnused,
  coreutils,
  libc,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc-mes;
    gnused = gnused;
    coreutils = coreutils;
  }
else
  callPackage ./windows {
    tinycc = tinycc;
    ntlibc = libc;
  }
