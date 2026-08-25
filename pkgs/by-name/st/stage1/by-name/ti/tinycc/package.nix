{
  callPackage,
  platform,
  stage0,
  stage1,
  tinycc-intermediate,
  libc,
  gnumake,
  gnused-mes,
  gnugrep,
  gnutar-mes,
  gzip,
  bash,
  coreutils-mes,
}:
if platform == "linux" then
  let
    toolchain = tinycc-intermediate // {
      compiler = tinycc-intermediate;
      libs = tinycc-intermediate;
      inherit (stage1.tinycc-mes) mainlineSrc version;
    };
  in
  callPackage ./linux {
    inherit (stage0) system platforms;
    musl = libc;
    tinycc = toolchain;
    gnused = gnused-mes;
    gnutar = gnutar-mes;
    coreutils = coreutils-mes;
  }
else
  stage1.tinycc-mes.boot.compiler
