{
  callPackage,
  isLinux,
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
if isLinux then
  callPackage ../gnutar/linux {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc-mes.boot;
    gnused = gnused-mes;
    coreutils = coreutils-mes;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ../gnutar/windows {
    tinycc = stage1.tinycc-mes;
    ntlibc = libc;
  }
