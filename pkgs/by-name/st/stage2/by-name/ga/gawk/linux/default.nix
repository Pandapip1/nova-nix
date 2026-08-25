# GNU awk 5.3.2, compiled by tcc against musl.
#
# The awk everything above the C library uses.  3.0.6 (mes.nix) is the one the
# Mes C library can build, and it is here only to build this one: a modern
# config.status writes a subs.awk with line continuations that 3.0.6 rejects,
# so anything configured from here on needs the newer awk.
{
  derivationWithMeta,
  system,
  platforms,
  tinycc,
  gnumake,
  gnused,
  gnugrep,
  gnutar,
  gzip,
  bash,
  coreutils,
  bootGawk,
}:
let
  pname = "gawk";
  version = "5.3.2";

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/gawk/gawk-${version}.tar.gz";
    sha256 = "8639a1a88fb411a1be02663739d03e902a6d313b5c6fe024d0bfeb3341a19a11";
  };

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnutar}/bin"
    "${gzip}/bin"
    "${bootGawk}/bin"
    "${tinycc}/bin"
    "${bash}/bin"
  ];

  CC = "${tinycc}/bin/tcc -static -B ${tinycc}/lib";
  AR = "${tinycc}/bin/tcc -ar";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./build.sh
  ];

  meta = {
    description = "GNU implementation of the AWK programming language";
    homepage = "https://www.gnu.org/software/gawk";
    license = "gpl3Plus";
    inherit platforms;
  };
}
