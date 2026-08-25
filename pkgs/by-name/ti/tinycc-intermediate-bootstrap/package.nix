{
  callPackage,
  platform,
  stage0,
  tinycc-bootstrap,
  libc-bootstrap,
  gnumake,
  gnused-bootstrap,
  gnugrep,
  gnutar-bootstrap,
  gzip,
  bash,
  coreutils-bootstrap,
}:
if platform == "linux" then
  callPackage ../tinycc/linux {
    inherit (stage0) system platforms;
    musl = libc-bootstrap;
    tinycc = tinycc-bootstrap.boot // {
      inherit (tinycc-bootstrap) mainlineSrc version;
    };
    gnused = gnused-bootstrap;
    gnutar = gnutar-bootstrap;
    coreutils = coreutils-bootstrap;
  }
else
  null
