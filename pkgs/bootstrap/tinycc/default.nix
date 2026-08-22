# TinyCC: the first C compiler in the bootstrap that can compile itself.
#
# Shared by every package set: the source and the sequence of rounds are the
# same wherever it is built, and what differs is the target -- which machine
# tcc emits code for, which object format it writes, and where the Mes C
# library keeps that platform's headers.  Those come in as arguments, so a
# second target is a call site rather than a copy of this directory.
{
  lib,
  newScope,
  stage0,
  mes,
  nyacc,
  # The target tcc is built for, as it spells it: TCC_TARGET_<this>.
  tccTarget,
  # Where the Mes C library keeps this platform's headers, relative to the
  # Mes source root -- "linux/x86" for ELF, and its own spelling elsewhere.
  mesArchInclude,
  # Extra -D arguments for the target, e.g. PE needs TCC_TARGET_PE as well.
  extraTargetDefines ? [ ],
  # Passed straight through to boot.nix -- see there.
  laterTargetDefines ? [ ],
  crt1Object ? null,
  # hex2, blood-elf and arenaSize, passed straight through to boot.nix -- see
  # there.  Defaulted the same way there, so a call site only names them to
  # override.
  hex2 ? stage0.hex2,
  bloodElf ? stage0.blood_elf_0,
  arenaSize ? "100000000",
}:
lib.makeScope newScope (
  self:
  with self;
  {
    inherit (stage0) system platforms;

    inherit (callPackage ./bootstrap-sources.nix { }) version src;

    mainline = callPackage ./mainline-sources.nix { };

    # Named so that the package above can build from the same tree.
    mainlineSrc = mainline.src;

    boot = callPackage ./boot.nix {
      inherit
        stage0
        nyacc
        tccTarget
        mesArchInclude
        extraTargetDefines
        laterTargetDefines
        crt1Object
        hex2
        bloodElf
        arenaSize
        ;
      inherit (mes) mes-m2;
      mes-libc = mes.libc;
      mesSrc = mes.src;
      mainlineSrc = mainline.src;
      mainlineVersion = mainline.version;
    };
  }
)
