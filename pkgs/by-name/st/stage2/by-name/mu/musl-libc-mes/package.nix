{
  callPackage,
  stage0,
  stage1,
  gnumake,
  gnupatch,
  gnused-mes,
  gnugrep,
  gnutar-mes,
  gzip,
  bash,
  coreutils-mes,
}:
let
  target = stage0;
in
callPackage ../musl-libc/default.nix {
  inherit stage0;
  inherit (target) system platforms;
  tinycc = stage1.tinycc.boot;
  gnused = gnused-mes;
  gnutar = gnutar-mes;
  coreutils = coreutils-mes;
}
