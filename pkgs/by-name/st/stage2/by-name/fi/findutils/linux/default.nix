# GNU findutils 4.10.0, compiled by tcc against musl.
#
# find and xargs.  gcc's build runs find, so this comes before it.
{
  stdenv,
  system,
  platforms,
  tinycc,
  gnumake,
  gnused,
  gnugrep,
  gnutar,
  gawk,
  bash,
  coreutils,
  stage0,
}:
let
  pname = "findutils";
  version = "4.10.0";

  fetchurl = import <nix/fetchurl.nix>;
in
stdenv.mkDerivation {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/findutils/findutils-${version}.tar.xz";
    sha256 = "1387e0b67ff247d2abde998f90dfbf70c1491391a59ddfecb8ae698789f0a4f5";
  };

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnutar}/bin"
    "${gawk}/bin"
    "${tinycc}/bin"
    "${bash}/bin"
    "${stage0.mescc-tools-extra.bin}/bin"
  ];

  CC = "${tinycc}/bin/tcc -B ${tinycc}/lib";
  AR = "${tinycc}/bin/tcc -ar";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./build.sh
  ];

  meta = {
    description = "GNU Find Utilities, the basic directory searching utilities";
    homepage = "https://www.gnu.org/software/findutils";
    license = "gpl3Plus";
    inherit platforms;
  };
}
