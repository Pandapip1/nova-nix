{
  callPackage,
  stage0,
  tinycc-bootstrap,
  tinycc-intermediate-bootstrap,
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
  toolchain = tinycc-intermediate-bootstrap // {
    compiler = tinycc-intermediate-bootstrap;
    libs = tinycc-intermediate-bootstrap;
    inherit (tinycc-bootstrap) mainlineSrc version;
  };
in
callPackage ./default.nix {
  inherit stage0;
  inherit (target) system platforms;
  tinycc = toolchain;
  gnused = gnused-bootstrap;
  gnutar = gnutar-bootstrap;
  coreutils = coreutils-bootstrap;
}
