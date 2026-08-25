# GNU tar 1.12, compiled by tcc against musl.
#
# The same source and version as default.nix; what the C library buys is
# modification times.  Built against Mes's, tar restores none of them, so an
# unpacked tree lands with the extraction time in extraction order -- and make
# then reads a distributed aclocal.m4 as older than the configure.ac beside it
# and tries to run an aclocal that is not in this bootstrap.
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
}:
let
  pname = "gnutar-musl";

  sources = import ./sources.nix { };
  inherit (sources) version;
in
derivationWithMeta {
  inherit pname version system;

  tarball = sources.src;

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnutar}/bin"
    "${gzip}/bin"
    "${tinycc}/bin"
    "${bash}/bin"
  ];

  CC = "${tinycc}/bin/tcc -B ${tinycc}/lib";
  AR = "${tinycc}/bin/tcc -ar";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./musl-build.sh
  ];

  meta = {
    description = "GNU implementation of the tar archiver, linked against musl";
    homepage = "https://www.gnu.org/software/tar";
    license = "gpl3Plus";
    inherit platforms;
  };
}
