# The Windows package set.
#
# Layout follows nixpkgs:
#
#   by-name/<shard>/<pname>/package.nix   one package per directory, shard =
#                                         the first two characters of <pname>
#   bootstrap/stage0-pe32/                the full-source bootstrap chain, as
#                                         its own scope
#   bootstrap/                            the sha256-pinned MSYS2 seeds
#   stdenv/                               mkDerivation, setup.sh, cc-wrapper.sh
#
# What is not Windows-specific lives one level up and is shared with the other
# package sets: ../lib.nix and ../build-support/.
#
# The set is a fixpoint: callPackage reads each package.nix's formal parameters
# and supplies them from the set being defined, so a package names its
# dependencies -- { stdenv, zlib }: ... -- rather than reaching across the tree
# with a relative import.  Nothing enumerates by-name packages; adding one is
# adding a directory.
let
  lib = import ../lib.nix;

  # The scope constructor, as nixpkgs spells it: newScope layers extra
  # arguments over the set, and callPackage is that with nothing extra.  A
  # nested scope (the bootstrap) is given newScope so it can layer itself on
  # in turn.
  newScope = extra: lib.callPackageWith (self // extra);
  callPackage = newScope { };

  # by-name is sharded to keep any one directory small, so the two levels are
  # walked directly here: the shard is a storage detail and must not show up
  # as an attribute.
  byName =
    let
      root = ./by-name;
      # readDir answers name -> type, and every entry at both levels is a
      # directory by construction.  Reading the type it already returned is
      # what keeps a stray file from being taken for a shard or a package:
      # unfiltered, an editor swapfile or a .DS_Store is opened as a directory
      # and takes the whole set down with "inappropriate type", rather than
      # being passed over.
      subdirectories =
        dir:
        let
          entries = builtins.readDir dir;
        in
        builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries);
      inShard =
        shard:
        map (pname: {
          name = pname;
          value = callPackage (root + "/${shard}/${pname}/package.nix") { };
        }) (subdirectories (root + "/${shard}"));
    in
    builtins.listToAttrs (builtins.concatMap inShard (subdirectories root));

  self = byName // {
    inherit lib newScope callPackage;

    stdenv = import ./stdenv;

    # build-support entries are named here rather than discovered, as nixpkgs
    # does in all-packages.nix: they are ways of building things, not packages.
    derivationWithMeta = callPackage ../build-support/derivation-with-meta/package.nix { };

    fetchurl = import <nix/fetchurl.nix>;

    # The bootstrap is a scope of its own, so the names of its intermediate
    # links (hex1, catm, M0.hex2) stay inside it.
    stage0 = callPackage ./bootstrap/stage0-pe32 { };

    # The stage above it, built by the compiler, assembler and linker stage0
    # ends with.  Its own intermediates (mes.M1, mes.hex2) stay inside it too.
    mes = callPackage ./bootstrap/mes { };

    # Not a stage: the parser modules MesCC loads, which Mes does not vendor.
    nyacc = callPackage ../bootstrap/nyacc { };
  };
in
self
