{
  callPackage,
  isLinux,
  stage0,
  stage1,
  mes,
  gnumake,
  bash,
  coreutils-mes,
  libc,
}:
if isLinux then
  callPackage ../gnused/linux {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc-mes.boot;
    coreutils = coreutils-mes;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ../gnused/windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = libc;
  }
