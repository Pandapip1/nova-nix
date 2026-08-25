{
  callPackage,
  platform,
  stage0,
  stage1,
  mes,
  gnupatch,
  libc,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc-mes.boot;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ./windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = libc;
  }
