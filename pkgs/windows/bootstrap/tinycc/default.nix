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
# boot-mes.exe used to crash on every invocation, including with no
# arguments at all -- see baseAddress below for what that was and the
# fourth bug it turned out to be (mescc's linker disagreeing with
# PE32-i386.hex2 about where the image loads).
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
  # mescc's linker defaults to 0x1000000, matching Linux's own ELF header;
  # PE32-i386.hex2 hardcodes ImageBase 0x400000 instead, the same way
  # mes-m2.nix already tells hex2-new for the round before this one.
  # boot-mes without this: every absolute address it emits (a string
  # literal's, a global's) lands 0xC00000 too high -- still inside the
  # image's declared (zero-filled) VirtualSize, so nothing refuses to load
  # it, but past SizeOfRawData, so what is read back through it is zero
  # bytes rather than the content that was meant to be there. This is the
  # boot-mes.exe crash the comment below used to describe unsolved: found
  # by disassembling the crash site (a null-through-%eax call inside an
  # __ntcallN trampoline) back to its caller, which turned out to be
  # brk.c's own first NtAllocateVirtualMemory call -- __ntdll_resolve
  # ("NtAllocateVirtualMemory") reading its name argument from
  # 0x107b6c0, 0xC00000 past where the string literal actually landed
  # (0x47b6c0, comfortably inside the file), reads zero bytes, matches no
  # export, and returns 0 for __ntcall6 to call through.
  baseAddress = "0x400000";
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
