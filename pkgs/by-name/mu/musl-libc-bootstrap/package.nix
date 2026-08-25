{
  callPackage,
  stage0,
  tinycc-bootstrap,
  gnumake,
  gnupatch,
  gnused-bootstrap,
  gnugrep,
  gnutar-bootstrap,
  gzip,
  bash,
  coreutils-bootstrap,
}:
let
  target = import ../../st/stage0-src/linux/platforms.nix { };
in
callPackage ../musl-libc/default.nix {
  inherit stage0;
  inherit (target) system platforms;
  tinycc = tinycc-bootstrap.boot;
  gnused = gnused-bootstrap;
  gnutar = gnutar-bootstrap;
  coreutils = coreutils-bootstrap;
}
