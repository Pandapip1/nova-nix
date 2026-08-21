# GNU patch, the first program in the bootstrap that is not part of a
# compiler.
#
# Everything above this needs it: the sources of make, coreutils, bash and
# the rest are all patched before they will build with this C library, and
# those patches are what live-bootstrap and nixpkgs' minimal bootstrap carry.
#
# Version 2.5.9 rather than anything newer, because 2.6 and later reach for
# gnulib pieces the Mes C library does not implement.
{
  derivationWithMeta,
  system,
  platforms,
  stage0,
  tinycc,
  unpackTarball,
  mesInclude,
}:
let
  pname = "gnupatch";
  version = "2.5.9";

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://ftp.gnu.org/gnu/patch/patch-${version}.tar.gz";
    sha256 = "ecb5c6469d732bcf01d6ec1afe9e64f1668caba5bfdb103c28d7f537ba3cdb8a";
  };

  src = unpackTarball {
    name = "${pname}-src";
    inherit version tarball;
  };
in
derivationWithMeta {
  inherit pname version system;

  srcdir = "${src}/patch-${version}";
  tcc = "${tinycc.compiler}/bin/tcc";
  libs = tinycc.libs;
  mesinc = mesInclude;

  bin_catm = stage0.mescc-tools-extra.catm;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;
  bin_cp = stage0.mescc-tools-extra.cp;
  bin_chmod = stage0.mescc-tools-extra.chmod;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "GNU Patch, a program to apply differences to files";
    homepage = "https://www.gnu.org/software/patch";
    license = "gpl3Plus";
    inherit platforms;
  };
}
