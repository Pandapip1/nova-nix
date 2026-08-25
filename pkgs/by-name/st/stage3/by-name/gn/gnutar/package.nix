{
  platform,
  stage0,
  stage2,
  gcc46,
  libc,
}:
if platform == "linux" then
  stage2.callPackage ../../../../stage2/by-name/gn/gnutar/linux/latest.nix {
    inherit (stage0) system platforms;
    gcc = gcc46;
    musl = libc;
  }
else
  stage2.gnutar
