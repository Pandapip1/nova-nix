# The Windows package set.
#
# Layout follows nixpkgs:
#
#   by-name/<shard>/<pname>/package.nix   one package per directory, shard =
#                                         the first two characters of <pname>
#   bootstrap/stage0-pe32/                the full-source bootstrap chain, as
#                                         its own scope
#   bootstrap/                            the sha256-pinned MSYS2 seeds
#   stdenv/                               mkDerivation, setup.sh, cc-wrapper.sh
#
# What is not Windows-specific lives one level up and is shared with the other
# package sets: ../lib.nix and ../build-support/.
#
# The set is a fixpoint: callPackage reads each package.nix's formal parameters
# and supplies them from the set being defined, so a package names its
# dependencies -- { stdenv, zlib }: ... -- rather than reaching across the tree
# with a relative import.  Nothing enumerates by-name packages; adding one is
# adding a directory.
let
  lib = import ../lib.nix;

  # The scope constructor, as nixpkgs spells it: newScope layers extra
  # arguments over the set, and callPackage is that with nothing extra.  A
  # nested scope (the bootstrap) is given newScope so it can layer itself on
  # in turn.
  newScope = extra: lib.callPackageWith (self // extra);
  callPackage = newScope { };

  # by-name is sharded to keep any one directory small, so the two levels are
  # walked here: the shard is a storage detail and must not show up as an
  # attribute.
  byName =
    let
      root = ./by-name;
      inShard =
        shard:
        map (pname: {
          name = pname;
          value = callPackage (root + "/${shard}/${pname}/package.nix") { };
        }) (builtins.attrNames (builtins.readDir (root + "/${shard}")));
    in
    builtins.listToAttrs (builtins.concatMap inShard (builtins.attrNames (builtins.readDir root)));

  self = byName // {
    inherit lib newScope callPackage;

    stdenv = import ./stdenv {
      inherit (self)
        gcc
        binutils
        bash
        coreutils
        gnused
        gnugrep
        gawk5
        findutils
        diffutils
        gnumake
        gnupatch
        gzip
        gnutar
        tinycc
        ntlibc
        stage0
        callPackage
        ;
    };

    # build-support entries are named here rather than discovered, as nixpkgs
    # does in all-packages.nix: they are ways of building things, not packages.
    derivationWithMeta = callPackage ../build-support/derivation-with-meta/package.nix { };

    fetchurl = import <nix/fetchurl.nix>;

    # The bootstrap is a scope of its own, so the names of its intermediate
    # links (hex1, catm, M0.hex2) stay inside it.
    stage0 = callPackage ./bootstrap/stage0-pe32 { };

    # The stage above it, built by the compiler, assembler and linker stage0
    # ends with.  Its own intermediates (mes.M1, mes.hex2) stay inside it too.
    mes = callPackage ./bootstrap/mes { };

    # Not a stage: the parser modules MesCC loads, which Mes does not vendor.
    nyacc = callPackage ../bootstrap/nyacc { };

    # The C library everything above tcc is built against -- this side's
    # musl, where Mes's own is only what the chain climbs on.  See its
    # default.nix for the difference that matters.
    ntlibc = callPackage ./bootstrap/ntlibc { };

    # The first program above the compiler and the C library, and what
    # everything above it is built with.
    gnumake = callPackage ./bootstrap/gnumake { };

    # And the second: what the packages above them are patched with, since
    # a release tarball is not hermetic as it stands.
    gnupatch = callPackage ./bootstrap/gnupatch { };

    # And the shell every ./configure above here is written in.  kaem got
    # the chain this far, and kaem has no loops, conditionals or pipelines.
    bash = callPackage ./bootstrap/bash { };

    # The programs every build script above here assumes -- cp, mv, rm,
    # mkdir, cat, ls, sort.  The first package on this side that make drives
    # rather than kaem.
    coreutils = callPackage ./bootstrap/coreutils { };

    # The stream editor every ./configure above here runs on its own output.
    # One build, not two: the Linux side needs a second sed against musl
    # because Mes's stdio mishandles a pipe, and ntlibc's does not.
    gnused = callPackage ./bootstrap/gnused { };

    # And the pattern matcher every ./configure above here runs a hundred
    # times.  Its own regex, since ntlibc has none.
    gnugrep = callPackage ./bootstrap/gnugrep { };

    # And the decompressor, so a release tarball above here is opened by a
    # program this bootstrap built rather than by the unpacker
    # mescc-tools-extra supplied to get it started.
    gzip = callPackage ./bootstrap/gzip { };

    # And the archiver every source tarball above here arrives in.  The first
    # package on this side that has to answer for NT's filesystem rather than
    # for its C library: no symbolic links, no owner, and one read-only bit
    # where POSIX has nine mode bits.
    gnutar = callPackage ./bootstrap/gnutar { };

    # And the awk every ./configure above here runs from its first hundred
    # lines.  3.0.6 is the seed awk: old enough and small enough to build
    # with no awk in the picture, and its release tarball ships the
    # pre-generated parser, so it needs no bison either.
    gawk = callPackage ./bootstrap/gawk { };

    # And the awk everything above here actually uses.  The seed above is
    # what a modern config.status is too new for; this is the one it needs.
    # It is built with the seed rather than by it -- there is no configure
    # here to run an awk script -- so the edge to it is a declared input
    # that nothing in the build executes.  See its default.nix.
    gawk5 = callPackage ./bootstrap/gawk5 { bootGawk = self.gawk; };

    # And the directory walker binutils and gcc run over their own trees.
    # The first package on this side to carry a modern gnulib import, and so
    # the first to have to answer for gnulib's generated headers -- which it
    # does by not needing them.  See its default.nix.
    findutils = callPackage ./bootstrap/findutils { };

    # And the tool binutils' configure runs to check its own generated files
    # against what it expects, and that a patch-based build takes its patches
    # in.  The smallest gnulib import on this side yet, and the first where
    # that smallness -- not needing configure's generated headers -- turned
    # out to follow from the package's own age rather than from anything this
    # port did differently.  See its default.nix.
    diffutils = callPackage ./bootstrap/diffutils { };

    # The shared tinycc, told what it is targeting: 32-bit PE32 on x86, whose
    # Mes headers live under include/windows/x86.
    tinycc = callPackage ./bootstrap/tinycc { };

    # binutils' as, ld and dlltool, alongside ar, ranlib, nm and objcopy,
    # all below -- see ./bootstrap/binutils/
    # default.nix's "as/ld generated files" section for what that took
    # (genscripts.sh off-chain for ld's i386pe emulation glue and
    # ldscripts; nothing at all for as; bison was never actually needed).
    # What follows is settled, checked against a real as+ld link under
    # ntlibc rather than assumed: what target triple
    # binutils/ld should be configured with, given that this chain's libc
    # is ntlibc, not mingw's runtime.
    #
    # The obvious answer -- i686-pc-mingw32, since that is the nearest stock
    # config for a binutils this old -- was never checked against what it
    # actually asks a target to be. It does not. Read against binutils
    # 2.46.0 (the version pinned at ../linux/bootstrap/binutils, tarball
    # already fetched there):
    #
    #   - bfd/config.bfd's `i[3-7]86-*-mingw32* | *-cygwin* | *-winnt | *-pe)`
    #     stanza treats all four spellings identically: targ_defvec =
    #     i386_pe_vec, same selvecs, same targ_underscore. "mingw32" carries
    #     no separate behaviour there -- it is one alternative among four
    #     that all mean "an i386 PE/COFF object", "pe" being the plainest.
    #   - ld/configure.tgt and gas/configure.tgt agree: `i[3-7]86-*-pe)` gets
    #     the identical targ_emul=i386pe / fmt=coff,em=pe that mingw32,
    #     cygwin and winnt get. Nothing i386pe-specific reads the OS field
    #     back out to ask "is this actually mingw"; the four names are
    #     synonyms at every selection point in bfd, gas and ld.
    #   - The only `#ifdef __MINGW32__` / `__CYGWIN__` code in bfd
    #     (bfd/peXXigen.c, bfd/pe-x86_64.c, bfd/bfdio.c) is guarded on the
    #     macro the *compiler building binutils* predefines when *binutils
    #     itself* is hosted on mingw/cygwin -- i.e. it is about what binutils
    #     runs on, not what it targets. Built here by tcc against ntlibc,
    #     that macro is simply never defined, and the branches are dead code.
    #   - `./config.sub i686-pc-pe` parses cleanly (binutils-2.46.0's own
    #     config.sub, checked directly), so nothing needs a made-up triple.
    #
    # So: use i686-pc-pe, not i686-pc-mingw32. Same bfd/ld/gas backend,
    # nothing lost, and it does not spell out a runtime ("mingw32") this
    # chain does not have and does not want autoconf scripts inferring
    # things from.
    #
    # What *is* a real interface question, not a naming one, and has to be
    # handled in the binutils and later gcc packages regardless of the
    # triple string chosen:
    #
    #   1. Entry point. GNU ld's PE emulation (ld/emultempl/pe.em,
    #      set_entry_point) defaults the entry symbol to "mainCRTStartup"
    #      (or "WinMainCRTStartup" for a few legacy subsystem versions).
    #      ntlibc's crt1.c defines the entry point as `_start`, and this
    #      chain's own tcc fork already agrees -- tccpe.c's PE linker names
    #      "_start" as the entry when linking -nostdlib (see the comment
    #      at ntlibc/crt/crt1.c:8). ld's default does not match either; any
    #      link against ntlibc's crt1.o needs an explicit `-e _start`
    #      (or `--entry _start`), unconditionally, independent of triple.
    #   2. Import libraries. ntlibc does not build a conventional import
    #      library -- it ships lib/ntdll.def, and this chain's tcc reads a
    #      .def directly as an input library (tccpe.c's pe_load_def), which
    #      is a tcc extension. GNU ld has no equivalent: ld/emultempl/pe.em
    #      only reads a .def file to learn what a DLL *being linked* should
    #      export (building an implib alongside a DLL you are creating), not
    #      to resolve imports *from* an existing DLL. The standard GNU
    #      toolchain answer is `dlltool -d lib/ntdll.def -l libntdll.a`, run
    #      once, to synthesize a real archive import library that `-lntdll`
    #      then resolves the ordinary way -- dlltool needs no live ntdll.dll
    #      to do this, only the .def. This has to happen somewhere in the
    #      binutils (or ntlibc-consuming) package; it is not automatic.
    #   3. Delay-import directory (PE directory entry 13). ntlibc's own
    #      delay-load mechanism (include/ntlibc/delayload.h) deliberately
    #      leaves this directory unpopulated -- tcc's linker cannot write it
    #      and nothing currently reads it. GNU ld does not populate it
    #      either for an ordinary link; the machinery that does
    #      (bfd/peXXigen.c's PE_DELAY_IMPORT_DESCRIPTOR handling, dlltool's
    #      `--delay`/`-y`, the `__delayLoadHelper2` MSVC convention) is only
    #      exercised if dlltool is explicitly asked to build a delay-import
    #      stub library. As long as that flag is never used, ordinary
    #      dlltool-built import libraries leave entry 13 empty, which is
    #      exactly ntlibc's own convention -- not a conflict, but worth
    #      recording so nobody reaches for --delay by habit.
    #
    # Verified against binutils-2.46.0 source directly (config.sub,
    # bfd/config.bfd, ld/configure.tgt, gas/configure.tgt,
    # ld/emultempl/pe.em, bfd/peXXigen.c, binutils/dlltool.c) and against
    # ntlibc's crt/crt1.c, lib/ntdll.def and include/ntlibc/delayload.h --
    # not from memory of how mingw toolchains usually work elsewhere.
    #
    # ar, ranlib, nm, objcopy, as, ld, dlltool: see its default.nix.
    binutils = callPackage ./bootstrap/binutils { };

    # The last package in this chain's full-source bootstrap: cc1.exe and
    # gcc.exe, compiled and linked entirely by this chain's own tcc against
    # ntlibc. See its default.nix.
    gcc = callPackage ./bootstrap/gcc { };
  };
in
self
