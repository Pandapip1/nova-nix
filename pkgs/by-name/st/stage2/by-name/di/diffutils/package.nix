{
  callPackage,
  isLinux,
  stage0,
  tinycc,
  stage1,
  gnused,
  coreutils,
  libc,
}:
if isLinux then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc;
    gnused = gnused;
    coreutils = coreutils;
  }
else
  callPackage ./windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = libc;
  }
