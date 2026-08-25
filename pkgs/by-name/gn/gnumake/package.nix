{
  callPackage,
  platform,
  stage0,
  tinycc-bootstrap,
  mes,
  gnupatch,
  libc,
}:
if platform == "linux" then
  callPackage ./linux {
    inherit (stage0) system platforms;
    tinycc = tinycc-bootstrap.boot;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ./windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
  }
