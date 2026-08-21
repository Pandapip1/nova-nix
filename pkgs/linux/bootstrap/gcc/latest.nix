# GCC 15.3.0, compiled by GCC 10.4.0.
#
# The end of the ladder: a current compiler, every byte behind it traced to
# the 181-byte hex0 seed.  It takes three gccs to get here because each is
# written in a language only the one below it can compile -- 4.6 in C for tcc,
# 4.6's g++ for gcc 10, and gcc 10 for this one.
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
  version = "15.3.0";

  gmpVersion = "6.3.0";
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
    sha256 = "fa59c1beef8995f27c4d71c1df227587189315d3e6faff1bb4306e61b0c530eb";
  };

  gmpTarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/gmp/gmp-${gmpVersion}.tar.xz";
    sha256 = "a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898";
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

  muslInclude = "${musl}/include";
  muslLib = "${musl}/lib";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./latest-build.sh
  ];

  meta = {
    description = "GNU Compiler Collection, version ${version}";
    homepage = "https://gcc.gnu.org";
    license = "gpl3Plus";
    inherit platforms;
  };
}
