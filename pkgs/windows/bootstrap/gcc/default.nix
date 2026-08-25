# GCC 4.6.4 for Windows: the last package in this chain's full-source
# bootstrap. cc1.exe and gcc.exe, compiled and linked ENTIRELY by this
# chain's own tcc (this same chain's tinycc.boot.tcc, the same compiler
# every earlier package on this side of the tree was built with), against
# ntlibc.
#
# Eleven commits of scoping work (896d3ea through 63d15d7) sit ahead of
# this file and this package's build.kaem -- read them in order for the
# real history: what generated/ is and how each of its ~120 files was
# produced (a real off-chain --target=i686-pc-mingw32 configure+make run,
# never regenerated from a guess, same discipline as ../binutils's own
# generated/), the per-line ntlibc audit every config.h in it received
# (auto-host.h, gmp/mpc/libcpp's own, libiberty's own), and the full
# ~1057-file gcc/libcpp + gmp/mpfr/mpc source-file probe against this
# chain's real tcc fork that found zero miscompiles, zero ICEs, and zero
# wrongly-rejected-valid-C anywhere in that whole sweep -- every failure
# chased down resolved to a missing generated file, a probe-harness bug, a
# wrong file in a stale extraction, or a real (already-decided) unvendored
# dependency, never a real gcc source file tcc handled incorrectly.
#
# build.kaem itself (~1330 lines, ~1120 individual compile lines) is
# GENERATED, not hand-typed -- from the same real, checked data every
# earlier commit on this package already vendored or extracted (this
# package's own generated/cc1-link.txt for cc1's real closed OBJS/C_OBJS
# list and link line; the probe harness's own real per-file flag data for
# gcc/libcpp/gmp/mpfr/mpc/libiberty, corrected in place for the popham.c
# per-object-define bug af6c095 found and the HAVE_HOST_CORE2/LT_OBJDIR
# drop that same commit made) -- but every line in it is just as real and
# just as traceable as if it had been typed by hand, per this package's
# own scoping commits' repeated point that a hand-driven, explicit,
# no-loops-no-globs build.kaem is still the right shape at this scale, not
# a ./configure run. See build.kaem's own header for the stage-by-stage
# shape (gmp/mpfr/mpc, libiberty, libcpp, libdecnumber, zlib, cc1's own
# libbackend.a + C_OBJS, cc1.exe, gcc.exe, functional test).
#
# ---------------------------------------------------------------------------
# Target triple: i686-pc-pe, same reasoning as ../binutils
#
# This package targets the exact same triple ../binutils's own binutils
# (as/ld/dlltool) was built for, and for the same reason (see that
# package's own default.nix): config.gcc's own `i[34567]86-*-pe |
# i[34567]86-*-cygwin*` and `*-*-mingw32*` stanzas both select the same
# i386/mingw32.h-based configuration once the generated/ headers this
# package vendors are the ones actually in force (896d3ea/9386c7c already
# established that generated/tm.h really does #include
# config/i386/mingw32.h, and configargs.h's own "i686-pc-pe" string is
# purely cosmetic banner text, not a compiled-in behavioral switch).
#
# ---------------------------------------------------------------------------
# AS_FOR_TARGET / LD_FOR_TARGET: this chain's own tcc, not ../binutils's
# as.exe/ld.exe -- see 9518ca7
#
# Checked directly against the live tcc fork, not assumed: tcc's own
# linker (tccpe.c) cannot consume a real COFF object the way ../binutils's
# own as.exe produces one, and a real GNU ld cannot link ntlibc's own
# crt1.o/libc.a at all (they are tcc's internal ELF relocatables, not
# COFF -- see ../binutils/default.nix's own "ntlibc's crt1.o/libc.a are
# ELF, not COFF"). Every .o this package's own build.kaem produces is
# therefore compiled AND linked by this chain's own tcc, end to end --
# binutils' as.exe/ld.exe are not part of this package's own build at all,
# though build.kaem's own functional test still exercises them
# indirectly: cc1.exe's own -o file.s output is fed straight back into
# this chain's own tcc (its integrated assembler + PE linker), not
# ../binutils's as.exe/ld.exe, for exactly this reason.
#
# ---------------------------------------------------------------------------
# What generated/ actually is, and what got a real per-line ntlibc audit
#
# Two categories, same distinction ../binutils's own default.nix already
# drew for its own generated/:
#
#   Target-derived, host-independent (insn-*.c, gt-*.h, gtype-desc.*,
#   options.c/.h, all the top-level *.h -- config.h, tconfig.h, tm.h,
#   tm_p.h, bconfig.h, insn-*.h, multilib.h, specs.h, and the rest; gmp's
#   own gmp.h/mp.h/gmp-mparam.h/mp_bases.h/fib_table.h/mpz/fac_ui.h/
#   mpn/perfsqr.h/mpn/fib_table.c/mpn/mp_bases.c; mpfr's own mparam.h):
#   built once by running gcc-4.6.4's real ./configure
#   (--target=i686-pc-mingw32) and enough of a real `make all-gcc` (with
#   gmp/mpfr/mpc unpacked in-tree, matching ../../../linux/bootstrap/gcc's
#   own build.sh convention) to produce them, on an ordinary Linux host
#   (896d3ea, 9386c7c, 92feaf0, 12ad247, 537e2c8, af6c095). None of these
#   differ by host -- a function of the gcc/gmp/mpfr version and the
#   --target string, not of ntlibc -- so vendoring the real output rather
#   than re-deriving it from documentation is the same move
#   ../binutils/default.nix's own generated/peigen.c etc. already made.
#   configargs.h is the one hand-written exception (it would otherwise
#   embed the off-chain scratch build's own argv, not a fact about this
#   package): see 9386c7c.
#
#   Real host answers, individually audited against ntlibc's actual
#   headers before being trusted (auto-host.h -- cb7942f/9518ca7; gmp's,
#   mpc's and libcpp's own separate config.h -- 92feaf0; gcc-core's own
#   bundled libiberty's config.h -- 5c4abbd): the same per-line discipline
#   ../binutils's own generated/bfd-config.h etc. already used. mpfr takes
#   no config.h at all -- its ~25 HAVE_*/feature answers are literal `-D`
#   flags on each compile line instead (92feaf0/af6c095), audited the same
#   way, now baked into every mpfr compile line build.kaem generates.
#
# ---------------------------------------------------------------------------
# The FNM_CASEFOLD shim, windows.patch, and shim/windows.h
#
# shim/fnmatch.h: byte-for-byte the same fix as ../binutils's own (and
# ../findutils's before it) -- gcc-core's own bundled libiberty/fnmatch.c
# needs FNM_CASEFOLD, a GNU extension no POSIX fnmatch.h (ntlibc's
# included) declares. windows.patch: the same three _WIN32-branch fixes
# ../binutils's own windows.patch already found and fixed
# (lrealpath.c/make-temp-file.c/physmem.c), freshly re-derived against
# gcc-core's own (different, older) copy of these files -- see 5c4abbd.
# shim/windows.h: gcc/config/i386/mingw32.h unconditionally #includes
# <windows.h> whenever IN_LIBGCC2 is defined; an empty stub is enough
# because the only thing that ever uses it (MINGW_ENABLE_EXECUTE_STACK,
# trampoline/nested-function support) is never instantiated by anything
# this bootstrap compiles -- see 9386c7c.
#
# ---------------------------------------------------------------------------
# host-default.c, not host-linux.c; libgcc scoped down to what this
# bootstrap's own closed source actually calls
#
# gcc/config/host-linux.c (the reference off-chain build's own host hook,
# since that build ran on x86_64-linux) calls PROT_READ/mmap and simply
# does not belong on this target's own file list -- gcc/config/i386/
# host-mingw32.c would be the "real" analogue, but it needs a genuine,
# unmet VirtualAlloc-family API ntlibc does not expose publicly (12ad247,
# 537e2c8: ntlibc's own src/internal/nt.h is explicit that this is
# deliberately not part of the public surface -- a real gap, reported to
# the ntlibc-owning peer session, not patched here). gcc's own generic
# host-default.c fallback (HOST_HOOKS_INITIALIZER, a trivial stub) is used
# instead: checked directly that the only thing host-mingw32.c's real
# hooks provide beyond that stub is precompiled-header address placement,
# which this bootstrap's build.kaem never exercises (no -x c-header, no
# --output-pch -- see also cc1-checksum.o's own reasoning below).
#
# libgcc is not gcc's own libgcc/ build system at all (that needs its own
# separate configure+Makefile machinery this package does not stand up) --
# it is 19 individually tcc-verified L_* compile units straight out of
# gcc/libgcc2.c (9386c7c, 9518ca7), the DImode arithmetic/conversion
# helpers this bootstrap's own closed source (tcc's own codegen, per
# tccgen.c's gen_opl, and whatever cc1 itself later generates) actually
# calls. See generated/cc1-link.txt section 4 for why the 8 C99 _Complex
# lib2funcs (__mulsc3 and friends) are excluded -- grepped for callers
# across the entire closed source set this package builds, zero found --
# and build.kaem's own libgcc comment for why the rest of gcc's real
# ~50-name lib2funcs list (ctors, __main, clz/ctz/popcount/parity, powi,
# the tf-mode variants) is not built: nothing in this bootstrap's own
# already-tcc-probed-clean source calls any of them either. A real gcc.exe
# invocation on a target program that DOES need one of these will fail to
# link with a real, informative undefined-reference error -- correct,
# diagnosable behavior for a deliberately narrowed libgcc, not silent
# breakage.
#
# ---------------------------------------------------------------------------
# cc1-checksum.o: a package-owned stand-in for genchecksum's output, not a
# workaround
#
# Real GCC computes this 16-byte array by running a real HOST-executed
# build tool (gcc/genchecksum.c, an MD5 digest of cc1's own already-
# compiled object code) after C_OBJS exist, and links it into cc1 as
# `executable_checksum`. Grepped this closed source set directly (see
# shim/cc1-checksum.c's own header): the only consumer anywhere is
# gcc/c-family/c-pch.c's precompiled-header staleness check, and this
# bootstrap's build.kaem never invokes PCH (same "dead hook" category as
# host-mingw32.c's own PCH address hooks, immediately above) -- so a fixed
# stand-in value is exactly as correct as a freshly computed one for what
# this build actually does with it, and avoids standing up genchecksum as
# a running (wine-executed) build-time tool to produce a value nothing
# here reads.
#
# ---------------------------------------------------------------------------
# Install-path placeholders: ${out} in place of /usr/local, i686-pc-pe in
# place of i686-pc-mingw32 -- see generated/cc1-link.txt section 3
#
# cppbuiltin.c, cppdefault.c, prefix.c, collect2.c, gcc.c and gccspec.c all
# take their install paths purely from -D flags on their own compile
# lines, not compiled-in literals (confirmed directly against the real
# reference build's own make3.log command lines for each file, not
# assumed uniform) -- build.kaem's own per-file defs substitute ${out} for
# every /usr/local occurrence and i686-pc-pe for every i686-pc-mingw32
# occurrence in those strings mechanically, the same
# -DBINDIR=\"${out}/bin\" idiom ../binutils/build.kaem already established.
#
# ---------------------------------------------------------------------------
# What this package does NOT attempt
#
# gcc.exe (the driver) is built -- its own real, closed object list
# (5c4abbd) links clean against the same libcpp.a/libdecnumber.a/
# libiberty.a cc1.exe uses -- but this package's own functional test does
# not invoke it: gcc.exe's own spec-driven exec of cc1/as/ld as
# subprocesses is a real, separate, not-yet-exercised question (which
# paths it searches, whether COMPILER_PATH/exec_prefixes resolve inside a
# nix store closure the way they would in a traditional install layout),
# left for whoever next drives this package's gcc.exe end to end rather
# than guessed at here. cc1.exe itself -- the actual compiler -- is what
# this package's functional test verifies directly: -o file.s from real C
# source, then this chain's own tcc (not gcc.exe, not binutils' as.exe/
# ld.exe -- see "AS_FOR_TARGET / LD_FOR_TARGET" above) assembling and
# linking the result into a real, running PE32 binary.
{
  derivationWithMeta,
  stage0,
  tinycc,
  ntlibc,
  binutils,
  gnupatch,
  gzip,
  callPackage,
}:
let
  pname = "gcc";
  inherit (stage0) system platforms;
  inherit (import ./sources.nix { })
    version
    gmpVersion
    mpfrVersion
    mpcVersion
    coreTarball
    gmpTarball
    mpfrTarball
    mpcTarball
    ;
  ntlibcSources = callPackage ../ntlibc/bootstrap-sources.nix { };
in
derivationWithMeta {
  inherit
    pname
    version
    system
    coreTarball
    gmpTarball
    mpfrTarball
    mpcTarball
    gmpVersion
    mpfrVersion
    mpcVersion
    ;

  tcc = tinycc.boot.tcc;
  patch = "${gnupatch}/bin/patch.exe";
  ar = "${binutils}/bin/ar.exe";
  # This chain's own real gzip.exe (../gzip), not stage0's minimal
  # ungz -- see build.kaem's own comment for why: ungz's fixed-buffer
  # puff() inflate cannot decompress gcc-core-4.6.4.tar.gz (162MB
  # uncompressed), confirmed directly, while this real gzip.exe already
  # does. Referenced as gunzip.exe for its argv[0]-dispatched decompress
  # mode (see ../gzip/build.kaem's own "Mode from argv[0]" comment).
  gunzip = "${gzip}/bin/gunzip.exe";

  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  windowsPatch = ./windows.patch;
  genDir = ./generated;
  shimDir = ./shim;
  cc1ChecksumC = ./shim/cc1-checksum.c;
  ntRpathC = ./nt-rpath.c;
  helloC = ./hello.c;

  bin_untar = stage0.mescc-tools-extra.untar;
  bin_cp = stage0.mescc-tools-extra.cp;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "GNU Compiler Collection (cc1, gcc) -- C only, for Windows/ntlibc, self-hosted by this chain's own tcc";
    homepage = "https://www.gnu.org/software/gcc";
    license = "gpl3Plus";
    inherit platforms;
  };
}
