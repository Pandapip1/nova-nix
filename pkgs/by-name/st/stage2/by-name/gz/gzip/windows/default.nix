# gzip 1.2.4, compiled by the tcc this chain built, against ntlibc.
#
# The PE32 counterpart of ../../../linux/bootstrap/gzip.  Same version and the
# same tarball hash; the tarball comes from mirrors.kernel.org rather than
# ftp.gnu.org, which does not answer here.
#
# 1.2.4 is a 1993 program: no gnulib, no config.h, no libtool, fourteen C
# files and a Makefile.in whose comment block lists every -D configure can
# hand it.  So this build does not run gzip's ./configure the way the Linux
# one does -- it asserts the four answers directly and lets kaem name the
# fourteen commands, which is what gnugrep does and for the same two reasons:
# there is nothing for a shell to do, and it keeps gzip off make, which on
# this side loses roughly one child in a hundred and fifty to a bad exec.
#
# The porting decisions -- what WIN32 and MSDOS would have selected and why
# they are left undefined, why getopt.o is dropped, why -Dstrlwr=unused is
# not carried over, why basename collides silently and that being fine -- are
# written out at the head of build.kaem and config.h, next to the lines they
# explain.
#
# What was verified by running the built program, beyond what build.kaem can
# check under kaem (which has no pipes, no redirection and --strict, so a
# deliberate failure cannot be tested there):
#
#   Round trip.  6.5 MB of mixed text and /dev/urandom, compressed with -9 and
#   decompressed again, sha256 identical to the original.  Large enough to
#   run the 32K deflate window and the dynamic Huffman path many times over
#   rather than emitting one stored block.
#
#   Interoperation, both directions.  The host's own gunzip reads what this
#   gzip writes and gets the same sha256; and this gzip decompresses six real
#   release tarballs already in the store -- make, coreutils, bash, sed, grep
#   and patch -- to exactly the bytes the host's gunzip produces from them.
#
#   Pipes.  `gzip -c' and `gzip -dc' with binary data on stdin and stdout,
#   sha256 preserved.  That is the check that matters most on this side: it
#   is what would fail if anything in the stack did CRLF translation, and it
#   is why SET_BINARY_MODE is left as the empty default.
#
#   Header bytes.  Identical to the host gzip's for the same input, including
#   the OS byte (0x03) and the stored name and mtime, which is the point of
#   the OS_CODE argument in build.kaem.
#
#   -t.  Zero on a good file; one, with "invalid compressed data--crc error",
#   on the same file with a byte flipped in the middle of the deflate stream;
#   one, with "not in gzip format", on the same file with the magic broken.
#
#   Mode from argv[0].  A copy named gunzip.exe, invoked by full backslashed
#   NT path, decompresses; a copy named zcat.exe writes to stdout.  The same
#   tree built without config.h answers `gunzip n.gz' by trying to COMPRESS
#   it -- that is the measurement config.h exists for.
#
#   -l, -N and -r, and mtime preservation through utime() on the way out and
#   back.
#
# Not verified: the compress(1) and pack(1) decompression paths (unlzw.c,
# unpack.c, unlzh.c) are compiled and linked but never exercised -- nothing
# in this bootstrap produces a .Z, a .z or a .lzh to test them on.  Nor is
# encryption (crypt.c), which gzip 1.2.4 ships stubbed out anyway.
{
  derivationWithMeta,
  stage0,
  tinycc,
  ntlibc,
  callPackage,
}:
let
  pname = "gzip";
  version = "1.2.4";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../../../nt/ntlibc/bootstrap-sources.nix { };
in
derivationWithMeta {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://mirrors.kernel.org/gnu/gzip/gzip-${version}.tar.gz";
    sha256 = "1ca41818a23c9c59ef1d5e1d00c0d5eaa2285d931c0fb059637d7c0cc02ad967";
  };

  tcc = tinycc.boot.tcc;

  # Both halves of ntlibc: the built libraries, and the source tree its
  # headers live in -- only bits/alltypes.h is generated, and that one is in
  # the output beside the libraries.  See the ntlibc package.
  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  # The two defines that cannot be spelled on a kaem command line.  See the
  # head of the file itself.
  configH = ./config.h;

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
    description = "GNU zip compression program";
    homepage = "https://www.gnu.org/software/gzip";
    license = "gpl3Plus";
    inherit platforms;
  };
}
