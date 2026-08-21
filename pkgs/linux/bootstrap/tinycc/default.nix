# TinyCC: the first C compiler in the bootstrap that can compile itself.
{
  lib,
  newScope,
  stage0,
  mes,
  nyacc,
}:
lib.makeScope newScope (
  self:
  with self;
  {
    inherit (stage0) system platforms;

    inherit (callPackage ./bootstrap-sources.nix { }) version src;

    mainline = callPackage ./mainline-sources.nix { };

    boot = callPackage ./boot.nix {
      inherit stage0 nyacc;
      inherit (mes) mes-m2;
      mes-libc = mes.libc;
      mesSrc = mes.src;
      mainlineSrc = mainline.src;
      mainlineVersion = mainline.version;
    };
  }
)
