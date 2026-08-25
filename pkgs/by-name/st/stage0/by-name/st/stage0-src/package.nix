{ callPackage, platform }:
callPackage ./source.nix { inherit platform; }
