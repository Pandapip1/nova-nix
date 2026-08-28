# The GCC-backed stdenv used to cross the final userland boundary.  It is the
# same implementation as the exported stdenv, but deliberately retains the
# reduced stage2 coreutils so that the complete coreutils can be built without
# depending on the stdenv that will ultimately contain it.
{
  callPackage,
  stage2,
}:
callPackage ../stdenv/package.nix {
  coreutils = stage2.coreutils;
}
