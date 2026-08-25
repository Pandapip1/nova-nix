{
  callPackage,
  platform,
  stage0,
  stage1,
  mes,
  gnumake,
  bash,
  coreutils-mes,
  libc,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc.boot;
    coreutils = coreutils-mes;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ./windows {
    tinycc = stage1.tinycc;
    ntlibc = libc;
  }
