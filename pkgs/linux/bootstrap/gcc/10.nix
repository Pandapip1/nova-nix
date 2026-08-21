# GCC 10.4.0, compiled by GCC 4.6.4 with C++.
#
# The first gcc here written in C++ rather than C, which is why 4.6 had to
# grow a g++ first.  10.4.0 rather than 10.5.0: 10.5 does not build with a
# compiler this old (gcc bug 110716).
#
# Its gmp, mpfr and mpc are newer than 4.6's -- 6.2.1 is the last gmp that
# 4.6 can still compile -- so they are pinned here rather than in sources.nix.
{
  derivationWithMeta,
  system,
  platforms,
  gcc,
  musl,
  binutils,
  gnumake,
  gnused,
  gnugrep,
  gnutar,
  gzip,
  gawk,
  diffutils,
  findutils,
  bash,
  coreutils,
  stage0,
}:
let
  pname = "gcc";
  version = "10.4.0";

  # The last gmp that gcc 4.6 can compile.
  gmpVersion = "6.2.1";
  mpfrVersion = "4.2.2";
  mpcVersion = "1.4.1";

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit
    pname
    version
    system
    gmpVersion
    mpfrVersion
    mpcVersion
    ;

  coreTarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/gcc/gcc-${version}/gcc-${version}.tar.xz";
    sha256 = "c9297d5bcd7cb43f3dfc2fed5389e948c9312fd962ef6a4ce455cff963ebe4f1";
  };

  gmpTarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/gmp/gmp-${gmpVersion}.tar.xz";
    sha256 = "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2";
  };

  mpfrTarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/mpfr/mpfr-${mpfrVersion}.tar.xz";
    sha256 = "b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01";
  };

  mpcTarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/mpc/mpc-${mpcVersion}.tar.xz";
    sha256 = "91204cd32f164bd3b7c992d4a6a8ce6519511aadab30f78b6982d0bf8d73e931";
  };

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnutar}/bin"
    "${gzip}/bin"
    "${gawk}/bin"
    "${diffutils}/bin"
    "${findutils}/bin"
    "${binutils}/bin"
    "${gcc}/bin"
    "${bash}/bin"
    "${stage0.mescc-tools-extra.bin}/bin"
  ];

  musl = "${musl}";
  muslInclude = "${musl}/include";
  muslLib = "${musl}/lib";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./10-build.sh
  ];

  meta = {
    description = "GNU Compiler Collection, version ${version}";
    homepage = "https://gcc.gnu.org";
    license = "gpl3Plus";
    inherit platforms;
  };
}
