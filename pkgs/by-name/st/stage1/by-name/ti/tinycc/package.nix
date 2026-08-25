{
  callPackage,
  isLinux,
  isWindows,
  targetTriple,
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
if isLinux && targetTriple == "i686-pc-linux-gnu" then
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
else if isWindows then
  callPackage ./windows {
    inherit (stage0) system platforms;
    inherit targetTriple;
    tinycc = stage1.tinycc-mes;
  }
else
  throw "tinycc: unsupported Linux target triple ${targetTriple}"
