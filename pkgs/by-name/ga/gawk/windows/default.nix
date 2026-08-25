# GNU awk 3.0.6, compiled by the tcc this chain built, against ntlibc.
#
# The PE32 counterpart of ../../../linux/bootstrap/gawk.  Same version and the
# same tarball hash: 3.0.6 (2000) is the seed awk, the one live-bootstrap and
# nixpkgs' minimal bootstrap both settle on, because it is small enough and
# old enough to build without an awk already existing.  gawk 5.3.2 is built
# with this one later.  From mirrors.kernel.org, since ftp.gnu.org does not
# answer here.
#
# This is the package every autotools ./configure above it depends on: a
# configure script runs awk from its first hundred lines, so nothing further
# up can be configured without one.
#
# As with grep, sed, gzip and tar, this build does not run ./configure.  The
# Linux recipe does -- it patches configure, waits for the clock to tick so
# that configure's newer-than-the-sources check is not a coin flip, exports
# two ac_cv_ answers configure cannot work out by running a test program, and
# then runs make.  All of that buys a set of answers this file already knows,
# at the cost of dragging bash, sed, grep and coreutils into gawk's closure
# and of running some hundreds of child processes through an exec path that
# still loses roughly one in a hundred and fifty.  So the answers are
# asserted in config.h and kaem names the sixteen compiles and the one link
# directly.  Both of the ac_cv_ answers the Linux build has to supply by hand
# are in config.h too, as GETPGRP_VOID and HAVE_TZSET.
#
# The parser is not a problem, which was the one thing that could have made
# this plan impossible: awk.y is bison input and there is no bison anywhere in
# this chain (bison's own configure needs an awk), but the 3.0.6 release
# tarball ships awktab.c, the pre-generated Bison 1.25 output, and it compiles
# as ordinary C.  A git checkout would not have.
#
# Almost everything the Linux recipe does for mes-libc is deleted rather than
# translated.  ntlibc has setlocale with a real LC_CTYPE and LC_COLLATE, a
# real strftime, strerror, strtod, strncasecmp, system, tzset and fmod, a
# POSIX getpgrp(void), an alloca that is a genuine stack adjustment, and
# getopt/getopt_long with gawk's own struct option layout.  So gawk's
# missing/ directory is not compiled at all -- ten replacement functions, of
# which missing/strftime.c alone is 700 lines -- and neither are getopt.c,
# getopt1.c or alloca.c.  What is left is thirteen of gawk's own files plus
# three of its library files.  See config.h for each answer and build.kaem
# for each file.
#
# Three files ARE kept that a complete C library might have displaced, and
# each for its own reason:
#
#   regex.c   ntlibc grew a <regex.h> and a POSIX regcomp/regexec in the pin
#             this is built against, and gawk cannot use it.  awk.h reaches
#             into struct re_pattern_buffer and struct re_registers directly,
#             and re.c calls re_compile_pattern, re_search and re_set_syntax
#             -- the GNU interface underneath the POSIX one, where gawk's
#             syntax bits live.  gawk's regex.o defines all four POSIX names
#             as well (regcomp, regexec, regfree, regerror), so ntlibc's
#             regex.o is never pulled out of libc.a and there is no
#             duplicate.  That was checked with nm rather than waited for:
#             this tcc does report "link symbol 'regcomp' defined twice", but
#             only when an archive member actually gets pulled, and the four
#             names are the ONLY overlap between gawk's sixteen objects and
#             ntlibc's 864 globals.
#   dfa.c     gawk's deterministic first-pass matcher.  No C library has a
#             counterpart.
#   random.c  ntlibc has random(), srandom() and initstate(), and gawk ships
#             its own on purpose so that rand() gives the same sequence
#             everywhere.  gawk's random.h renames them to gawk_random() and
#             so on, so this is not even a shadowing -- both live in the
#             binary and only gawk's is called.
#
# One patch, and it is not about the C library: argv[0] arrives from the NT
# loader as a full backslashed store path, and gawk_name() -- which strips it
# down to `gawk' for every diagnostic, both usage lines and ARGV[0] -- splits
# on '/' only.  See patches/nt-program-name.patch.  The Linux build's
# no-stamp.patch is not carried over: it edits configure, and nothing here
# runs configure.
#
# One thing this awk cannot do, and it is not gawk's fault: `"cmd" | getline'
# and `print | "cmd"'.  io.c's gawk_popen is a pipe() plus a fork() plus an
# execl of /bin/sh, and on this side the child's end of the pipe does not come
# back -- the command's output goes to the console and getline reads nothing
# (measured; whether the loss is in fork, in the dup2 across it, or in what
# ntlibc's exec maps /bin/sh onto was not chased down here, but it is below
# gawk either way).  system() does work, and so does every file redirection,
# including `getline < "file"' and `print > "file"'.  It does not affect what
# this package exists for: autoconf's config.status probes for exactly this
# with `$AWK 'BEGIN { getline <"/dev/null" }'', which passes here, and neither
# of the two awk programs it then runs -- subs.awk and defines.awk -- pipes
# to anything.
{
  derivationWithMeta,
  stage0,
  tinycc,
  ntlibc,
  gnupatch,
  callPackage,
}:
let
  pname = "gawk";
  version = "3.0.6";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../../../nt/ntlibc/bootstrap-sources.nix { };
in
derivationWithMeta {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://mirrors.kernel.org/gnu/gawk/gawk-${version}.tar.gz";
    sha256 = "abf276e10c7b871332d07bf2b652133a27419677d157383097bbd153e58a8bfc";
  };

  tcc = tinycc.boot.tcc;
  patch = "${gnupatch}/bin/patch.exe";

  # Both halves of ntlibc: the built libraries, and the source tree its
  # headers live in -- only bits/alltypes.h is generated, and that one is in
  # the output beside the libraries.  See the ntlibc package.
  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  # What ./configure would have discovered, and the five true answers it is
  # deliberately not given.  See the head of that file.
  configH = ./config.h;

  # Ours, not live-bootstrap's, and not the Linux package's either -- the one
  # patch there (no-stamp) edits a configure this build never runs.
  patchProgramName = ./patches/nt-program-name.patch;

  # The build's own acceptance test, and its two input files.  It is an awk
  # program that checks its own answers, because kaem has no way to compare
  # one program's output against another's.  See selftest.awk.
  selfTest = ./selftest.awk;
  selfTestData = ./data1.txt;
  selfTestData2 = ./data2.txt;

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
    description = "GNU implementation of the AWK programming language";
    homepage = "https://www.gnu.org/software/gawk";
    license = "gpl3Plus";
    inherit platforms;
  };
}
