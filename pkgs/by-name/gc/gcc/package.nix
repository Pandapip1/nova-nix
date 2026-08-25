{
  stage0,
  stage3,
}:
stage3.callPackage ../../st/stage3/by-name/gc/gcc_4_6_4/linux/latest.nix {
  inherit stage0;
  inherit (stage0) system platforms;
  gcc = stage3.gcc_15_3_0;
  libc = stage3.libc;
  gnutar = stage3.gnutar;
}
