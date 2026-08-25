{
  isLinux,
  callPackage,
  stage0,
  stage1,
  stage2,
  gcc_4_6_4,
}:
if isLinux then
  callPackage ../../../../stage2/by-name/mu/musl-libc/gcc.nix {
    gcc = gcc_4_6_4;
    gnutar = stage2.gnutar;
    inherit (stage0) system platforms;
  }
else
  stage1.libc
