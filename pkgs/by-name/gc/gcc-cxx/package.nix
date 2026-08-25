{
  callPackage,
  platform,
  stage0,
  gcc,
  libc-gcc,
  gnused,
  gnutar,
  coreutils,
}:
if platform == "linux" then
  callPackage ../gcc/linux/cxx.nix {
    inherit (stage0) system platforms;
    inherit gcc;
    musl = libc-gcc;
    gnused = gnused;
    gnutar = gnutar;
    coreutils = coreutils;
  }
else
  gcc
