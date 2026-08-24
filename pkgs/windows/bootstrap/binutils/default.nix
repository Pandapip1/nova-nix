# GNU binutils 2.46.0 for Windows: ar, ranlib, nm, objcopy, compiled by the
# tcc this chain built, against ntlibc.
#
# Same tarball, same version, same sha256 as ../../../linux/bootstrap/binutils
# -- this project mirrors the Linux bootstrap's stages, and the target-triple
# question that comment left open (see pkgs/windows/default.nix, the note
# ahead of this package) is settled here: i686-pc-pe, not i686-pc-mingw32.
# config.bfd, ld/configure.tgt and gas/configure.tgt all treat "pe" and
# "mingw32" as identical synonyms at every selection point, so nothing is
# lost and nothing is claimed about a mingw runtime this chain does not have.
#
# as and ld are not built here. Both need generation steps nothing in this
# chain has yet: ld unconditionally needs binutils/deffilep.c, which the
# release tarball does not ship pre-generated (bison, absent from this
# chain, would have to run once off-chain and be vendored the way bfd's own
# generated headers are below) plus ld/ldscripts/*, built by genscripts.sh
# for the i386pe emulation; as needs its own object-format glue audited the
# same way bfd's was here. Left for a follow-up package once that generation
# work is done -- ar/ranlib/nm/objcopy do not need any of it, since none of
# the three touches ld's emulation machinery or a bison grammar.
#
# ---------------------------------------------------------------------------
# Why this is a hand-written build.kaem, and not ./configure
#
# bash, sed, grep, gawk, gnumake, coreutils are all built on this chain by
# now (pkgs/windows/default.nix says outright that bash exists so
# "./configure above here" can run), so a configure-driven build is not
# impossible the way it was when gnumake/gawk/gnugrep were built.  It was
# tried in spirit anyway: findutils, the package directly below this one,
# chose not to run its own ./configure for a documented reason -- doing so
# "would have dragged bash, sed, grep, awk, coreutils and make into
# findutils' closure and put some thousands of child processes through an
# exec path that this very package found a bug in" (see
# ../findutils/default.nix).  binutils' real ./configure is that same risk
# multiplied by roughly two orders of magnitude: hundreds of feature-test
# compiles per subdirectory (bfd, libiberty, binutils), each one a child
# process.  Given a package this size already needed hand-auditing every
# HAVE_ answer against ntlibc's real headers (below), running configure
# would not have saved that work -- config.h's answers still had to be
# checked one by one against ntlibc, since a stock Linux configure run
# answers questions this platform answers differently (see generated/, and
# the sizeof/HAVE_MMAP/HAVE_SBRK corrections there) -- while adding the
# exec-storm risk on top.  So: configure was run, but on a real Linux host,
# purely to get its generated OUTPUT (config.h, bfd-in3.h, targmatch.h,
# elf32-target.h, bfdver.h, peigen.c -- none of which the release tarball
# ships pre-built, and none of which need a shell to use once they exist),
# and every answer in the generated/*-config.h files was then re-checked by
# hand against ntlibc's actual headers before being trusted, the same way
# generated/bfd-config.h had HAVE_MMAP, HAVE_MADVISE, HAVE_MPROTECT and the
# SIZEOF_* macros corrected for a target with no <sys/mman.h> and a 32-bit
# `long`.  See "What generated/ actually is" below.
#
# ---------------------------------------------------------------------------
# What generated/ actually is
#
# bfd.h, bfdver.h, elf32-target.h, elf64-target.h, targmatch.h and peigen.c:
# built once by running the real bfd/configure and `make headers` (bfd.h,
# config.h) and a real `make` far enough to generate peigen.c (a sed
# substitution of peXXigen.c, not source) and targmatch.h (built from
# config.bfd's own data by targmatch.sh) on an ordinary Linux host with
# --target=i686-pc-pe.  None of these six files differ by *host* -- they are
# a function of the binutils version and the --target string, not of the
# C library being built against -- so generating them once, off the actual
# binutils build system, and vendoring the result is the same move this
# chain already makes for mes's crt1.M1 (hand-assembled once, copied rather
# than regenerated every build) and for mes's own generated arch headers.
# Regenerating them would need bison (targmatch.h's underlying data needs
# none, but deffilep.c later will) and a full autoconf/automake toolchain
# this chain does not have and a hand-written build.kaem has no way to
# invoke anyway.
#
# The four *-config.h files (bfd, libiberty, binutils, libsframe) are
# different: these DO encode host answers, so the ones from that same
# Linux-host configure run were re-audited by hand against ntlibc's real
# headers before being used, exactly the way build.kaem asserts config.h
# answers for every other package on this side of the chain (see gnumake's
# default.nix/build.kaem for the precedent). What changed from the
# Linux-host answers, and why:
#
#   HAVE_MMAP / USE_MMAP / HAVE_MADVISE / HAVE_MPROTECT   undef'd: no
#     <sys/mman.h> in ntlibc.  bfd's non-mmap path (plain read()) is real
#     and already there.
#   SIZEOF_LONG / SIZEOF_VOID_P   4, not 8: this is a 32-bit target
#     (i386), not the 64-bit Linux host configure ran on.  SIZEOF_OFF_T
#     stays 8 -- ntlibc's off_t is _Int64 unconditionally, not size-of-long.
#   HAVE_FOPEN64 / HAVE_FSEEKO64 / HAVE_FTELLO64 (and their HAVE_DECL_
#     counterparts)   undef'd: these are only real, distinct symbols on a
#     libc with a 32-bit off_t and a large-file-support opt-in.  ntlibc's
#     off_t is always 64-bit, so fopen64 et al are bare #defines behind
#     _LARGEFILE64_SOURCE (include/stdio.h) that this build never sets --
#     asking HAVE_FOPEN64=1 without it makes bfdio.c call a macro that
#     never expands, i.e. an undeclared function.  HAVE_FSEEKO/HAVE_FTELLO
#     (the real, non-64 names) stay 1: ntlibc has both, for real.
#   HAVE_MALLOC_H / HAVE_STDIO_EXT_H / HAVE_X86_SHA1_HW_SUPPORT
#     (libiberty)   undef'd: no <malloc.h> or <stdio_ext.h> in ntlibc
#     (glibc-specific, and nothing here needs either), and the Linux host's
#     probe for hardware SHA1 instructions is a host CPU feature question,
#     not a target one.
#   HAVE_SBRK / HAVE_DECL_SBRK (libiberty)   undef'd: no brk()/sbrk() on
#     NT.  xmalloc.c's own comment already says as much ("Not used for
#     win32 ports other than cygwin32"); libiberty/config.h just had not
#     been told that for real.
#   HAVE_SPAWN_H / HAVE_POSIX_SPAWN / HAVE_POSIX_SPAWNP (libiberty)
#     undef'd: no <spawn.h> in ntlibc.  This is what sends pex-unix.c down
#     its fork()+exec() path instead -- see "pex-win32 vs pex-unix" below.
#   HAVE_BYTESWAP_H and its HAVE_DECL_BSWAP_* (libsframe, via
#     libctf/swap.h)   undef'd: no <byteswap.h>; swap.h's own portable
#     bswap_16/32/64 fallbacks (shift-and-mask, no library call) are what
#     actually get used, on every platform that lacks glibc's header.
#
# ---------------------------------------------------------------------------
# pex-win32.c vs pex-unix.c
#
# libiberty ships both: pex-win32.c against real Win32 CreateProcess-family
# APIs (via <windows.h>), pex-win32.c's job pex-unix.c does with
# fork()/vfork()/execvp().  ntlibc is not a port of the Win32 process APIs --
# it is a POSIX layer over NT, with a real fork() (see
# [[fork-cloexec-handle-bug]] for a bug already found and worked around
# elsewhere in this chain) -- so pex-unix.c is the one that actually matches
# what ntlibc offers, and it compiles clean against ntlibc's real fcntl.h/
# unistd.h once HAVE_SPAWN_H is off (above).  pex-win32.c would need
# <windows.h>, which windows.patch already establishes this chain does not
# have and does not want (see its header).  Nothing here calls libiberty's
# pexecute machinery at all -- ar/ranlib/nm/objcopy spawn no children -- so
# this is dead code either way, and pex-unix.c is simply the honest choice
# of dead code to carry.
#
# ---------------------------------------------------------------------------
# The FNM_CASEFOLD shim
#
# libiberty/fnmatch.c (glibc's own GNU fnmatch, built unconditionally by
# libiberty's own Makefile whether or not the host has a working fnmatch)
# uses FNM_CASEFOLD, a GNU extension no POSIX fnmatch.h -- ntlibc's
# included -- declares.  shim/fnmatch.h is byte-for-byte
# ../findutils/shim/fnmatch.h: the same problem, the same fix, already
# reviewed once for that package.  See that file's own header for why the
# bit values are safe to reuse (they agree with ntlibc's for the three
# POSIX flags, checked) and why compiling libiberty/fnmatch.c rather than
# patching ntlibc is the right call (a named object beats an archive
# member; ntlibc's own fnmatch.o, in libc.a, is never pulled into the
# link).  ar/ranlib/nm/objcopy do not call fnmatch themselves -- it is only
# here because libiberty's Makefile builds it unconditionally as part of
# REQUIRED_OFILES, and that file has to compile to be archived.
{
  derivationWithMeta,
  stage0,
  tinycc,
  ntlibc,
  gnupatch,
  gnutar,
  callPackage,
}:
let
  pname = "binutils";
  version = "2.46.0";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../ntlibc/bootstrap-sources.nix { };
in
derivationWithMeta {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://ftp.gnu.org/gnu/binutils/binutils-${version}.tar.xz";
    sha256 = "d75a94f4d73e7a4086f7513e67e439e8fcdcbb726ffe63f4661744e6256b2cf2";
  };

  tcc = tinycc.boot.tcc;
  patch = "${gnupatch}/bin/patch.exe";
  tar = "${gnutar}/bin/tar.exe";

  # Both halves of ntlibc: the built libraries, and the source tree its
  # headers live in -- only bits/alltypes.h is generated, and that one is
  # in the output beside the libraries. See the ntlibc package.
  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  windowsPatch = ./windows.patch;
  shimFnmatch = ./shim/fnmatch.h;
  ntRpathC = ./nt-rpath.c;

  # See "What generated/ actually is" above.
  genBfdH = ./generated/bfd.h;
  genBfdverH = ./generated/bfdver.h;
  genElf32TargetH = ./generated/elf32-target.h;
  genElf64TargetH = ./generated/elf64-target.h;
  genTargmatchH = ./generated/targmatch.h;
  genPeigenC = ./generated/peigen.c;
  genBfdConfigH = ./generated/bfd-config.h;
  genLibibertyConfigH = ./generated/libiberty-config.h;
  genBinutilsConfigH = ./generated/binutils-config.h;
  genLibsframeConfigH = ./generated/libsframe-config.h;

  # unxz's own doubling bug (see build.kaem) needs catm; the doubled output
  # is then unpacked by real tar, not mescc-tools-extra's untar -- binutils'
  # tarball has several symlinks whose target does not fit in untar's own
  # header field, the same reason the Linux recipe uses GNU tar here too.
  bin_catm = stage0.mescc-tools-extra.catm;
  bin_unxz = stage0.mescc-tools-extra.unxz;
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
    description = "Tools for manipulating binaries (ar, ranlib, nm, objcopy)";
    homepage = "https://www.gnu.org/software/binutils";
    license = "gpl3Plus";
    inherit platforms;
  };
}
