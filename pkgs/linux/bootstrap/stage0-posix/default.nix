# stage0-posix: a full-source bootstrap for Linux, as a scope.
#
# The Windows set's stage0-pe32 is a fork of this, so the two are deliberately
# the same shape: one pinned upstream source, a platforms.nix holding the
# arch-dependent names, a hex0.nix that turns the seed into a checked hex0, and
# a mescc-tools-boot.nix that walks the rest of the chain in the order
# upstream's own build script does.  Reading them side by side is the point --
# what differs between the two is exactly what Windows needed.
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
      ;

    inherit (callPackage ./bootstrap-sources.nix { }) version src;

    # The seed ships as a submodule of the source it assembles, so `src`
    # carries both.  It is 100755 in git, and fetchGit restores that, which is
    # what lets it run at all.
    hex0-seed = "${src}/bootstrap-seeds/POSIX/x86/hex0-seed";

    hex0 = callPackage ./hex0.nix { };

    # The chain, in upstream's order.  The names are upstream's own artifact
    # names with the characters nix will not take in an identifier replaced:
    # hex2-0 is hex2_0, M1-macro-1.M1 is M1_macro_1_M1.
    inherit (callPackage ./mescc-tools-boot.nix { })
      hex1
      hex2_0
      catm
      M0
      cc_x86
      M2
      blood_elf_0
      M1_0
      hex2_1
      M1
      hex2
      ;
  }
)
