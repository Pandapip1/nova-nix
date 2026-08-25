{
  callPackage,
  stage0-src,
  hex0-seed,
}:
callPackage ./implementation.nix { inherit stage0-src hex0-seed; }
