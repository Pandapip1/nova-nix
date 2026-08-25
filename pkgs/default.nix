# A package set is a fixpoint over by-name values.  Those values are not
# required to be derivations: source descriptions, scopes, functions, nullable
# capabilities, and stdenv all live in the same dependency-injected namespace.
{ platform ? "linux" }:
let
  # The loader needs callPackageWith before it can load by-name, so `lib` is
  # the one value bootstrapped by importing its by-name recipe directly.
  lib = import ./by-name/li/lib/package.nix;
  newScope = extra: lib.callPackageWith (self // extra);
  callPackage = newScope { };
  byName = import ./by-name { inherit callPackage; };

  self = byName // {
    inherit
      lib
      newScope
      callPackage
      platform
      ;

  };
in
self
