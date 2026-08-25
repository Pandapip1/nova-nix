# GNU make, compiled by tcc against ntlibc.
#
# The first thing above the compiler and the C library, and what everything
# above it is built with: bash, coreutils, binutils and the rest all ship a
# Makefile and expect make to run it.  It is first because it is the only
# one of them that needs no shell to build -- kaem can drive this, and make
# drives the rest.
#
# The tarball rather than the git tree: make's release carries the gnulib
# imports (glob, fnmatch, alloca) and the autotools-generated headers, and
# the git tree carries neither.  From mirrors.kernel.org because ftp.gnu.org
# does not answer here.
{
  stdenv,
  stage0,
  tinycc,
  ntlibc,
  callPackage,
}:
let
  pname = "gnumake";
  version = "4.4.1";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../../../nt/ntlibc/bootstrap-sources.nix { };
in
stdenv.mkDerivation {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://mirrors.kernel.org/gnu/make/make-${version}.tar.gz";
    sha256 = "dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3";
  };

  tcc = tinycc.boot.tcc;

  # Both halves of ntlibc: the built libraries, and the source tree its
  # headers live in.  Only bits/alltypes.h is generated, and that one is in
  # the output beside the libraries -- see the ntlibc package.
  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  # The one patch this build still needs, as a replace: kaem splits a quoted
  # string on spaces, so both the pattern and the replacement arrive as
  # variables rather than written into the script.
  shellAbs = "\"/bin/sh\"";
  shellRel = "\"sh\"";

  bin_ungz = stage0.mescc-tools-extra.ungz;
  bin_untar = stage0.mescc-tools-extra.untar;
  bin_catm = stage0.mescc-tools-extra.catm;
  bin_cp = stage0.mescc-tools-extra.cp;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;
  bin_replace = stage0.mescc-tools-extra.replace;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "A tool which controls the generation of executables";
    homepage = "https://www.gnu.org/software/make";
    license = "gpl3Plus";
    inherit platforms;
  };
}
