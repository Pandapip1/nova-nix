{
  callPackage,
  isLinux,
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
if isLinux then
  callPackage ../../../../stage1/by-name/ti/tinycc/linux {
    inherit (stage0) system platforms;
    musl = libc-mes;
    tinycc = stage1.tinycc-mes.boot // {
      inherit (stage1.tinycc-mes) mainlineSrc version;
    };
    gnused = gnused-mes;
    gnutar = gnutar-mes;
    coreutils = coreutils-mes;
  }
else
  null
