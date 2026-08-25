# Same tarballs, same versions, same sha256s as ../../../linux/bootstrap/gcc:
# this is not a different gcc, just a different host/libc for the same
# 4.6.4 release (still the newest gcc tcc can itself compile) and the same
# in-tree gmp/mpfr/mpc gcc's own build expects when there is no system copy.
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
