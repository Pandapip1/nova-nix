{
  lib,
  newScope,
  stage2,
}:
let
  # Bash and the libc-backed TinyCC use the supporting userland assembled in
  # stage2; stage1's own final values win where the scopes overlap.
  stageScope = extra: newScope (stage2 // extra);
in
lib.makeScope stageScope (
  self:
  import ./by-name { callPackage = self.callPackage; }
)
