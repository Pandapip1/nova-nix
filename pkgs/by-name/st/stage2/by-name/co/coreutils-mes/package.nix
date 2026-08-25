{
  callPackage,
  platform,
  stage0,
  stage1,
  mes,
  gnumake,
  gnupatch,
  libc,
}:
if platform == "linux" then
  callPackage ../coreutils/linux {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc-mes.boot;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ../coreutils/windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = libc;
  }
