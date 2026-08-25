{
  platform,
  gcc,
  stage0,
  stage1,
  stage2,
  callPackage,
}:
if platform == "windows" then
  import ./windows {
    inherit gcc stage0 callPackage stage2;
    inherit (stage2)
      binutils
      bash
      coreutils
      gnused
      gnugrep
      gawk5
      findutils
      diffutils
      gnumake
      gnupatch
      gzip
      gnutar
      ;
    tinycc = stage1.tinycc-mes;
    ntlibc = stage2.libc;
  }
else
  null
