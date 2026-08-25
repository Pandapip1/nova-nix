{
  callPackage,
  platform,
  libc,
  stage0,
  gcc,
  gnused,
  gnutar,
  coreutils,
  gnumake,
  gnugrep,
  gzip,
  bash,
}:
if platform == "linux" then
  let
    target = import ../../st/stage0-src/linux/platforms.nix { };
  in
  callPackage ../../mu/musl-libc/gcc.nix {
    inherit gcc;
    inherit (target) system platforms;
    gnused = gnused;
    gnutar = gnutar;
    coreutils = coreutils;
  }
else
  libc
