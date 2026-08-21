# GNU tar 1.35, compiled by gcc against musl.
#
# 1.12 carried the bootstrap from the mescc-tools unpackers as far as a real
# compiler, but it predates the pax extended headers a modern release tarball
# uses: gcc 15's stops it with "Unknown file type 'x'".  This is the tar that
# opens the sources above it.
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
  bash,
  coreutils,
}:
let
  pname = "gnutar";
  version = "1.35";

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/tar/tar-${version}.tar.gz";
    sha256 = "14d55e32063ea9526e057fbf35fcabd53378e769787eff7919c3755b02d2b57e";
  };

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnutar}/bin"
    "${gzip}/bin"
    "${gawk}/bin"
    "${binutils}/bin"
    "${musl}/bin"
    "${gcc}/bin"
    "${bash}/bin"
  ];

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./latest-build.sh
  ];

  meta = {
    description = "GNU implementation of the tar archiver";
    homepage = "https://www.gnu.org/software/tar";
    license = "gpl3Plus";
    inherit platforms;
  };
}
