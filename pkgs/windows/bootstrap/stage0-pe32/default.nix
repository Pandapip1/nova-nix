# stage0-pe32: a full-source bootstrap for Windows, as a scope.
#
# The layout follows nixpkgs' pkgs/os-specific/linux/minimal-bootstrap/
# stage0-posix: one pinned upstream source, a platforms.nix holding the
# arch-dependent names, a hex0.nix that turns the seed into a checked hex0, and
# a mescc-tools-boot.nix that walks the rest of the chain in the order
# upstream's own build script does.
#
# Nothing is vendored.  Every source file the chain assembles comes out of
# `src`, so the whole bootstrap is pinned by a single hash and is audited by
# reading upstream rather than by diffing copies of it.
#
# The scope is layered over the enclosing package set, so a link may name the
# link below it -- hex1 is built by hex0 -- without those names reaching the
# top level.
{ lib, newScope }:
lib.makeScope newScope (
  self:
  with self;
  {
    inherit (callPackage ./platforms.nix { })
      platforms
      system
      stage0Arch
      pe32Arch
      ;

    inherit (callPackage ./bootstrap-sources.nix { }) version src;

    # The seed ships in the same repository as the source it assembles, so
    # `src` carries both.  nixpkgs needs a second fetch here only because
    # upstream keeps its POSIX seeds in a separate repository.
    hex0-seed = "${src}/bootstrap-seeds/PE32/i386/hex0-seed.exe";

    hex0 = callPackage ./hex0.nix { };

    inherit (callPackage ./mescc-tools-boot.nix { })
      hex1
      hex2
      catm
      M0
      cc_x86
      M2
      M1
      hex2-new
      ;
  }
)
