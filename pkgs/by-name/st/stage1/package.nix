{
  lib,
  newScope,
}:
# Mes and the first TinyCC built by MesCC.
lib.makeScope newScope (
  self:
  import ./by-name { callPackage = self.callPackage; }
)
