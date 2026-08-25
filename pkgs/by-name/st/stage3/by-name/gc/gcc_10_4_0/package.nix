{
  callPackage,
  stage0,
  gcc-cxx_4_6_4,
  libc,
}:
callPackage ../gcc_4_6_4/linux/10.nix {
  inherit stage0 libc;
  inherit (stage0) system platforms;
  gcc = gcc-cxx_4_6_4;
}
