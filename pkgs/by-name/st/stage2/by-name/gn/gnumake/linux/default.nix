# GNU make, compiled by tcc.
#
# The first thing above patch, and what everything above it is built with:
# coreutils, bash and the rest all ship a Makefile and expect make to run it.
{
  stdenv,
  system,
  platforms,
  stage0,
  tinycc,
  gnupatch,
  mesInclude,
}:
let
  pname = "gnumake";
  version = "4.4.1";
in
stdenv.mkDerivation {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://ftp.gnu.org/gnu/make/make-${version}.tar.gz";
    sha256 = "dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3";
  };

  tcc = "${tinycc.compiler}/bin/tcc";
  libs = tinycc.libs;
  mesinc = mesInclude;

  patch1 = ./0001-No-impure-bin-sh.patch;
  patch2 = ./0002-remove-impure-dirs.patch;
  patch3 = ./0003-tinycc-support.patch;

  bin_patch = "${gnupatch}/bin/patch";
  bin_ungz = stage0.mescc-tools-extra.ungz;
  bin_untar = stage0.mescc-tools-extra.untar;
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
    description = "A tool to control the generation of non-source files from sources";
    homepage = "https://www.gnu.org/software/make";
    license = "gpl3Plus";
    inherit platforms;
  };
}
