{
  callPackage,
  stage0-src,
  hex0-bootstrap,
}:
callPackage ./implementation.nix { inherit stage0-src hex0-bootstrap; }
