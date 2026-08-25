{
  callPackage,
  platformFamily,
  stage0,
}:
callPackage (./. + "/${platformFamily}") { inherit stage0; }
