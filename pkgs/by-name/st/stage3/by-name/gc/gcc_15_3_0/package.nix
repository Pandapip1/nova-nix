{
  callPackage,
  stage0,
  gcc_10_4_0,
  libc,
  gnutar,
}:
callPackage ../gcc_4_6_4/linux/latest.nix {
  inherit stage0 libc gnutar;
  inherit (stage0) system platforms;
  gcc = gcc_10_4_0;
}
