{ callPackage, platform }:
let
  implementation = ./. + "/${platform}.nix";
in
if builtins.pathExists implementation then
  callPackage implementation { }
else
  null
