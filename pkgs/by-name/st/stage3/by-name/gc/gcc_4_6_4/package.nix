{
  isLinux,
  callPackage,
  stage0,
  stage1,
  stage2,
}:
if isLinux then
  callPackage ./linux {
    inherit (stage0) system platforms;
    libc = stage1.libc;
    gnutar = stage2.gnutar;
  }
else
  callPackage ./windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = stage1.libc;
  }
