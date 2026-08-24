# GNU findutils 4.10.0, compiled by the tcc this chain built, against ntlibc.
#
# find and xargs.  gcc's build runs find, and binutils' runs both, so this
# comes before them.  The PE32 counterpart of
# ../../../linux/bootstrap/findutils, same version and the same tarball hash.
# From mirrors.kernel.org, since ftp.gnu.org does not answer here -- and as
# .tar.xz, because findutils has shipped nothing else since 4.7.0.
#
# ---------------------------------------------------------------------------
# Why there is still no ./configure here, when this is the package that had
# the best claim to one
#
# Every Windows package below this one asserts configure's answers in a
# config.h.  findutils is the first with a MODERN GNULIB IMPORT, and that is a
# different kind of dependency on configure than a list of HAVE_ answers.
# gnulib has two halves.  One is .c files, which can be named on a command
# line like anything else.  The other is REPLACEMENT HEADERS: configure
# generates gl/lib/stdio.h from gl/lib/stdio.in.h by substituting a hundred
# and sixteen @GNULIB_FOO@ values into it, and unistd.h from unistd.in.h with
# a hundred and eighty-eight, and thirty-seven more besides.  On the host,
# `make' writes thirty-nine such headers.  Nothing in this bootstrap can do
# that, and hand-writing them is not a port, it is a rewrite.
#
# So the question was not "should configure run" but "can this be built
# without those headers at all", and the answer -- established by trying it
# rather than by argument -- is yes, for one reason: a gnulib replacement
# header exists to RENAME things.  It is how gnulib gets `rpl_fseeko' in
# front of a broken fseeko.  ntlibc needs no such rename for anything
# findutils uses; its fseeko, mbrtowc, getcwd, openat, fdopendir and the rest
# are the real functions.  Where ntlibc lacks a function outright -- error,
# euidaccess, rpmatch, wcwidth, nl_langinfo, GNU fnmatch, GNU regex -- the
# gnulib .c file that supplies it is simply compiled, and being a named object
# it wins the link over any archive member outright.  What is left is a short
# list of things gnulib's headers ADD rather than replace: five prototypes,
# ten S_IS* macros for file types no system has, timezone_t, O_SEARCH,
# S_IRWXUGO, mbszero.  Those are in shim/gl-missing-decls.h, one at a time,
# each saying which .in.h it comes from and who reads it.
#
# What settled it was trying it, in that order: with a config.h and nothing
# else, the hundred files this build compiles failed in a handful of clusters
# -- a missing <error.h>, a missing <uchar.h>, gnulib using C23's `bool' and
# `alignof' as keywords, `_GL_ARG_NONNULL' with nowhere to come from -- and
# every cluster had a five-line answer.  Not one of them was a rename.  The
# shim/ directory is the complete list, and it is 426 lines of header -- most
# of that comment -- against the 39 files and 29000 lines a host `make'
# generates into gl/lib.  Nothing is being smuggled past here; almost all of
# those 29000 lines are the renaming machinery for libcs that need it, and
# ntlibc does not.  Against
# that, running configure would have dragged bash, sed, grep, awk, coreutils
# and make into findutils' closure and put some thousands of child processes
# through an exec path that this very package found a bug in (see
# patches/nt-xargs-child-atexit.patch).
#
# Two other things made it cheaper than it looks.  gnulib's own boilerplate --
# the eight hundred lines of _GL_ATTRIBUTE_*, _Noreturn, _GL_CMP and
# _GL_GNUC_PREREQ that its m4 writes into every config.h -- is copied verbatim
# into shim/gl-common.h rather than hand-stubbed, because hand-stubbing it is
# exactly where a wrong macro arity would turn a declaration into syntax that
# happens to parse.  And four of gnulib's forty-six .in.h files carry no
# substitutions at all, so build.kaem copies those four; that is byte for byte
# what gnulib's own rule produces.
#
# ---------------------------------------------------------------------------
# What the Linux recipe does that is deleted here
#
# Less than usual, because the Linux findutils is built against MUSL, not
# mes-libc -- it is above the tcc/musl line, so it carries none of the
# `-Dsig_atomic_t=int' family that breaks against ntlibc.  It has exactly one
# workaround, and it is dropped:
#
#   sed -i 's/chdir_long/chdir/' gl/lib/save-cwd.c
#         a fix for configure deciding wrongly that PATH_MAX is not a usable
#         bound and then not compiling the chdir_long it had just called for.
#         There is no configure here to decide wrongly; gl/lib/chdir-long.c is
#         named in build.kaem and save-cwd.c is left alone.
#
# Its `wait for the clock to tick' loop goes too -- that is there because tar
# restores no mtimes and configure compares them; nothing here compares
# timestamps at build time.
#
# ---------------------------------------------------------------------------
# What find can and cannot mean on this platform
#
# NT's filesystem is not the one find was written for, and the honest thing is
# to say exactly where, rather than to report that the tests pass.  All of the
# following was measured under wine against ntlibc d89ec5d, by reading
# ntlibc's src/stat/stat.c and by running the built binaries; the real Windows
# loader was not available, so everything here is WINE-ONLY unless it is a
# statement about ntlibc's source.
#
#   -perm, -executable
#         work, but on modes ntlibc SYNTHESISES rather than stores.
#         mode_from_attrs() in src/stat/stat.c is the whole model: a directory
#         is 0755, a symbolic link 0777, a regular file 0755 if its NAME ends
#         in .exe, .com, .bat, .cmd or .sh (case-insensitively) and 0644
#         otherwise, and the NT read-only attribute clears the write bits to
#         give 0555 or 0444.  So `-perm 755' is a question about the file's
#         extension, `-perm 644' about its absence, and `-perm 664' -- an
#         ordinary answer under a 002 umask -- matches nothing at all, ever.
#         -executable goes through euidaccess and agrees with -perm.
#   -user, -group, -uid, -gid, -nouser, -nogroup
#         work, and are useless: ntlibc reports st_uid = st_gid = 1000 for
#         every file on the volume.  -uid 1000 matches everything, -nouser and
#         -nogroup match nothing.  %u and %g resolve through getpwuid to the
#         name of whoever is running, which is the same for every file.
#   -type l, -lname, -xtype, -L, -P, -follow
#         work CORRECTLY on symbolic links that ntlibc itself made: symlink()
#         succeeds, lstat reports S_ISLNK with the right target, readlink
#         returns it, and -L/-follow resolve to the target while -P does not.
#         Measured, on a tree built from inside wine.  Two caveats.  The
#         artefact wine writes for such a link is its own reparse encoding --
#         a zero-length file whose name ends in '?' -- which is not a symbolic
#         link to anything outside wine, and on real NT symlink() needs
#         SeCreateSymbolicLinkPrivilege, which a build may not hold.  And a
#         symbolic link made on the UNIX side and seen through wine's Z: drive
#         is not visible as a link at all: find reports it as a regular file
#         with the target's contents, and a dangling one does not appear in
#         the directory listing at all.  That is wine's mapping, not find's,
#         and it is what makes -type l look broken if it is tested the easy
#         way.
#   -fstype, %F
#         do not work, and say so rather than lying: NT has no mount table,
#         no getmntent, no statfs and no statvfs, and ntlibc offers none of
#         them, so gnulib's mountlist compiles with no MOUNTED_* strategy and
#         read_file_system_list() fails.  `find . -fstype ntfs' prints
#         "Cannot read mounted file system list" and exits nonzero.  Declaring
#         one of the MOUNTED_* macros to make it compile would have been the
#         mes-libc mistake in reverse.
#   -newer, -mtime, -atime, -newerXY, -printf %T
#         work here, and this is the result to trust least.  Timestamps are
#         read correctly, but the ntlibc pinned here has a known real-Windows
#         regression in which utimensat/utime/futimesat FAIL on ordinary
#         files, and that is green under wine and red on NT.  So every
#         timestamp-dependent result in this package is wine-only in a
#         stronger sense than the rest.
#   -context
#         refuses, as GNU find does on any host without libselinux; the stub
#         in shim/selinux/ makes is_selinux_enabled() return 0.
#
# One more platform limit, found by testing rather than looked up: a file
# whose name contains '"' can be listed but not stat'd.  NT reserves
# " * : < > ? | in a filename; wine's Z: will create one from the unix side,
# and then readdir returns it -- so -name and -type f, which go through
# d_type, are right -- while every predicate that needs a stat fails with
# ENOENT and find exits 1 having printed the name.  That is a clean failure,
# not a wrong answer, and it is the platform's, not find's.
#
# ---------------------------------------------------------------------------
# What is not built
#
# locate, updatedb and frcode.  updatedb is a Bourne script of pipelines and
# `sort'; locate is useless without the database only updatedb builds; and
# what binutils and gcc run is find and xargs, neither of which needs either.
# The Linux sibling builds them because `make install' does, not because
# anything asks for them.
{
  derivationWithMeta,
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
  gnutar,
  callPackage,
}:
let
  pname = "findutils";
  version = "4.10.0";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../ntlibc/bootstrap-sources.nix { };
in
derivationWithMeta {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://mirrors.kernel.org/gnu/findutils/findutils-${version}.tar.xz";
    sha256 = "1387e0b67ff247d2abde998f90dfbf70c1491391a59ddfecb8ae698789f0a4f5";
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
  # the same argument the gawk 5.3.2 package makes for its bootGawk.
  inherit
    gawk5
    bash
    coreutils
    gnumake
    gnused
    gnugrep
    gnutar
    ;

  # What ./configure would have discovered, and the answers it is deliberately
  # not given.  See the head of that file.
  configH = ./config.h;

  # This port's own headers.  Each says in its own header what it is standing
  # in for and why the answer could not be withheld instead.
  shimCommon = ./shim/gl-common.h;
  shimDecls = ./shim/gl-missing-decls.h;
  shimError = ./shim/error.h;
  shimFnmatch = ./shim/fnmatch.h;
  shimLanginfo = ./shim/langinfo.h;
  shimUchar = ./shim/uchar.h;
  shimSelinux = ./shim/selinux/selinux.h;
  shimSeContext = ./shim/selinux/context.h;
  shimMissing = ./shim/nt-missing.c;

  # Ours, not live-bootstrap's, and not the Linux package's either -- that one
  # has no patches, only a sed on a configure result this build never
  # produces.  Two of these three are for bugs that stopped a whole feature
  # working; each patch argues its own case.
  patchProgramName = ./patches/nt-program-name.patch;
  patchExecdir = ./patches/nt-execdir-path-syntax.patch;
  patchXargsAtexit = ./patches/nt-xargs-child-atexit.patch;

  bin_unxz = stage0.mescc-tools-extra.unxz;
  bin_untar = stage0.mescc-tools-extra.untar;
  bin_cp = stage0.mescc-tools-extra.cp;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;
  bin_catm = stage0.mescc-tools-extra.catm;

  # The build's own acceptance test needs a comparison, and kaem has none.
  # `match' exits 0 if its two arguments are the same string -- it exists so
  # that a kaem script can assert something -- and it is what turns
  # `find ... -exec match EXPECTED {} +' into a check rather than an exercise.
  # See the self-test section of build.kaem.
  bin_match = stage0.mescc-tools-extra.match;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "GNU Find Utilities, the basic directory searching utilities";
    homepage = "https://www.gnu.org/software/findutils";
    license = "gpl3Plus";
    inherit platforms;
  };
}
