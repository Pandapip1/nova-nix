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
# boot-mes does not build yet.  Compiling tcc.c through this side's mes-m2.exe
# segfaults -- a byte write through a null pointer, deterministically, not the
# GC/allocation-pattern flakiness an earlier look at this suspected (that read
# was wrong: the one run that looked "clean" was actually hitting an
# unrelated file-not-found path in a since-fixed test harness, not really
# avoiding the crash).
#
# Bisected to a single line: TinyCC's tccgen.c, inside decl0, the call
# `type_decl(&type, &ad, &v, TYPE_DIRECT);` a few lines into the loop that
# walks each declaration.  Confirmed by two independent means of narrowing --
# truncating tccgen.c at increasingly precise, brace-and-#if-balanced cut
# points (the first attempt at this was itself contaminated by an unbalanced
# `#if 0`, which cost a false "it's variable shadowing" lead before being
# caught and corrected) -- both converge on this exact call.  The same call
# shape appears earlier in the same file (tccgen.c:3693) and compiles fine
# there, so it is not the call itself; something about decl0's own state at
# that point in its two nested `while(1)` loops is what triggers it.  A
# hand-written minimal repro of that state (shadowed local, address-of after
# the shadowing scope closes) does not reproduce it either, so whatever this
# is depends on real accumulated compiler state, not a small isolable
# construct.
#
# Ruled out: arena exhaustion (identical crash at 15M and 25M cells; GC does
# run -- confirmed via MES_DEBUG=2, dozens of collections happen before the
# crash -- so it is not "GC never runs", either). Ruled out: g_free literally
# being NULL in any of gc.c's four cell allocators (make_cell,
# make_pointer_cell, make_value_cell, alloc) -- a temporary build with a
# null-guard added to all four still crashed at the identical instruction,
# meaning whatever pointer is null at the point of the write isn't g_free in
# one of those.  The crash is a byte store (`movb %al,(%ebx)`, storing literal
# 2) reached through a conditional branch, inside src/*.c compiled code (a
# fixed address inside mes-m2.exe, not anything from the target program being
# compiled) -- consistent with some other cell-shaped allocation this session
# didn't get to, but not confirmed.  The same tcc.c content compiles cleanly
# through Linux's mes-m2 (pkgs/linux/....tinycc.boot.boot0 already builds),
# so this is specific to the Windows-built interpreter, not a defect in
# tcc.c or in mescc's Scheme-level compiler logic.
#
# Next step needs real tooling rather than more blind bisection: M2-Planet's
# calling convention here (frame pointer in %esi, not %ebp; return-address
# placement that doesn't match ordinary cdecl) makes the wine crash dump's
# raw stack contents unreadable without either a symbolized build or
# purpose-built stack-walking, neither of which exists yet for this chain.
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
