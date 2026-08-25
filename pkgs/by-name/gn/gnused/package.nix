{
  callPackage,
  platform,
  stage0,
  tinycc,
  tinycc-bootstrap,
  gnumake,
  bash,
  coreutils-bootstrap,
  gnugrep,
  gnutar,
  gzip,
  gawk-bootstrap,
  libc,
}:
if platform == "linux" then
  callPackage ./linux/musl.nix {
    inherit (stage0) system platforms;
    inherit tinycc;
    coreutils = coreutils-bootstrap;
  }
else
  callPackage ./windows {
    tinycc = tinycc-bootstrap;
    ntlibc = libc;
  }
