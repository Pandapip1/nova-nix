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

    # The C library MesCC compiles, and what TinyCC will link against.
    #
    # The shared package, told which kernel: that picks the include directory,
    # the source lists, what a program starts at, and -- only here -- the PE32
    # header and footer that hex2 wraps an executable in.
    libc = callPackage ../shared/libc.nix {
      inherit stage0;
      inherit (stage0) kaem;
      mesKernel = "windows";
      sources = import ./libc-sources.nix { };
      mesccPrelude = ./mescc-prelude.scm;

      # Smaller than the Linux side's, because it has to be.  A 32-bit
      # Windows process gets a gigabyte of contiguous address space and a
      # wine-hosted one 256MB, so 15 million cells -- 198MB with the jam
      # buffer -- is what fits everywhere this is built.  Whether the largest
      # translation unit compiles in that is a question for the round that
      # needs it, and lib/windows/brk.c is where the figure comes from.
      arenaSize = "15000000";
    };
  }
)
