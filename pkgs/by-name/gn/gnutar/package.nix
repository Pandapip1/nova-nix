{
  callPackage,
  platform,
  stage0,
  tinycc,
  tinycc-bootstrap,
  gnused,
  gnumake,
  gnugrep,
  gzip,
  gawk-bootstrap,
  bash,
  coreutils-bootstrap,
  libc,
}:
if platform == "linux" then
  callPackage ./linux/musl.nix {
    inherit (stage0) system platforms;
    inherit tinycc gnused;
    coreutils = coreutils-bootstrap;
  }
else
  callPackage ./windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
  }
