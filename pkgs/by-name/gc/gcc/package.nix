# The chain's final C compiler, per platform.
#
# Linux reaches a modern GCC: the 4.6.4 rung is only a stepping stone, and
# `latest.nix' is the last one built with the one before it.
#
# Windows stops at 4.6.4 -- that IS this chain's final compiler there, built
# and linked end to end by this chain's own tcc against ntlibc.  There is no
# newer rung to point at: see st/stage3/by-name/gc/gcc_4_6_4/windows for what
# it takes to get even that far, and st/stdenv for the cc-wrapper that hides
# its two remaining driver gaps from everything above it.
{
  isLinux,
  stage0,
  stage3,
}:
if isLinux then
  stage3.callPackage ../../st/stage3/by-name/gc/gcc_4_6_4/linux/latest.nix {
    inherit stage0;
    inherit (stage0) system platforms;
    gcc = stage3.gcc_15_3_0;
    libc = stage3.libc;
    gnutar = stage3.gnutar;
  }
else
  stage3.gcc_4_6_4
