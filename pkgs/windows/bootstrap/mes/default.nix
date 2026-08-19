# GNU Mes for Windows, as a scope.
#
# The stage above stage0-pe32: that chain ends with a C compiler, an assembler
# and a linker, and this is the first thing built with all three rather than
# assembled by hand.  Mes is a Scheme interpreter and a C compiler, and is
# where a bootstrap stops being hexadecimal and starts being a language.
#
# The tools come from the stage0 scope rather than being rebuilt here, so the
# binary this produces is the one that chain's own output made.
{
  lib,
  newScope,
  stage0,
}:
lib.makeScope newScope (
  self:
  with self;
  {
    inherit (stage0) system platforms;

    inherit (callPackage ./bootstrap-sources.nix { }) version src;

    inherit (callPackage ./mes-m2.nix { inherit (stage0) M2 M1 hex2-new; })
      mes-m2
      ;
  }
)
