{
  callPackage,
  stage0-src,
  hex2-0,
}:
callPackage ./implementation.nix { inherit stage0-src hex2-0; }
