{
  callPackage,
  stage0,
  stage1,
  tinycc-intermediate,
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
  toolchain = tinycc-intermediate // {
    compiler = tinycc-intermediate;
    libs = tinycc-intermediate;
    inherit (stage1.tinycc) mainlineSrc version;
  };
in
callPackage ./default.nix {
  inherit stage0;
  inherit (target) system platforms;
  tinycc = toolchain;
  gnused = gnused-mes;
  gnutar = gnutar-mes;
  coreutils = coreutils-mes;
}
