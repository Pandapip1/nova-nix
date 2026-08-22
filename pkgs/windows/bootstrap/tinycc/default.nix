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
#
# boot-mes builds: see pkgs/bootstrap/mes and the mes/M2-Planet forks for
# the three bugs that were stacked underneath the crash this comment used
# to describe (an unreported assertion failure, hiding an M2-Planet
# short-circuit bug, hiding a genuine arena exhaustion). What's left of
# that story: TCC_TARGET_PE is deliberately absent from
# extraTargetDefines below. MesCC cannot compile tccpe.c's own
# `#pragma pack(push, 1)`, so it never went in the round that MesCC
# itself compiles -- laterTargetDefines carries it instead, reaching
# every round from boot0 up, where a real (if still bootstrapping) tcc is
# doing the compiling and #pragma pack is no longer MesCC's problem.
#
# boot0 does not build yet -- not from anything in this file. The compiled
# boot-mes.exe binary itself crashes on every invocation, including with
# no arguments at all: a null-pointer *call* (not a data read), inside
# what disassembles as an __ntcall-shaped trampoline (push up to six args,
# `call *eax` through the first one) reached from a resolve-and-cache
# pattern matching __ntdll_resolve's own. The name being resolved is an
# address past the end of the file's real content, in the same
# zero-mapped-past-PE_end region Mes's own argv/envp live in on this
# side -- consistent with a string that some earlier step was supposed to
# place there and didn't, though that step hasn't been found yet. This
# reproduces standalone (`wine boot-mes.exe` with no arguments, from
# outside nix entirely), so it is not about anything boot0's own
# machinery asks of it; boot-mes.exe itself is broken as a program, the
# same way __assert_fail was broken as a program, before the fixes noted
# above. Bisecting it needs the same disassembly-first approach that found
# those three, starting from this crash's own call chain rather than
# tccgen.c's content, since this one reproduces before argv is even
# looked at.
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
  # See the comment above: MesCC can't compile tccpe.c, so PE32 starts one
  # round later than the target itself does.
  laterTargetDefines = [ "TCC_TARGET_PE=1" ];
  # mes-libc's own crt1, not recompiled: it isn't C on this side
  # (lib/windows/x86-mes-mescc/crt1.M1, hand-assembled), and there is
  # nothing round-specific about it to justify redoing that work at every
  # round -- it is cdecl, the same calling convention every round's own
  # tcc uses, so the one mes-libc already built serves every round alike.
  crt1Object = mes.libc.crt1;
  hex2 = stage0.hex2-new;
  bloodElf = null;
  # 19000000, not mes-libc's 15000000: this round's translation unit
  # (tcc.c, ONE_SOURCE=1, so every file it #includes comes along) needs
  # more headroom than mes-libc's own largest bundle did. Measured: 15M
  # failed with "make_cell: out of memory" -- a real, correctly-reported
  # exhaustion once __assert_fail's own bug (see the mes fork) stopped
  # eating the message -- and 19M is enough to finish.
  arenaSize = "19000000";
}
