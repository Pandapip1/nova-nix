{
  callPackage,
  platform,
  stage0,
  stage1,
  libc-mes,
  gnumake,
  gnused-mes,
  gnugrep,
  gnutar-mes,
  gzip,
  bash,
  coreutils-mes,
}:
if platform == "linux" then
  callPackage ../tinycc/linux {
    inherit (stage0) system platforms;
    musl = libc-mes;
    tinycc = stage1.tinycc.boot // {
      inherit (stage1.tinycc) mainlineSrc version;
    };
    gnused = gnused-mes;
    gnutar = gnutar-mes;
    coreutils = coreutils-mes;
  }
else
  null
