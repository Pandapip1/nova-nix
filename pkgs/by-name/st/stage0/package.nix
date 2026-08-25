{
  lib,
  newScope,
  stage0-src,
}:
let
  packages = lib.makeScope newScope (
    self:
    import ./by-name { callPackage = self.callPackage; }
  );
in
stage0-src
// packages
// { inherit stage0-src; }
