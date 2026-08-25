{
  callPackage,
  platform,
  stage0,
  tinycc-bootstrap,
  mes,
  gnumake,
  gnused-bootstrap,
  gnugrep,
  bash,
  coreutils-bootstrap,
  libc,
}:
if platform == "linux" then
  callPackage ../gnutar/linux {
    inherit (stage0) system platforms;
    tinycc = tinycc-bootstrap.boot;
    gnused = gnused-bootstrap;
    coreutils = coreutils-bootstrap;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ../gnutar/windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
  }
