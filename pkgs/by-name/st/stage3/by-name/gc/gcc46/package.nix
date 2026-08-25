{
  platform,
  stage0,
  stage1,
  stage2,
}:
if platform == "linux" then
  stage2.callPackage ./linux {
    inherit (stage0) system platforms;
    musl = stage2.libc;
  }
else
  stage2.callPackage ./windows {
    tinycc = stage1.tinycc;
    ntlibc = stage2.libc;
  }
