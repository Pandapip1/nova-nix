# TinyCC for Windows, as the shared bootstrap recipe.
#
# tccTarget stays "I386" -- TinyCC has one x86 code generator, and PE32 is a
# question of what TCC_TARGET_PE adds on top of it (tccpe.c, PE-shaped
# section and relocation handling), not a different one.  mesArchInclude
# points at the headers this side's Mes C library actually has.
#
# stage0.hex2 is the C-written linker: mescc.scm's linker step passes flags
# (--little-endian, --base-address) that the earlier hand-written hex2 does
# not read.  See pkgs/by-name/me/mes/windows/mes-m2.nix as well.  No
# bloodElf: --debug-info builds an ELF symbol table, and there is no such
# thing to build here.
#
# arenaSize matches mes-libc's: see pkgs/by-name/me/mes/shared/libc.nix for where the
# figure comes from.  tcc.c compiled in one pass (ONE_SOURCE=1) is a
# comparable-sized translation unit to libc+tcc.c, so the same ceiling
# applies for the same reason -- what a 32-bit process can reserve as
# contiguous address space under wine.
#
# boot-mes builds: see pkgs/by-name/me/mes and the mes/M2-Planet forks for
# the three bugs that were stacked underneath the crash this comment used
# to describe (an unreported assertion failure, hiding an M2-Planet
# short-circuit bug, hiding a genuine arena exhaustion).
#
# TCC_TARGET_PE is in extraTargetDefines, so PE32 is the target from the
# first round rather than from boot0. It was the other way round while
# MesCC could not compile tccpe.c, and that was not survivable: the round
# MesCC compiles is the only one in the chain that emits an executable at
# all, so a boot-mes that did not know PE emitted ELF, and boot0 came out
# as Windows code -- PEB reads, ntdll calls -- inside an ELF wrapper, which
# neither system will load. Four MesCC bugs stood in the way, all fixed in
# the mes fork and none of them Windows-specific; tccpe.c is simply the
# first file in the bootstrap to ask for any of them, being #ifdef'd out
# of the Linux chain entirely.
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
callPackage ../shared {
  inherit stage0 mes nyacc;
  tccTarget = "I386";
  mesArchInclude = "windows/x86";
  # Every round from boot0 up needs telling too: extraTargetDefines reaches
  # only the round MesCC compiles.
  laterTargetDefines = [ "TCC_TARGET_PE=1" ];
  # See the comment above. The four MesCC bugs, for the record: #pragma
  # pack, a typedef naming more than one thing, offsetof of a nested field,
  # and a struct initialised from another struct -- that last one silently,
  # which is what makes it worth naming here.
  extraTargetDefines = [ "TCC_TARGET_PE=1" ];
  # tcc.h makes PATHSEP a semicolon under TCC_TARGET_PE: see boot.nix.
  pathSep = ";";
  # mes-libc's own crt1, for bootMes's library only: it isn't C on this side
  # (lib/windows/x86-mes-mescc/crt1.M1, hand-assembled, meant to be handed
  # straight to hex2's own linker the way boot-mes.exe's own build already
  # is), so it is copied rather than recompiled -- see boot.nix's own
  # crt1Object.
  crt1Object = mes.libc.crt1;
  # Every round from boot0 up has a real tcc doing the compiling instead,
  # which can build a real crt1 from C source the ordinary way -- see
  # boot.nix's own crt1Source and lib/windows/x86-mes-gcc/crt1.c for what
  # this file does that lib/linux/${arch}-mes-gcc/crt1.c did not need to.
  windowsCrt1Src = "${mes.src}/lib/windows/x86-mes-gcc/crt1.c";
  # mescc's linker defaults to 0x1000000, matching Linux's own ELF header;
  # PE32-i386.hex2 hardcodes ImageBase 0x400000 instead, the same way
  # mes-m2.nix already tells the same hex2 for the round before this one.
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
  hex2 = stage0.hex2;
  bloodElf = null;
  # 19000000, not mes-libc's 15000000: this round's translation unit
  # (tcc.c, ONE_SOURCE=1, so every file it #includes comes along) needs
  # more headroom than mes-libc's own largest bundle did. Measured: 15M
  # failed with "make_cell: out of memory" -- a real, correctly-reported
  # exhaustion once __assert_fail's own bug (see the mes fork) stopped
  # eating the message -- and 19M is enough to finish.
  arenaSize = "19000000";
}
