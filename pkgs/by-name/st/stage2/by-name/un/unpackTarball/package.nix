{ callPackage, isLinux, stage0 }:
if isLinux then
  callPackage ./linux { inherit (stage0) system platforms; }
else
  null
