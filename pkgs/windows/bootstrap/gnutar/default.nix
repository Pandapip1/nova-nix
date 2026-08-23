# GNU tar 1.12, compiled by the tcc this chain built, against ntlibc.
#
# The PE32 counterpart of ../../../linux/bootstrap/gnutar.  Same version and
# the same tarball hash: 1.12 is the last tar that is a self-contained tree --
# fifteen C files and a small library of its own -- rather than a gnulib
# import whose replacement modules would collide with a real C library at
# every turn.  From mirrors.kernel.org, since ftp.gnu.org does not answer
# here.
#
# The one large difference from the Linux build is that this one does not run
# ./configure.  Over there, tar was the first package to do so, and bash was
# built for exactly that; the argument for keeping it was that from tar
# upward a package could be built the way its authors intended.  It buys much
# less on this side.  tar 1.12's configure asks about tape drives, remote
# shells, `union wait', four spellings of <sys/mtio.h> and a working fnmatch;
# every one of those answers is already known here, and three of them
# configure would get WRONG (see config.h).  Running it would mean dragging
# bash, sed, grep and coreutils into tar's closure, and running about nine
# hundred child processes through an exec path that loses roughly one in a
# hundred and fifty, to be told things this file already knows.  So the
# answers are written out, as they are for grep and sed, and kaem names the
# twenty-six compiles and the one link directly.  There is no make here
# either, for the same reason grep has none: a straight-line build is not
# worth a retry loop.
#
# Nothing is patched on the Linux side.  Three things are patched here, and
# all three are about NT's filesystem rather than about the C library -- see
# patches/ and the head of build.kaem.
#
# Everything the Linux build's configure would have added from lib/ as a
# replacement function is simply not compiled: alloca, basename, dirname,
# execlp, fileblocks, ftruncate, gmalloc, memset, mkdir, rename, rmdir,
# stpcpy, strstr, getopt and getopt1.  ntlibc has all of them.  That is the
# whole of the "expect to delete, not add" lesson applied to this package: the
# Linux recipe's shape survives, and fifteen of its files do not.
#
# One file is kept that a working C library would have displaced, and kept on
# purpose: lib/fnmatch.c.  ntlibc's fnmatch is POSIX and has no
# FNM_LEADING_DIR, and FNM_LEADING_DIR is how `tar -xf a.tar dir' reaches
# dir/sub/file and how --exclude excludes a subtree.  See config.h.
#
# _WIN32 and WIN32, which a PE-target tcc defines, are left alone -- this
# package sides with grep rather than with coreutils.  tar 1.12 predates
# gnulib entirely; WIN32 appears in exactly two places in the tree, one in
# lib/getopt.c (not compiled, ntlibc has getopt) and one in lib/fnmatch.h,
# where all it does is decide that prototypes are usable, which they are.
# MSDOS, which is what tar 1.12 actually branches on some sixty times, is not
# defined by anything here and must not be: those branches are for a
# sixteen-bit compiler with an 8.3 filesystem, not for NT.
{
  derivationWithMeta,
  stage0,
  tinycc,
  ntlibc,
  gnupatch,
  callPackage,
}:
let
  pname = "gnutar";
  version = "1.12";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../ntlibc/bootstrap-sources.nix { };
in
derivationWithMeta {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://mirrors.kernel.org/gnu/tar/tar-${version}.tar.gz";
    sha256 = "c6c37e888b136ccefab903c51149f4b7bd659d69d4aea21245f61053a57aa60a";
  };

  tcc = tinycc.boot.tcc;
  patch = "${gnupatch}/bin/patch.exe";

  # Both halves of ntlibc: the built libraries, and the source tree its
  # headers live in -- only bits/alltypes.h is generated, and that one is in
  # the output beside the libraries.  See the ntlibc package.
  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  # What ./configure would have discovered, and what it would have got wrong.
  configH = ./config.h;

  # Ours, not live-bootstrap's -- there is no live-bootstrap recipe for tar --
  # and none of the three is about the C library.  See each file's own
  # comment.
  patchSymlinks = ./patches/nt-no-symlinks.patch;
  patchReadonly = ./patches/nt-readonly-attribute.patch;
  patchProgramName = ./patches/nt-program-name.patch;

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
    description = "GNU implementation of the tar archiver";
    homepage = "https://www.gnu.org/software/tar";
    license = "gpl3Plus";
    inherit platforms;
  };
}
