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
  };
in
self
