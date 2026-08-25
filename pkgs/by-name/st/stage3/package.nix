{
  lib,
  newScope,
  stage1,
  stage2,
}:
let
  # The GCC ladder builds on the complete TCC/libc userland from stage2.
  stageScope = extra: newScope (stage1 // stage2 // extra);
in
lib.makeScope stageScope (
  self:
  import ./by-name { callPackage = self.callPackage; }
)
