{
  callPackage,
  stage0,
  gcc_4_6_4,
  libc,
}:
callPackage ../gcc_4_6_4/linux/cxx.nix {
  inherit stage0 libc;
  inherit (stage0) system platforms;
  gcc = gcc_4_6_4;
}
