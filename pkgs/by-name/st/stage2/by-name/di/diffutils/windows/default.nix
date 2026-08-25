# GNU diffutils 3.8, compiled by the tcc this chain built, against ntlibc.
#
# diff, cmp, diff3 and sdiff.  binutils' configure runs cmp, and gcc's build
# compares generated files against what it has, so this comes before both.
# The PE32 counterpart of ../../../linux/bootstrap/diffutils, same version and
# the same tarball hash.  From mirrors.kernel.org, since ftp.gnu.org does not
# answer here.
#
# ---------------------------------------------------------------------------
# No ./configure, for the same reason as findutils, and a smaller gnulib
#
# diffutils 3.8's gnulib import is the same KIND of dependency on configure
# that findutils' is -- generated replacement headers, not just a list of
# HAVE_ answers -- and the same fact makes it possible to do without them:
# ntlibc is close enough to POSIX that no gnulib module diffutils uses needs
# a renamed rpl_* entry point.  Where ntlibc lacks the function outright --
# error, euidaccess's neighbours are not needed here, but nl_langinfo,
# wcwidth and getprogname are -- the gnulib .c file or a small file of this
# port's own supplies it and wins the link outright as a named object.
#
# What is different from findutils, and what made this import notably
# smaller to answer for: diffutils 3.8's gnulib is several years older than
# findutils 4.10.0's, and its config.hin -- autoheader's own template, shipped
# in the tarball -- already carries the _GL_ATTRIBUTE_*/_Noreturn/_GL_CMP
# boilerplate that findutils' gnulib instead generates separately and this
# port had to copy into shim/gl-common.h.  So config.h here needs no such
# shim: it is config.hin with every #undef answered, in place, plus the two
# platform decisions at its tail (see epilogue below).  What gnulib's
# REPLACEMENT HEADERS would still have added on top -- five names in
# <string.h>, two in <wchar.h>, one in <time.h>, one in <locale.h>, eleven
# S_IS* macros in <sys/stat.h>, and <fnmatch.h> and <langinfo.h> in full,
# ntlibc having neither -- is in shim/, one file per system header, each
# saying which gnulib .in.h it stands in for and who reads it.  Every one of
# them #include_next's ntlibc's real header first; -Ilib comes before
# ntlibc's include directory on the compile line, which is what makes that
# resolve to ntlibc's header and not back to itself.
#
# ---------------------------------------------------------------------------
# What settled it, and what is NOT carried over from mes-libc
#
# Established by trying it, the same way as findutils: with config.h and the
# shim/ headers and nothing else, the 91 files this build compiles failed in
# a handful of clusters, and every one of them was a missing declaration or a
# missing small function, never a rename.  See build.kaem for the compile
# list and shim/nt-missing.c for the three functions ntlibc has no branch
# for at all.
#
# The Linux diffutils build is against musl, not mes-libc -- ../../../
# linux/bootstrap/diffutils's own comment says musl is where a package has
# "outgrown the libc that got the bootstrap started" -- so it carries none of
# the `-Dsig_atomic_t=int' / `-Dendpwent' / `-DLC_ALL=' / `-DHAVE_SYS_SIGLIST'
# / `-Dstrsignal' family that breaks against ntlibc, and nothing here had to
# delete such a thing either.  config.h's answers were decided fresh for this
# package rather than copied from findutils or either gawk: HAVE_FORK and
# HAVE_WORKING_FORK are both yes here (sdiff and diff3 each fork and exec an
# external `diff', measured working under wine) where the closest precedent,
# findutils' xargs, needed a patch for a related fork/exec defect -- see the
# xargs patch's own reasoning for why that one does not recur here, in
# build.kaem's note on the self-test.
#
# ---------------------------------------------------------------------------
# The one wrong ANSWER this build produced, not a missing declaration
#
# Every other gap here is a compile or a link error -- loud, and fixed before
# anything ran.  One gap is neither: src/system.h's same_file() -- the
# "are these two arguments the same physical file" test that decides whether
# diff reads a file at all, whether diff -r recurses into a directory entry
# twice, and whether cmp treats its output as /dev/null -- defaults to
# comparing st_ino and st_dev, documented as returning -1 ("unknown") when it
# cannot tell.  ntlibc gives a pipe, a console or a character device an
# all-zero stat, so two such handles compared EQUAL under the default: `cmp a
# b' with its output piped printed NOTHING, having decided the pipe was
# /dev/null, while its exit status stayed right -- exactly how a bug like
# this survives a smoke test that only checks exit codes. Fixed in the
# epilogue this package's config.h carries at its tail, along with NULL_DEVICE
# ("NUL", not "/dev/null" -- under wine, Z: maps the host's root, so the POSIX
# spelling resolves and silently hands cmp the HOST's null device).  See
# config.h's own comment on both, at the very end of the file.
{
  stdenv,
  stage0,
  tinycc,
  ntlibc,
  gnupatch,
  gawk5,
  bash,
  coreutils,
  gnumake,
  gnused,
  gnugrep,
  callPackage,
}:
let
  pname = "diffutils";
  version = "3.8";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../../../nt/ntlibc/bootstrap-sources.nix { };
in
stdenv.mkDerivation {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://mirrors.kernel.org/gnu/diffutils/diffutils-${version}.tar.xz";
    sha256 = "a6bdd7d1b31266d11c4f4de6c1b748d4607ab0231af5188fc2533d0ae2438fec";
  };

  tcc = tinycc.boot.tcc;
  patch = "${gnupatch}/bin/patch.exe";

  # Both halves of ntlibc: the built libraries, and the source tree its
  # headers live in -- only bits/alltypes.h is generated, and that one is in
  # the output beside the libraries.  See the ntlibc package.
  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  # The tools the Linux recipe names as inputs and that this build does not
  # run, because there is no ./configure here to run them.  They are declared
  # so that the dependency edge the Linux package has is visible on this side
  # too, and so that a future change here that does need one has it.  This is
  # the same argument the findutils sibling makes for its own copy of this
  # list.
  inherit
    gawk5
    bash
    coreutils
    gnumake
    gnused
    gnugrep
    ;

  # What ./configure would have discovered, and the answers it is deliberately
  # not given.  See the head of this file.
  configH = ./config.h;

  # This port's own headers, standing in for what gnulib's generated
  # replacement headers would have added on top of ntlibc's real ones.  Each
  # says in its own header what it is standing in for and why the answer
  # could not be withheld instead.
  shimFnmatch = ./shim/fnmatch.h;
  shimLanginfo = ./shim/langinfo.h;
  shimLocale = ./shim/locale.h;
  shimString = ./shim/string.h;
  shimWchar = ./shim/wchar.h;
  shimTime = ./shim/time.h;
  shimSysStat = ./shim/sys-stat.h;
  shimMissing = ./shim/nt-missing.c;

  # Three files ./configure would generate that the tarball ships no
  # un-substituted template for at all -- see each one's own header.
  shimPathsH = ./shim/paths.h;
  shimVersionC = ./shim/version.c;
  shimVersionH = ./shim/version.h;

  # Ours, not live-bootstrap's, and not the Linux package's either -- that one
  # has no patches at all.  See the patch's own reasoning.
  patchProgramName = ./patches/nt-program-name.patch;

  bin_unxz = stage0.mescc-tools-extra.unxz;
  bin_untar = stage0.mescc-tools-extra.untar;
  bin_cp = stage0.mescc-tools-extra.cp;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;
  bin_catm = stage0.mescc-tools-extra.catm;

  # The build's own acceptance test needs a comparison, and kaem has none.
  # `match' exits 0 if its two arguments are the same string; see the
  # self-test section of build.kaem, as findutils' does.
  bin_match = stage0.mescc-tools-extra.match;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "Commands for showing the differences between files";
    homepage = "https://www.gnu.org/software/diffutils";
    license = "gpl3Plus";
    inherit platforms;
  };
}
