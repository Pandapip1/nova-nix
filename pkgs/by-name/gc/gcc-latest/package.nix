{
  callPackage,
  platform,
  stage0,
  gcc,
  gcc10,
  libc-gcc,
  gnused,
  gnutar-latest,
  coreutils,
}:
if platform == "linux" then
  callPackage ../gcc/linux/latest.nix {
    inherit (stage0) system platforms;
    gcc = gcc10;
    musl = libc-gcc;
    gnused = gnused;
    gnutar = gnutar-latest;
    coreutils = coreutils;
  }
else
  gcc
