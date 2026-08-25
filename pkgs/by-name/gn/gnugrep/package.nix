{
  callPackage,
  platform,
  stage0,
  tinycc-bootstrap,
  mes,
  gnumake,
  bash,
  coreutils-bootstrap,
  libc,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = tinycc-bootstrap.boot;
    coreutils = coreutils-bootstrap;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ./windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
  }
