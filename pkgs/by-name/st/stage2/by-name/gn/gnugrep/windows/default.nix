# GNU grep 2.4, compiled by the tcc this chain built, against ntlibc.
#
# The PE32 counterpart of ../../../linux/bootstrap/gnugrep.  Same version and
# same tarball hash: 2.4 is the last grep that is a self-contained tree --
# eight C files, its own regex, its own dfa -- rather than a gnulib import
# whose replacement modules would collide with a real C library at every turn.
# From mirrors.kernel.org, since ftp.gnu.org does not answer here.
#
# No makefile is carried on this side.  The Linux build fetches (well, keeps)
# a hand-written main.mk because grep's own Makefile.in comes from a configure
# nothing here can run; but that makefile only names eight compiles and three
# links, and kaem can name those directly.  Doing so also keeps grep off make,
# which on this side loses roughly one child in a hundred and fifty to a bad
# exec -- a build of eleven commands is not worth the retry loop coreutils
# needs.  See build.kaem for what each command is.
#
# Three of the eleven objects the Linux makefile builds are gone, and all
# three for the same reason: ntlibc has the function, so keeping grep's copy
# would make this linker -- which resolves archives in one pass -- see the
# symbol defined twice.
#
#   stpcpy          <string.h>, char *stpcpy(char *, const char *).
#   getopt/getopt1  ntlibc has getopt, getopt_long and getopt_long_only, and
#                   its struct option has the same four members in the same
#                   order that grep's own getopt.h declares, so grep's header
#                   still describes what it links against.
#
# What is NOT dropped is regex.  ntlibc has no <regex.h> and no regcomp, so
# grep's bundled regex.c is the only POSIX matcher in the picture; dfa.c and
# search.c use it through grep's own regex.h and nothing collides.
{
  stdenv,
  stage0,
  tinycc,
  ntlibc,
  callPackage,
}:
let
  pname = "gnugrep";
  version = "2.4";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../../../nt/ntlibc/bootstrap-sources.nix { };
in
stdenv.mkDerivation {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://mirrors.kernel.org/gnu/grep/grep-${version}.tar.gz";
    sha256 = "a32032bab36208509466654df12f507600dfe0313feebbcd218c32a70bf72a16";
  };

  tcc = tinycc.boot.tcc;

  # Both halves of ntlibc: the built libraries, and the source tree its
  # headers live in -- only bits/alltypes.h is generated, and that one is in
  # the output beside the libraries.  See the ntlibc package.
  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  bin_ungz = stage0.mescc-tools-extra.ungz;
  bin_untar = stage0.mescc-tools-extra.untar;
  bin_cp = stage0.mescc-tools-extra.cp;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "GNU implementation of the Unix grep command";
    homepage = "https://www.gnu.org/software/grep";
    license = "gpl3Plus";
    inherit platforms;
  };
}
