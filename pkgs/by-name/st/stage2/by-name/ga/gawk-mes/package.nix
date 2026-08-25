{
  callPackage,
  platform,
  stage0,
  stage1,
  mes,
  gnumake,
  gnupatch,
  gnused-mes,
  gnugrep,
  bash,
  coreutils-mes,
  libc,
}:
if platform == "linux" then
  callPackage ../gawk/linux/mes.nix {
    inherit (stage0) system platforms;
    tinycc = stage1.tinycc.boot;
    gnused = gnused-mes;
    coreutils = coreutils-mes;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ../gawk/windows {
    tinycc = stage1.tinycc;
    ntlibc = libc;
  }
