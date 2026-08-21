# The Linux package set.
#
# Layout follows the Windows set, which follows nixpkgs:
#
#   bootstrap/stage0-posix/               the full-source bootstrap chain, as
#                                         its own scope
#
# What is not Linux-specific lives one level up and is shared with the other
# package sets: ../lib.nix and ../build-support/.
#
# There is no by-name/ yet: this set is the bootstrap and nothing above it.
let
  lib = import ../lib.nix;

  newScope = extra: lib.callPackageWith (self // extra);
  callPackage = newScope { };

  # The tcc built on the Mes C library comes as a compiler and a directory of
  # libraries built separately from it; the tcc built on musl is one path that
  # is both.  Packages that take either are written against the two-part
  # shape, so this presents the second the same way rather than teaching each
  # of them about the difference.
  muslToolchain = drv: drv // {
    compiler = drv;
    libs = drv;
    inherit (self.tinycc) mainlineSrc version;
  };

  self = {
    inherit lib newScope callPackage;

    derivationWithMeta = callPackage ../build-support/derivation-with-meta/package.nix { };

    # The bootstrap is a scope of its own, so the names of its intermediate
    # links (hex2-0, M0.hex2, M1-macro-1.M1) stay inside it.
    stage0 = callPackage ./bootstrap/stage0-posix { };

    # The stage above it, built by the compiler, assembler and linker stage0
    # ends with.  Its own intermediates (mes.M1, mes.hex2) stay inside it too.
    mes = callPackage ./bootstrap/mes { };

    # Not a stage: the parser modules MesCC loads, which Mes does not vendor.
    # Shared with the Windows set -- it is pure Scheme, and says nothing about
    # the platform MesCC runs on or compiles for.
    nyacc = callPackage ../bootstrap/nyacc { };

    # The first C compiler here that implements enough of C to build a system,
    # and the first that can compile itself.
    tinycc = callPackage ./bootstrap/tinycc { };

    # How a release tarball becomes a source tree, using the unpackers this
    # bootstrap built rather than nova-nix's builtin:unpack.
    unpackTarball = callPackage ./bootstrap/unpack.nix {
      inherit (self.stage0) system platforms;
    };

    # The first program here that is not part of a compiler.  Everything
    # above needs it: their sources are patched before they will build.
    gnupatch = callPackage ./bootstrap/gnupatch {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc.boot;
      mesInclude = "${self.mes.src}/include";
    };

    # What everything above is built with: they ship Makefiles.
    gnumake = callPackage ./bootstrap/gnumake {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc.boot;
      mesInclude = "${self.mes.src}/include";
    };

    # The programs every build script above assumes exist.
    coreutils = callPackage ./bootstrap/coreutils {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc.boot;
      mesInclude = "${self.mes.src}/include";
    };

    # The first real shell: everything above is built by ./configure scripts,
    # which kaem cannot run.
    bash = callPackage ./bootstrap/bash {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc.boot;
      mesInclude = "${self.mes.src}/include";
    };

    # The first package built by a shell script rather than a kaem file.
    gnused = callPackage ./bootstrap/gnused {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc.boot;
      mesInclude = "${self.mes.src}/include";
    };

    # The same sed against musl, because the Mes C library's stdio gets getc
    # and ungetc on a pipe wrong and every modern config.status depends on
    # them agreeing.  See bootstrap/gnused/musl.nix.
    gnused-musl = callPackage ./bootstrap/gnused/musl.nix {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc-musl;
    };

    gnugrep = callPackage ./bootstrap/gnugrep {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc.boot;
      mesInclude = "${self.mes.src}/include";
    };

    # The first package built by running its own ./configure.
    gnutar = callPackage ./bootstrap/gnutar {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc.boot;
      mesInclude = "${self.mes.src}/include";
    };

    gzip = callPackage ./bootstrap/gzip {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc.boot;
      mesInclude = "${self.mes.src}/include";
    };

    # Every autotools configure script uses awk.
    # 3.0.6, the newest awk the Mes C library can build.  It exists to build
    # the one below.
    gawk-mes = callPackage ./bootstrap/gawk/mes.nix {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc.boot;
      mesInclude = "${self.mes.src}/include";
    };

    # The awk everything from here up uses.
    gawk = callPackage ./bootstrap/gawk {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc-musl;
      gnused = self.gnused-musl;
      bootGawk = self.gawk-mes;
    };

    # The same tar against musl, which restores modification times where the
    # one below it does not.  See bootstrap/gnutar/musl.nix.
    gnutar-musl = callPackage ./bootstrap/gnutar/musl.nix {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc-musl;
      gnused = self.gnused-musl;
    };

    # The full coreutils, which the 5.0 below is not: live-bootstrap's
    # makefile names the 62 programs it compiles, and env, uname, date and
    # stat are not among them.
    coreutils-musl = callPackage ./bootstrap/coreutils/musl.nix {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc-musl;
      gnused = self.gnused-musl;
      gnutar = self.gnutar-musl;
    };

    # The same gcc with C++, built by the one above: every gcc after 4.7 is
    # written in C++ and needs a C++ compiler to build at all.
    gcc-cxx = callPackage ./bootstrap/gcc/cxx.nix {
      inherit (self.stage0) system platforms;
      gcc = self.gcc;
      musl = self.musl-gcc;
      gnused = self.gnused-musl;
      gnutar = self.gnutar-musl;
      coreutils = self.coreutils-musl;
    };

    # The first gcc here written in C++, built by the g++ above it.
    gcc10 = callPackage ./bootstrap/gcc/10.nix {
      inherit (self.stage0) system platforms;
      gcc = self.gcc-cxx;
      musl = self.musl-gcc;
      gnused = self.gnused-musl;
      gnutar = self.gnutar-musl;
      coreutils = self.coreutils-musl;
    };

    # musl again, this time built by gcc: everything tcc could not assemble,
    # plus a shared library, a dynamic loader and the musl-gcc wrapper that
    # the compilers above link against.
    musl-gcc = callPackage ./bootstrap/musl/gcc.nix {
      inherit (self.stage0) system platforms;
      gcc = self.gcc;
      gnused = self.gnused-musl;
      gnutar = self.gnutar-musl;
      coreutils = self.coreutils-musl;
    };

    # The last link in the chain: a real C compiler.
    gcc = callPackage ./bootstrap/gcc {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc-musl;
      gnused = self.gnused-musl;
      gnutar = self.gnutar-musl;
      coreutils = self.coreutils-musl;
    };

    # find and xargs, which gcc's build runs.
    findutils = callPackage ./bootstrap/findutils {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc-musl;
      gnused = self.gnused-musl;
      gnutar = self.gnutar-musl;
      coreutils = self.coreutils-musl;
    };

    # The assembler and linker gcc needs.
    binutils = callPackage ./bootstrap/binutils {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc-musl;
      gnused = self.gnused-musl;
      gnutar = self.gnutar-musl;
      coreutils = self.coreutils-musl;
    };

    # Compiled against musl: 3.8 needs socklen_t, which the Mes C library
    # does not have.
    diffutils = callPackage ./bootstrap/diffutils {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc-musl;
      gnused = self.gnused-musl;
      coreutils = self.coreutils-musl;
    };

    # The C library that replaces Mes's, and the compiler on top of it.  Both
    # are built twice, because the first musl is compiled by the tcc that
    # still stands on the Mes C library and that tcc miscompiles musl's
    # vfprintf: every %e/%f/%g prints zero however correct the arithmetic
    # behind it was.  Compiling musl again with the tcc that the first musl
    # produced fixes it, which is the same argument as tcc's own second round
    # -- a compiler that compiled itself is one whose output has been checked
    # by the thing it produced.
    musl-intermediate = callPackage ./bootstrap/musl {
      inherit (self.stage0) system platforms;
      tinycc = self.tinycc.boot;
    };

    tinycc-musl-intermediate = callPackage ./bootstrap/tinycc-musl {
      inherit (self.stage0) system platforms;
      musl = self.musl-intermediate;
      tinycc = self.tinycc.boot // {
        inherit (self.tinycc) mainlineSrc version;
      };
    };

    # The C library everything above links against.
    musl = callPackage ./bootstrap/musl {
      inherit (self.stage0) system platforms;
      tinycc = muslToolchain self.tinycc-musl-intermediate;
    };

    # ... and the compiler everything above uses.
    tinycc-musl = callPackage ./bootstrap/tinycc-musl {
      inherit (self.stage0) system platforms;
      tinycc = muslToolchain self.tinycc-musl-intermediate;
    };
  };
in
self
