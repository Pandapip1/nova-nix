{
  lib,
  newScope,
  stage1,
}:
let
  # Stage2 recipes may name stage1 tools directly; a stage2 package with the
  # same name wins inside this scope.
  stageScope = extra: newScope (stage1 // extra);
in
lib.makeScope stageScope (
  self:
  import ./by-name { callPackage = self.callPackage; }
)
