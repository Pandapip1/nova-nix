{
  callPackage,
  stage0-src,
  hex2-bootstrap,
}:
callPackage ./implementation.nix { inherit stage0-src hex2-bootstrap; }
