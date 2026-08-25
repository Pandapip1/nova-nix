{
  callPackage,
  platform,
  stage0,
  tinycc-bootstrap,
  mes,
  gnumake,
  gnupatch,
  libc,
}:
if platform == "linux" then
  callPackage ../coreutils/linux {
    inherit (stage0) system platforms;
    tinycc = tinycc-bootstrap.boot;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ../coreutils/windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
  }
