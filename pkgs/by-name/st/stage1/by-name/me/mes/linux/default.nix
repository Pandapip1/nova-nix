# GNU Mes, built by the compiler, assembler and linker stage0-posix ends with.
#
# The chain below this one stops at hex2; this is the first thing above it
# that is not a bootstrap tool but a program someone would want: a Scheme
# interpreter, and with it MesCC, the C compiler that goes on to build TinyCC.
{
  lib,
  newScope,
  stage0,
  nyacc,
}:
lib.makeScope newScope (
  self:
  with self;
  {
    inherit (stage0) system platforms;

    inherit (callPackage ./bootstrap-sources.nix { }) version src;

    inherit
      (callPackage ./mes-m2.nix {
        inherit (stage0) M1 hex2;
        M2 = stage0.M2;
        blood-elf = stage0.blood-elf;
      })
      mes-m2
      ;

    # The C library MesCC compiles, and what TinyCC will link against.
    #
    # The shared package, told which kernel: that picks the include directory,
    # the source lists, and what a program starts at.
    libc = callPackage ../shared/libc.nix {
      inherit stage0;
      inherit (stage0) kaem;
      mesKernel = "linux";
      sources = import ./libc-sources.nix { };
      mesccPrelude = ./mescc-prelude.scm;
    };
  }
)
