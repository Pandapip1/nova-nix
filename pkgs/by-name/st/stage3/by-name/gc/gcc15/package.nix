{
  platform,
  stage0,
  stage2,
  gcc46,
  gcc10,
  libc,
  gnutar,
}:
if platform == "linux" then
  stage2.callPackage ../gcc46/linux/latest.nix {
    inherit (stage0) system platforms;
    gcc = gcc10;
    musl = libc;
    gnutar = gnutar;
  }
else
  gcc46
