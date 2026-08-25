{
  callPackage,
  platform,
  stage0,
  gcc-cxx,
  libc-gcc,
  gnused,
  gnutar,
  coreutils,
}:
if platform == "linux" then
  callPackage ../gcc/linux/10.nix {
    inherit (stage0) system platforms;
    gcc = gcc-cxx;
    musl = libc-gcc;
    gnused = gnused;
    gnutar = gnutar;
    coreutils = coreutils;
  }
else
  gcc-cxx
