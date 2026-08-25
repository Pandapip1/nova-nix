{
  lib,
  newScope,
}:
let
  packages = lib.makeScope newScope (
    self:
    import ./by-name { callPackage = self.callPackage; }
  );
in
packages.stage0-src
// packages
