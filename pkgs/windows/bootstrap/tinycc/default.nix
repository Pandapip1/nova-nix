# TinyCC for Windows, as the shared bootstrap recipe.
#
# tccTarget stays "I386" -- TinyCC has one x86 code generator, and PE32 is a
# question of what TCC_TARGET_PE adds on top of it (tccpe.c, PE-shaped
# section and relocation handling), not a different one.  mesArchInclude
# points at the headers this side's Mes C library actually has.
#
# hex2-new rather than stage0.hex2: mescc.scm's linker step passes flags
# (--little-endian, --base-address) that only the C-written hex2 reads: see
# pkgs/windows/bootstrap/mes/mes-m2.nix for the same substitution.  No
# bloodElf: --debug-info builds an ELF symbol table, and there is no such
# thing to build here.
#
# arenaSize matches mes-libc's: see pkgs/bootstrap/mes/libc.nix for where the
# figure comes from.  tcc.c compiled in one pass (ONE_SOURCE=1) is a
# comparable-sized translation unit to libc+tcc.c, so the same ceiling
# applies for the same reason -- what a 32-bit process can reserve as
# contiguous address space under wine.
{
  stage0,
  mes,
  nyacc,
  callPackage,
}:
callPackage ../../../bootstrap/tinycc {
  inherit stage0 mes nyacc;
  tccTarget = "I386";
  mesArchInclude = "windows/x86";
  extraTargetDefines = [ "TCC_TARGET_PE=1" ];
  hex2 = stage0.hex2-new;
  bloodElf = null;
  arenaSize = "15000000";
}
