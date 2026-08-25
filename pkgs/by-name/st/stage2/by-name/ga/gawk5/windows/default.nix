# GNU awk 5.3.2, compiled by the tcc this chain built, against ntlibc.
#
# The PE32 counterpart of ../../../linux/bootstrap/gawk.  Same version and
# the same tarball hash.  This is the awk everything above the C library
# uses; ../gawk -- 3.0.6, the seed -- exists to build this one, because 3.0.6
# is old enough to build with no awk in the picture and too old for the
# subs.awk a modern config.status generates.  From mirrors.kernel.org, since
# ftp.gnu.org does not answer here.
#
# Everything after this package depends on it: diffutils, findutils, binutils
# and gcc all configure through an autoconf that runs awk from its first
# hundred lines and then again inside config.status.
#
# As with grep, sed, gzip, tar and the 3.0.6 seed, this build does not run
# ./configure.  That decision was harder to defend here and was made on
# measurement rather than on precedent: 5.3.2 is 34 C files against 3.0.6's
# 16, and it carries a gnulib import (support/) that 3.0.6 does not have.
# What made it come out the same way is that the import is small and
# self-contained -- eleven .c files, no config-time code generation, no
# gnulib-tool m4 layer to satisfy -- and that the release tarball ships both
# bison outputs (awkgram.c and command.c), so nothing has to be generated at
# build time at all.  Against that, running configure would drag bash, sed,
# grep and coreutils into gawk's closure and put a few hundred child
# processes through make's exec path, which had a deterministic
# fork/close-on-exec bug in it for most of the time this package was being
# written.  So the answers are asserted in config.h and kaem
# names the thirty-seven compiles and the one link.  Both of the ac_cv_
# answers the Linux build has to supply by hand are in config.h too, as
# GETPGRP_VOID and HAVE_TZSET.
#
# The parser was checked before anything else, as it was for 3.0.6: awk.y and
# command.y are bison input and there is no bison anywhere in this chain
# (bison's own configure needs an awk).  The 5.3.2 release tarball ships
# awkgram.c and command.c pre-generated, and they compile as ordinary C.  A
# git checkout would not have.
#
# Almost everything the Linux recipe does for mes-libc is deleted rather than
# translated -- the same rule the 3.0.6 sibling follows, and it deletes the
# same things: ntlibc has setlocale with real LC_CTYPE, LC_COLLATE, LC_NUMERIC
# and LC_MESSAGES (so the Linux side's `-DLC_ALL=' is dropped, not ported --
# it would make setlocale expand to nothing), a real strftime, mktime, timegm,
# strerror, strsignal, strtod, strcoll, strncasecmp, system, tzset and fmod,
# a POSIX getpgrp(void), and getopt/getopt_long/getopt_long_only.  So gawk's
# entire missing_d/ directory is kept out of the build -- replace.c compiles
# to an object with no symbols in it -- and mpfr, dlopen, sockets, readline,
# libsigsegv, libintl, mmap and iconv are all answered no, honestly, because
# none of them exists in this chain.
#
# Four decisions in the other direction, and they are the ones worth reading:
#
#   -DGAWK      is load-bearing here where it was cargo in 3.0.6 (the 3.0.6
#               package left it off after building both ways and getting
#               byte-identical binaries).  support/localeinfo.h reads
#               `#if GAWK' to pick `#define char32_t wchar_t' over
#               `#include <uchar.h>', which ntlibc does not have.
#
#   _GNU_SOURCE is load-bearing and is the least obvious thing in the port.
#               support/regex.h declares the GNU interface underneath the
#               POSIX one -- struct re_pattern_buffer, struct re_registers,
#               re_compile_pattern, re_search, re_set_syntax -- only inside
#               `#ifdef _GNU_SOURCE', and awk.h embeds both of those structs
#               by value.  Without it every file fails with "field 'regs' has
#               incomplete type", which is a confusing way to be told a
#               feature-test macro is missing.
#
#   HAVE_STRINGS_H
#               is DEFINED here and deliberately WITHHELD in the 3.0.6
#               sibling, and the difference is in awk.h, not in ntlibc.
#               3.0.6's awk.h reads <string.h> and <strings.h> as
#               alternatives, so admitting the second loses every str*
#               declaration; 5.3.2's includes each under its own #ifdef.  The
#               answer was re-read rather than carried over, which is the
#               whole point of that class of question.
#
#   support/getopt.c and getopt1.c ARE compiled, where the 3.0.6 sibling
#               drops gawk's getopt and uses ntlibc's.  5.3.2's is gnulib's,
#               and main.c depends on the leading '+', on optional arguments
#               and on GNU permutation while command.c calls
#               getopt_long_only.  Keeping the implementation that matches
#               the header gawk includes was the conservative call.  It costs
#               seven duplicate symbols, all resolved in gawk's favour; see
#               the nm note in build.kaem.
#
# Three files this port supplies that gawk does not, and one gawk file it
# patches, none of them about a function ntlibc merely lacks:
#
#   langinfo.h, nt-missing.c
#               ntlibc has no <langinfo.h> and no nl_langinfo, and this is
#               not an answer that can be withheld: support/regcomp.c
#               includes the header and calls nl_langinfo(CODESET) outside
#               every #ifdef.  gawk has the same problem on MS-Windows and
#               answers it the same way, in pc/langinfo.h and pc/gawkmisc.pc,
#               which are not compiled here.  nt-missing.c supplies that plus
#               the only two other names ntlibc does not have that gawk
#               references: wcscoll (eval.c, multibyte collation -- wcscmp is
#               exact in the C locale) and putwc (node.c's dump_wstr, a
#               debugging aid called from nowhere that tcc emits anyway).
#
#   patches/nt-program-name.patch
#               argv[0] arrives from the NT loader as a full backslashed
#               store path and gawk_name() splits on '/' only, so without
#               this every diagnostic and ARGV[0] carries the store path.
#               The 3.0.6 sibling's patch, moved onto 5.3.2's prototypes.
#
#   patches/nt-system-via-libc.patch
#               and this one is a regression 5.3.2 introduces, not something
#               ntlibc lost.  3.0.6 implemented awk's system() as a call to
#               the C library's system(), which ntlibc has and which works.
#               5.3.2 replaced it with gawk_system(), which open-codes
#               fork() + execl("/bin/sh") except on VMS and MinGW -- and
#               there is no /bin/sh on this target.  Measured with a
#               nine-line C program, no fork in it: execl("/bin/sh", ...)
#               fails with errno 9, EBADF, while execl of a genuinely
#               absent path gives ENOENT and execl of cmd.exe runs.  Under
#               wine /bin/sh resolves to the host's ELF shell, which
#               ntlibc's __spawn cannot load because NtCreateUserProcess
#               loads PE images; on a real NT system the path is simply not
#               there.  So every system() call returned 126 having done
#               nothing.  This is NOT the fork/cloexec handle bug -- it
#               reproduces with no fork, and it is unchanged across that
#               fix.  The C library's system() works because ntlibc's runs
#               %ComSpec% (cmd.exe), not /bin/sh.  The patch widens gawk's
#               own escape hatch to cover _WIN32.
#
# One thing this awk cannot do, and it is the same gap the 3.0.6 sibling has:
# `"cmd" | getline' and `print | "cmd"'.  io.c's gawk_popen and
# gawk_popen_write are pipe() + fork() + execl("/bin/sh"), and it is the same
# /bin/sh the system() patch is about -- the exec fails, the child exits, and
# getline reads nothing and returns 0 with ERRNO unset.  Unlike system(),
# there is no C library call to fall back to that would hand gawk the fd it
# needs, and pointing gawk at cmd.exe instead is not a rename: cmd.exe does
# not parse what follows /C the way a POSIX shell parses -c, and the command
# strings come from awk programs that were written for a POSIX shell.  So
# this is left broken rather than half-fixed.
# system() and every file redirection DO work, including `getline < "file"'
# and `print > "file"'.  It does not affect what this package exists for:
# autoconf's config.status probes for exactly this with
# `$AWK 'BEGIN { getline <"/dev/null" }'', which passes here, and neither of
# the two awk programs it then runs -- subs.awk and defines.awk -- pipes to
# anything.  That was not taken on faith: a real autoconf 2.71 configure (GNU
# make 4.4.1's) was run twice, once with AWK set to this binary and once with
# the host's gawk, and every generated file came out identical apart from the
# `AWK =' line and the build directory.
{
  derivationWithMeta,
  stage0,
  tinycc,
  ntlibc,
  gnupatch,
  bootGawk,
  callPackage,
}:
let
  pname = "gawk";
  version = "5.3.2";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../../../nt/ntlibc/bootstrap-sources.nix { };
in
derivationWithMeta {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://mirrors.kernel.org/gnu/gawk/gawk-${version}.tar.gz";
    sha256 = "8639a1a88fb411a1be02663739d03e902a6d313b5c6fe024d0bfeb3341a19a11";
  };

  tcc = tinycc.boot.tcc;
  patch = "${gnupatch}/bin/patch.exe";

  # Both halves of ntlibc: the built libraries, and the source tree its
  # headers live in -- only bits/alltypes.h is generated, and that one is in
  # the output beside the libraries.  See the ntlibc package.
  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  # The seed awk.  Nothing in this build RUNS it -- there is no configure
  # here and no awk script to run -- but it is named so that the dependency
  # edge the Linux package has is visible on this side too, and so that a
  # future change here that does need an awk has one.  On the Linux side the
  # same argument is `self.gawk-mes'.
  inherit bootGawk;

  # What ./configure would have discovered, and the answers it is
  # deliberately not given.  See the head of that file.
  configH = ./config.h;

  # The <langinfo.h> ntlibc does not have, and the three functions behind it.
  shimLanginfo = ./langinfo.h;
  shimMissing = ./nt-missing.c;

  # Ours, not live-bootstrap's, and not the Linux package's either -- the one
  # patch there edits a configure this build never runs.
  patchProgramName = ./patches/nt-program-name.patch;
  patchSystem = ./patches/nt-system-via-libc.patch;

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
