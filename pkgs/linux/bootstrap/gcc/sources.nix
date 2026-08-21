# The gcc source, and the three arbitrary-precision libraries its build wants
# in tree, shared by every build of it.
#
# gmp, mpfr and mpc are unpacked into the source tree because that is where
# gcc's build looks for them when there is no system copy.
{ }:
let
  version = "4.6.4";

  gmpVersion = "4.3.2";
  mpfrVersion = "2.4.2";
  mpcVersion = "1.0.3";

  fetchurl = import <nix/fetchurl.nix>;
in
{
  inherit
    version
    gmpVersion
    mpfrVersion
    mpcVersion
    ;

  coreTarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/gcc/gcc-${version}/gcc-core-${version}.tar.gz";
    sha256 = "e534a5cb05ab839d7cf7b2496fd5df42e76352926c1cf0d94de76184c26a739c";
  };

  cxxTarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/gcc/gcc-${version}/gcc-g++-${version}.tar.gz";
    sha256 = "690a5d4f664180640db28079e3461468192c484c37d6f671dde4b53a7f9918bb";
  };

  gmpTarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/gmp/gmp-${gmpVersion}.tar.gz";
    sha256 = "7be3ad1641b99b17f6a8be6a976f1f954e997c41e919ad7e0c418fe848c13c97";
  };

  mpfrTarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/mpfr/mpfr-${mpfrVersion}.tar.gz";
    sha256 = "246d7e184048b1fc48d3696dd302c9774e24e921204221540745e5464022b637";
  };

  mpcTarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/mpc/mpc-${mpcVersion}.tar.gz";
    sha256 = "617decc6ea09889fb08ede330917a00b16809b8db88c29c31bfbb49cbf88ecc3";
  };
}
