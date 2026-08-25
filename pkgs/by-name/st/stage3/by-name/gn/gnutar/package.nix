{
  isLinux,
  callPackage,
  stage0,
  stage2,
  gcc_4_6_4,
  libc,
}:
if isLinux then
  callPackage ../../../../stage2/by-name/gn/gnutar/linux/latest.nix {
    inherit (stage0) system platforms;
    gcc = gcc_4_6_4;
    musl = libc;
    gnutar = stage2.gnutar;
  }
else
  stage2.gnutar
