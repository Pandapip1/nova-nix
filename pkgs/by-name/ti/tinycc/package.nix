{
  callPackage,
  platform,
  stage0,
  tinycc-bootstrap,
  tinycc-intermediate-bootstrap,
  libc,
  gnumake,
  gnused-bootstrap,
  gnugrep,
  gnutar-bootstrap,
  gzip,
  bash,
  coreutils-bootstrap,
}:
if platform == "linux" then
  let
    toolchain = tinycc-intermediate-bootstrap // {
      compiler = tinycc-intermediate-bootstrap;
      libs = tinycc-intermediate-bootstrap;
      inherit (tinycc-bootstrap) mainlineSrc version;
    };
  in
  callPackage ./linux {
    inherit stage0;
    inherit (stage0) system platforms;
    musl = libc;
    tinycc = toolchain;
    gnused = gnused-bootstrap;
    gnutar = gnutar-bootstrap;
    coreutils = coreutils-bootstrap;
  }
else
  tinycc-bootstrap.boot.compiler
