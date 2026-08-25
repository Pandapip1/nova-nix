# GNU grep 2.4, compiled by tcc.
#
# Old enough to need no patches against this C library.  The makefile is
# carried beside this file rather than fetched: grep's own comes from a
# configure that cannot run here, and nixpkgs' minimal bootstrap wrote a plain
# one.
{
  derivationWithMeta,
  system,
  platforms,
  stage0,
  tinycc,
  gnumake,
  bash,
  coreutils,
  mesInclude,
}:
let
  pname = "gnugrep";
  version = "2.4";

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/grep/grep-${version}.tar.gz";
    sha256 = "a32032bab36208509466654df12f507600dfe0313feebbcd218c32a70bf72a16";
  };

  makefile = ./main.mk;

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${tinycc.compiler}/bin"
    "${stage0.mescc-tools-extra.bin}/bin"
  ];

  CC = "${tinycc.compiler}/bin/tcc -static -B ${tinycc.libs}/lib -I ${mesInclude}";
  AR = "${tinycc.compiler}/bin/tcc -ar";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./build.sh
  ];

  meta = {
    description = "GNU implementation of the Unix grep command";
    homepage = "https://www.gnu.org/software/grep";
    license = "gpl3Plus";
    inherit platforms;
  };
}
