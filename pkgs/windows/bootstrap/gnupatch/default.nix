# GNU patch 2.5.9, compiled by tcc against ntlibc.
#
# Wanted because the packages above this one arrive as release tarballs with
# things in them that a hermetic build must not have -- absolute /bin/sh,
# /usr/include on a search path -- and the projects' own answer to that is a
# patch file.  make needed none, which is why it went first; bash needs five.
#
# 2.5.9 rather than anything newer: 2.6 and later use gnulib pieces this
# bootstrap has no counterpart for.  From mirrors.kernel.org, since
# ftp.gnu.org does not answer here.
{
  derivationWithMeta,
  stage0,
  tinycc,
  ntlibc,
  callPackage,
}:
let
  pname = "gnupatch";
  version = "2.5.9";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../ntlibc/bootstrap-sources.nix { };
in
derivationWithMeta {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://mirrors.kernel.org/gnu/patch/patch-${version}.tar.gz";
    sha256 = "ecb5c6469d732bcf01d6ec1afe9e64f1668caba5bfdb103c28d7f537ba3cdb8a";
  };

  tcc = tinycc.boot.tcc;

  # Both halves of ntlibc: the built libraries, and the source tree its
  # headers live in -- see the ntlibc package for why only one header is in
  # the output.
  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  bin_ungz = stage0.mescc-tools-extra.ungz;
  bin_untar = stage0.mescc-tools-extra.untar;
  bin_catm = stage0.mescc-tools-extra.catm;
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
    description = "Apply a diff file to an original";
    homepage = "https://www.gnu.org/software/patch";
    license = "gpl3Plus";
    inherit platforms;
  };
}
