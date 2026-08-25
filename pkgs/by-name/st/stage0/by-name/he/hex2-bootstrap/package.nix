{ callPackage, stage0-src, hex1 }:
callPackage ./implementation.nix { inherit stage0-src hex1; }
