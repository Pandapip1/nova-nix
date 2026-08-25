{
  callPackage,
  platform,
  stage0,
}:
callPackage (./. + "/${platform}") { inherit stage0; }
