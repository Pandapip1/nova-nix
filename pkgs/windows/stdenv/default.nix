# nova-nix stage-1 stdenv, on this chain's own from-scratch toolchain -- no
# binary seeds.  bootstrap/gcc's gcc.exe/cc1.exe as the compiler,
# bootstrap/binutils' ar.exe/ranlib.exe/nm.exe/objcopy.exe as the archiver,
# bootstrap/bash's bash.exe as the builder, bootstrap/coreutils and its
# GNU-userland siblings (gnused, gnugrep, gawk5, findutils, diffutils,
# gnumake, gnupatch, gzip, gnutar) as the tools every ./configure and
# Makefile above here assumes, and bootstrap/tinycc's own tcc as the thing
# that actually assembles and links -- see cc-wrapper.sh for why.
#
# system = "x86-windows": this chain emits 32-bit PE32, a real architecture
# change from the old msys/mingw-seeded stdenv's x86_64-windows -- see
# ../bootstrap/stage0-pe32/platforms.nix, which is where "x86-windows" is
# first defined and where every earlier package on this side of the tree
# already gets its own `system` from.
#
# Two real, load-bearing gaps in bootstrap/gcc's own gcc.exe, both
# documented at length in ../bootstrap/gcc/build.kaem's own tail (the
# hello2.s/hello3.s functional tests and the comment above them) --
# neither is a guess, both were found by driving the real binary:
#
#   1. `gcc.exe -c foo.c -o foo.o` is broken -- libiberty's own
#      make_temp_file()/mkstemps() is handed a real Windows-notation temp
#      path and the file is never actually created there, even though an
#      isolated fopen() against the identical path succeeds every time.
#      Root cause unknown, reported to the ntlibc-owning peer session as a
#      possible ntlibc bug, not fixed there or here. The only proven path
#      is `-S` (cc1 emits assembly directly, no driver-managed temp file).
#   2. Full driver-mediated linking (gcc.exe spawning its own idea of `ld`)
#      has never been attempted -- explicitly out of scope in
#      ../bootstrap/gcc/default.nix's own "what this package does NOT
#      attempt" section. What IS proven, end to end, by that package's own
#      functional test, is: cc1.exe (or gcc.exe -S) to a .s file, then this
#      chain's own tcc assembling and linking that .s directly against
#      ntlibc's crt1.o/libc.a, with -lntdll for the syscall surface.
#
# cc-wrapper.sh is the shim that hides both gaps from everything above it:
# a `-c` invocation becomes `gcc.exe ... -S` followed by `tcc -c` on the
# resulting assembly (tcc's own -c, proven fine -- the bug is specifically
# in gcc's own driver-managed temp-file dance for the .s intermediate, not
# in tcc, per ../bootstrap/gcc/build.kaem's own reasoning for installing
# tcc as "as.exe"), and any real link -- `-c`-then-link or a bare
# `gcc.exe foo.c -o foo.exe` -- is done by invoking tcc directly for the
# final link (the one proven-working recipe: -nostdlib, ntlibc's own
# crt1.o, -L ntlibc/lib -lc -lntdll, mirroring ../bootstrap/gcc/build.kaem's
# own hello.exe link line exactly), never through gcc.exe's own unverified
# link mode.
{
  gcc,
  binutils,
  bash,
  coreutils,
  gnused,
  gnugrep,
  gawk5,
  findutils,
  diffutils,
  gnumake,
  gnupatch,
  gzip,
  gnutar,
  tinycc,
  ntlibc,
  stage0,
  callPackage,
}:
let
  setup = ./setup.sh;
  ccWrapper = ./cc-wrapper.sh;
  tcc = tinycc.boot.tcc;
  ntlibcSrc = (callPackage ../bootstrap/ntlibc/bootstrap-sources.nix { }).src;
  # This package's own gcc/build.kaem installs cc1.exe/gcc.exe/as.exe under
  # this exec-prefix -- libgcc.a (the DImode helper subset build.kaem's own
  # "libgcc" section builds and archives, needed by any consumer whose own
  # codegen or cc1's own generated code wants 64-bit arithmetic) lives
  # alongside them.
  gccLibDir = "${gcc}/lib/gcc/i686-pc-pe/4.6.4";
in
{
  mkDerivation =
    attrs:
    derivation (
      attrs
      // {
        system = "x86-windows";
        builder = "${bash}/bin/bash.exe";
        args = [ "${setup}" ];

        # Toolchain and userland bin dirs, as canonical store paths -- this
        # chain's own bash/ntlibc accept these directly (no cygdrive-style
        # mapping: unlike the old MSYS2 seed, nothing in this chain is a
        # POSIX-emulation layer over Win32 paths, and every earlier
        # kaem-driven package already passes /nix/store paths straight
        # through to ntlibc-linked programs with no translation).
        gccBin = "${gcc}/bin";
        binutilsBin = "${binutils}/bin";
        # bash's own build.kaem installs sh.exe alongside bash.exe (a copy,
        # not a symlink -- see that package's build.kaem), the same way
        # gnutar's own userland aliases its bare name.  builder above already
        # names bash.exe by its full store path to launch this script, which
        # needs no PATH lookup -- but ./configure and every Makefile above
        # here invoke a bare "sh" of their own, so bash's bin dir has to be
        # on PATH too, same as every other tool below.
        bashBin = "${bash}/bin";
        coreutilsBin = "${coreutils}/bin";
        gnusedBin = "${gnused}/bin";
        gnugrepBin = "${gnugrep}/bin";
        gawk5Bin = "${gawk5}/bin";
        findutilsBin = "${findutils}/bin";
        diffutilsBin = "${diffutils}/bin";
        gnumakeBin = "${gnumake}/bin";
        gnupatchBin = "${gnupatch}/bin";
        gzipBin = "${gzip}/bin";
        gnutarBin = "${gnutar}/bin";
        # .tar.xz sources (findutils/diffutils/binutils/gcc's own tarballs all
        # needed one) have no decompressor anywhere in this chain's own
        # stage-1 userland -- gzip above is this chain's own from-source
        # build, but nothing built an xz. stage0's own mescc-tools-extra unxz
        # (bootstrap-only elsewhere in this tree, never before reached from a
        # stdenv-level mkDerivation) is the only one there is, and it carries
        # a real bug setup.sh's unpack phase has to work around the same way
        # every bootstrap .tar.xz already does -- see that phase's own
        # comment for what the bug is and why doubling the input fixes it.
        unxzBin = "${stage0.mescc-tools-extra.unxz}";

        # cc-wrapper.sh's own inputs: this chain's own tcc, and everything
        # it needs to reproduce the proven-working assemble+link recipe.
        NN_TCC = "${tcc}";
        NN_GCC = "${gcc}/bin";
        NN_GCC_LIBDIR = gccLibDir;
        NN_NTLIBC_LIB = "${ntlibc}/lib";
        NN_NTLIBC_INCLUDE = "${ntlibc}/include";
        NN_NTLIBC_SRC_INCLUDE = "${ntlibcSrc}/include";
        NN_NTLIBC_ARCH_I386 = "${ntlibcSrc}/arch/i386";
        NN_NTLIBC_ARCH_GENERIC = "${ntlibcSrc}/arch/generic";

        ccWrapperSrc = ccWrapper;
      }
    );
}
