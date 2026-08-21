# GNU tar 1.12, compiled by tcc.
#
# The first package in the bootstrap built by running its own ./configure,
# which is what bash was built for.  1.12 because 1.13 and later want more of
# a C library than Mes provides.
{
  derivationWithMeta,
  system,
  platforms,
  stage0,
  tinycc,
  gnumake,
  gnused,
  gnugrep,
  bash,
  coreutils,
  mesInclude,
}:
let
  pname = "gnutar";
  version = "1.12";

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/tar/tar-${version}.tar.gz";
    sha256 = "c6c37e888b136ccefab903c51149f4b7bd659d69d4aea21245f61053a57aa60a";
  };

  # A configure script looks tools up by bare name, so this is what it may
  # find -- the bootstrap's own, and not the host's.
  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${tinycc.compiler}/bin"
    "${bash}/bin"
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
    description = "GNU implementation of the tar archiver";
    homepage = "https://www.gnu.org/software/tar";
    license = "gpl3Plus";
    inherit platforms;
  };
}
