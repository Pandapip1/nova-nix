# The Linux package set.
#
# Layout follows the Windows set, which follows nixpkgs:
#
#   bootstrap/stage0-posix/               the full-source bootstrap chain, as
#                                         its own scope
#
# What is not Linux-specific lives one level up and is shared with the other
# package sets: ../lib.nix and ../build-support/.
#
# There is no by-name/ yet: this set is the bootstrap and nothing above it.
let
  lib = import ../lib.nix;

  newScope = extra: lib.callPackageWith (self // extra);
  callPackage = newScope { };

  self = {
    inherit lib newScope callPackage;

    derivationWithMeta = callPackage ../build-support/derivation-with-meta/package.nix { };

    # The bootstrap is a scope of its own, so the names of its intermediate
    # links (hex2-0, M0.hex2, M1-macro-1.M1) stay inside it.
    stage0 = callPackage ./bootstrap/stage0-posix { };
  };
in
self
