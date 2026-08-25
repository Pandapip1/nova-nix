{
  callPackage,
  platform,
  stage0,
  stage1,
  mes,
  gnumake,
  gnused-mes,
  gnugrep,
  bash,
  coreutils-mes,
  libc,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc-mes.boot;
    gnused = gnused-mes;
    coreutils = coreutils-mes;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ./windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = libc;
  }
