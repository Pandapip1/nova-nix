# GNU awk 3.0.6, compiled by tcc.
#
# Every autotools configure script uses awk, so nothing further up can be
# configured without one.  awk is a copy of gawk rather than a symlink, for
# the same reason sh is a copy of bash: a store path is read-only by the time
# anything would follow it.
{
  derivationWithMeta,
  system,
  platforms,
  tinycc,
  gnumake,
  gnupatch,
  gnused,
  gnugrep,
  bash,
  coreutils,
  stage0,
  mesInclude,
}:
let
  pname = "gawk";
  version = "3.0.6";

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/gawk/gawk-${version}.tar.gz";
    sha256 = "abf276e10c7b871332d07bf2b652133a27419677d157383097bbd153e58a8bfc";
  };

  noStampPatch = ./no-stamp.patch;

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnupatch}/bin"
    "${tinycc.compiler}/bin"
    "${bash}/bin"
    "${stage0.mescc-tools-extra.bin}/bin"
  ];

  CC = "${tinycc.compiler}/bin/tcc -static -B ${tinycc.libs}/lib -I ${mesInclude}";
  AR = "${tinycc.compiler}/bin/tcc -ar";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./mes-build.sh
  ];

  meta = {
    description = "GNU implementation of the AWK programming language";
    homepage = "https://www.gnu.org/software/gawk";
    license = "gpl3Plus";
    inherit platforms;
  };
}
