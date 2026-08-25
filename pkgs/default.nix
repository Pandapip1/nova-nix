# A package set is a fixpoint over by-name values.  Those values are not
# required to be derivations: source descriptions, scopes, functions, nullable
# capabilities, and stdenv all live in the same dependency-injected namespace.
{
  platform ? "x86_64-linux",
  buildTriple ? if builtins.match ".*-windows" platform != null then "i686-pc-pe" else "i686-pc-linux-gnu",
  hostTriple ? buildTriple,
  targetTriple ? hostTriple,
}:
let
  isLinux = builtins.match ".*-linux" platform != null;
  isWindows = builtins.match ".*-windows" platform != null;
  platformFamily = if isWindows then "windows" else "linux";
  checkedPlatform =
    if isLinux || isWindows then platform else throw "unsupported platform: ${platform}";
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
      isLinux
      isWindows
      platformFamily
      buildTriple
      hostTriple
      targetTriple
      ;

    platform = checkedPlatform;

  };
in
self
