{
  callPackage,
  platform,
  stage0,
  tinycc-bootstrap,
  mes,
  gnumake,
  gnupatch,
  gnused-bootstrap,
  gnugrep,
  bash,
  coreutils-bootstrap,
  libc,
}:
if platform == "linux" then
  callPackage ../gawk/linux/mes.nix {
    inherit (stage0) system platforms;
    tinycc = tinycc-bootstrap.boot;
    gnused = gnused-bootstrap;
    coreutils = coreutils-bootstrap;
    mesInclude = "${mes.src}/include";
  }
else
  callPackage ../gawk/windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
  }
