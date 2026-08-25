{ callPackage, platformFamily }:
let
  implementation = ./. + "/${platformFamily}.nix";
in
if builtins.pathExists implementation then
  callPackage implementation { }
else
  null
