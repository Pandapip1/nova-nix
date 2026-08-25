# nova-nix stage-1 stdenv: the Windows genericBuild, on this chain's own
# from-scratch toolchain.
#
# Run by this chain's own bash.exe (bootstrap/bash) as a derivation's
# builder. stdenv/default.nix passes the package via the environment:
#   $src           source tarball or directory
#   $out           install prefix (the output store path)
#   $gccBin, $binutilsBin, $bashBin, $coreutilsBin, $gnusedBin, $gnugrepBin,
#   $gawk5Bin, $findutilsBin, $diffutilsBin, $gnumakeBin, $gnupatchBin,
#   $gzipBin, $gnutarBin       this chain's own userland, one bin dir each
#   $unxzBin                   stage0's own mescc-tools-extra unxz, a single
#                              binary (not a bin dir) -- .tar.xz sources only
#   $NN_TCC, $NN_GCC, $NN_GCC_LIBDIR, $NN_NTLIBC_LIB, $NN_NTLIBC_INCLUDE,
#   $NN_NTLIBC_SRC_INCLUDE, $NN_NTLIBC_ARCH_I386, $NN_NTLIBC_ARCH_GENERIC
#                              cc-wrapper.sh's own inputs, exported as-is
#   $ccWrapperSrc              the cc-wrapper script (a store path)
#   $buildInputs               dependency store paths
# plus these optional knobs a package may set:
#   $configureFlags / $makeFlags  extra flags for the default phases
#   $dontConfigure                skip ./configure
#   $buildPhase / $installPhase   replace the default build / install commands
#
# No cygdrive-style path mapping anywhere in here, unlike the old MSYS2-seed
# stdenv this replaces: this chain's own bash and every tool it built are
# ntlibc-linked native programs, not a POSIX-emulation layer over Win32
# paths, and every earlier kaem-driven package in this chain already passes
# /nix/store paths straight through to them with no translation -- so
# neither does this.
set -e

export PATH="$coreutilsBin:$gnusedBin:$gnugrepBin:$gawk5Bin:$findutilsBin:$diffutilsBin:$gnumakeBin:$gnupatchBin:$gzipBin:$gnutarBin:$binutilsBin:$gccBin:$bashBin"

# This chain's own bash reports $PWD drive-letter-prefixed (e.g.
# "Z:/tmp/..."), unlike every /nix/store path nix itself hands this
# script, which arrives plain ("/nix/store/..."). The two forms are NOT
# interchangeable here: a real, measured ntlibc/coreutils bug (this
# chain's own mkdir -p, tested directly outside any build -- never before
# exercised in-chain, since every earlier kaem-driven package uses
# mescc-tools-extra's own bin_mkdir instead) reports success on a
# "Z:/foo/bar" target and creates nothing, while the byte-identical path
# with the drive letter stripped ("/foo/bar") creates it correctly. Not
# root-caused further (not patched here -- ntlibc is a read-only,
# peer-owned dependency; this is a report, not a fix), but reliably
# reproduced, so every path this script itself builds from $PWD strips
# the drive letter before use.
builddir="$PWD"
case "$builddir" in
  ?:*) builddir="${builddir#?:}" ;;
esac
mkdir -p "$builddir/tmp"
export TMPDIR="$builddir/tmp" TMP="$builddir/tmp" TEMP="$builddir/tmp"

# --- bare-name tool shims ---
# Every package in this chain's own userland except coreutils installs its
# binaries with a real .exe suffix (gnutar's tar.exe, gzip's gunzip.exe,
# gnumake's make.exe, gnused's sed.exe, and so on -- see each package's own
# build.kaem "install" section); coreutils alone installs bare names (cp,
# mkdir, ...). This chain's own PATH search has no PATHEXT-style ".exe"
# fallback (found directly: `tar xf` and `gunzip -c`, with tar.exe/
# gunzip.exe genuinely present on PATH, both fail "command not found").
# autoconf-generated ./configure scripts and plain Makefiles invoke sed,
# grep, awk, make and the rest by their bare, extensionless names
# throughout -- not just this script's own two calls above -- so the fix
# has to be general: a shim directory of bare-named copies of every .exe
# in this chain's own (non-gcc) userland, ahead of the real bin dirs on
# PATH. gccBin is deliberately excluded here -- "gcc"/"cc" get the
# cc-wrapper.sh shim below instead, not a bare pass-through alias, and
# nothing above the compiler needs cc1.exe/as.exe by their own bare names.
toolShims="$builddir/tool-shims"
mkdir -p "$toolShims"
for dir in "$binutilsBin" "$gnusedBin" "$gnugrepBin" "$gawk5Bin" "$findutilsBin" "$diffutilsBin" "$gnumakeBin" "$gnupatchBin" "$gzipBin" "$gnutarBin" "$bashBin"; do
  for f in "$dir"/*.exe; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .exe)"
    cp "$f" "$toolShims/$base"
  done
done

# coreutils is the one package in this chain's userland that installs
# BARE names (see the comment above), and that is not only a spelling
# problem: ntlibc cannot execute a suffix-less file by PATH search at
# all.  src/process/find_program.c's __find_program tries each PATH
# entry as `dir\name' and then as `dir\name.exe', and gates both on
# access(p, X_OK) -- and ntlibc's access (src/unistd/access.c) is
# faccessat over its own stat, whose mode is synthesized from the
# FILENAME (src/stat/stat.c: a name ending .exe/.com/.bat/.cmd/.sh gets
# 0755, anything else 0644), NTFS having no per-file execute bit to
# read.  So bare `mkdir' fails X_OK, `mkdir.exe' does not exist, and
# every execvp of a coreutils name fails ENOENT no matter what is on
# PATH -- the same synthesized-permission wall the configure-phase
# comment below describes, reached from the other side.
#
# Measured directly, and it is what the PATH fix below alone did NOT
# solve: making PATH ';'-parseable, on its own, left libgreet's install
# recipe failing exactly as before with `make: mkdir: No such file or
# directory'.  That is the second half of the same wall -- ntlibc could
# now see $toolShims as a PATH entry and still could not execute
# anything in it under a bare name.  binutils, sed, grep, awk, make,
# patch, gzip, tar and bash all install real .exe files, so
# __find_program's own ".exe" append already resolves those once PATH
# parses; coreutils alone has no .exe to append to.
#
# The bare copies above are still what bash's own lookup uses; these are
# .exe-suffixed copies for ntlibc's.  Both names, one directory.
for f in "$coreutilsBin"/*; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  cp "$f" "$toolShims/$base.exe"
done

export PATH="$toolShims:$PATH"

# gnumake's own build.kaem patches default_shell from "/bin/sh" to bare
# "sh" (mirroring the Linux bootstrap's 0001-No-impure-bin-sh.patch), so
# make resolves its per-recipe shell by searching PATH -- but only ONE of
# this chain's two PATH consumers agrees on how PATH is delimited. bash's
# own command lookup (general.c's get_next_path_element, unpatched by
# windows.patch) hardcodes ':', same as every Unix bash; ntlibc's execvp
# (src/process/find_program.c) parses PATH as the *Windows* variable,
# entries split on ';' -- by design, not a bug (see that file's own
# top-of-file comment). This chain's PATH is colon-joined for bash's sake,
# which means the entire string is one non-existent ';'-delimited
# directory as far as ntlibc's execvp is concerned: every bare-name
# execvp() call -- not just this one -- fails ENOENT no matter what is
# actually on PATH. Measured directly: gnumake's shell search for bare
# "sh" failed this exact way even with $bashBin's sh.exe correctly on
# PATH and shimmed bare into $toolShims.
#
# The fix is not to switch PATH's own delimiter (bash's internal lookup,
# used for every recipe command make itself does NOT exec by shell-search,
# needs ':' throughout). It is to give make an absolute path so it never
# reaches PATH search at all: job.c's construct_command_argv checks $SHELL
# before falling back to default_shell, and ntlibc's find_program takes
# any name containing '/' as-is (its has_dir() check), skipping PATH
# search entirely. $toolShims/sh is exactly that -- an absolute path to
# the same sh.exe copy already shimmed above.
export SHELL="$toolShims/sh"

# --- dependency flags ---
# Start from EMPTY flag sets: host-inherited CPPFLAGS/LDFLAGS would inject
# ambient -I/-L directories ahead of the declared buildInputs, silently
# leaking undeclared dependencies into every configure/make line.
CPPFLAGS=""
LDFLAGS=""
for dep in $buildInputs; do
  CPPFLAGS="$CPPFLAGS -I$dep/include"
  LDFLAGS="$LDFLAGS -L$dep/lib"
  PATH="$PATH:$dep/bin"
done
export CPPFLAGS LDFLAGS PATH

# --- cc-wrapper: route every compiler call through our -S+tcc shim ---
# Installed under "gcc" and "cc", ahead of the real gcc.exe on PATH -- see
# cc-wrapper.sh for what it does and why. ar/ranlib/nm/objcopy need no
# wrapper (binutilsBin above already puts the real ones on PATH).
#
# $CC is exported as "$toolShims/sh $wrapperBin/gcc" -- two words, not the
# bare "gcc" this used to be -- because a bare PATH-resolved invocation of
# wrapperBin/gcc goes through a real, measured EACCES, not a synthesized
# one. wrapperBin/gcc is a text script (cc-wrapper.sh's own #!/bin/bash
# shebang); ntlibc's chmod (src/stat/chmod.c, its own comment: "chmod can
# only express one thing on NTFS: whether the file is read-only") has no
# way to grant it a real host execute bit, NTFS having no such per-file
# attribute at all. Confirmed with strace -f across a full hello build:
# wine's own process-launch path, handed a non-PE target, tries a raw host
# execve() of it first (`execve(".../wrappers/gcc", ["gcc","--version"],
# ...) = -1 EACCES`) -- a real permission denial, the file genuinely has
# no x bit on the host, not this chain's own synthesized-by-suffix stat()
# question -- and on that failure falls back to reading the shebang line
# and re-launching with the named interpreter as a raw HOST process
# (`execve(".../z:/bin/bash", ["/bin/bash", ".../wrappers/gcc", ...])`),
# escaping wine/ntlibc entirely into a genuinely native Linux bash. That
# escaped bash is what was actually producing every other anomaly in the
# same build: real /bin/uname and /usr/bin/arch (the coordinator's own
# suspicion, confirmed -- not a PATH leak, a real native process), pwd's
# write error, xargs' missing echo, and -- the actual blocker -- a raw
# native execve() of gcc.exe/tcc with no wine translation at all, which
# the kernel cannot run (no PE/wine entry in /proc/sys/fs/binfmt_misc on
# this host, confirmed directly), falling through binfmt_misc's only
# registered wildcard (mono's "cli" detector) to run-detectors, which also
# has nothing for it: "unable to find an interpreter for gcc.exe".
#
# $toolShims/sh is a real PE binary (a copy of this chain's own bash.exe,
# already proven throughout this chain's every earlier stage), so wine's
# normal in-process PE loader handles it directly -- no raw host execve,
# no shebang fallback, no escape. wrapperBin/gcc as a plain argument to it
# is never itself exec'd by anything; sh only ever reads it as script text.
wrapperBin="$builddir/wrappers"
mkdir -p "$wrapperBin"
cp "$ccWrapperSrc" "$wrapperBin/gcc"
cp "$ccWrapperSrc" "$wrapperBin/cc"
chmod +x "$wrapperBin/gcc" "$wrapperBin/cc"
export PATH="$wrapperBin:$PATH"
#
# $toolShims/bash, not $toolShims/sh: cc-wrapper.sh needs real bash, not
# POSIX-mode bash. Both are the same bash.exe binary copied under two
# bare names, and bash inspects its own argv[0] to decide which mode to
# start in -- named "sh", it disables its own extensions, array syntax
# (incFlags=(...), sources=(), and every other array this script uses)
# included, which is a syntax error under sh-mode, not just a behaviour
# change. Measured directly: `wine sh.exe cc-wrapper.sh -o a.exe x.c`
# outside the whole build, in isolation, up against this exact repo's
# cc-wrapper.sh -- "cc-wrapper.sh: line 48: syntax error near unexpected
# token `('" (line 48 is incFlags=( ... ), the first array in the file).
# ./configure above stays on $toolShims/sh deliberately: it is a plain
# #!/bin/sh script with no bash extensions of its own, so sh-mode is the
# right mode for it, not just a tolerated one.
export CC="$toolShims/bash $wrapperBin/gcc"

# --- and the same absolute-path rule for the archiver ---
# $CC above is absolute for a reason specific to the cc-wrapper (a text
# script wine cannot exec), but there is a second, entirely separate
# reason every tool name a Makefile invokes has to be absolute here, and
# it applies to real .exe binaries too: the ':'-vs-';' PATH split
# documented at $SHELL above.  make does not route every recipe line
# through $SHELL -- GNU make's construct_command_argv_internal takes a
# fast path for any line with no shell metacharacters and execs the
# program directly, which reaches ntlibc's execvp
# (src/process/find_program.c) and its Windows-style ';'-delimited PATH
# parse.  This chain's PATH is colon-joined for bash's sake, so every
# such bare-name exec fails ENOENT no matter what is on PATH.
#
# Measured directly, and this is exactly how it surfaces: libgreet's own
# Makefile has two recipe lines, `$(CC) -c greet.c -o greet.o` and
# `$(AR) rcs libgreet.a greet.o`.  The first succeeded -- $CC is absolute
# -- and the second failed with `make: ar: No such file or directory`
# with $toolShims/ar (a real bare-named copy of binutils' own ar.exe)
# present and on PATH the whole time.
#
# AR and RANLIB are what a Makefile actually spells (`AR ?= ar` is the
# conventional line, and make's own built-in default for $(AR) is the
# bare name "ar"), so those are the two exported here.  nm/objcopy/ld are
# not: nothing in this package set invokes them from a Makefile, and a
# package that does should get its own absolute value rather than have
# this list grow speculatively.
export AR="$toolShims/ar"
export RANLIB="$toolShims/ranlib"

# --- and, for every bare name NOT reachable through a Makefile variable ---
# $CC/$AR/$RANLIB above only cover the names a Makefile happens to spell
# as a variable.  libgreet's install recipe spells `mkdir -p ...` and
# `cp ...` outright, and there is no $(MKDIR)/$(CP) to override: with
# $AR fixed, the very next failure was `make: mkdir: No such file or
# directory`, same fast-path execvp, same ';'-vs-':' PATH split.  That
# class of line cannot be fixed one variable at a time, so PATH itself
# is made to satisfy both parsers at once.
#
# It can be, because the two parsers disagree on the separator and on
# nothing else, and each ignores an entry it cannot resolve:
#
#   bash 2.05b   general.c's extract_colon_unit, line 601:
#                  for (start = i; string[i] && string[i] != ':'; i++)
#                ':' is hardcoded, and findcmd.c's get_next_path_element
#                turns an EMPTY element into "." -- so no empty element
#                may be introduced here.
#   ntlibc       src/process/find_program.c's __find_program:
#                  const char *e = strchr(p, ';');
#                ';' is hardcoded ("a ':' cannot be the separator because
#                every absolute entry (\"C:\\Windows\") contains one" --
#                that file's own comment), and a directory that does not
#                resolve simply fails its access(X_OK) and is skipped.
#
# Both read verbatim from the sources this chain actually builds
# (bash-2.05b's own tarball and the pinned ntlibc source), not assumed.
#
# So: keep the colon-joined list bash needs, append one guard element,
# then repeat the same directories semicolon-joined.  Given a colon list
# "A:B:C", PATH becomes "A:B:C:/nova-nix-nt-path-guard;A;B;C" and
#
#   bash    splits on ':'  -> A, B, C, "/nova-nix-nt-path-guard;A;B;C"
#   ntlibc  splits on ';'  -> "A:B:C:/nova-nix-nt-path-guard", A, B, C
#
# Each parser sees every real directory in its own order, plus exactly
# one trailing/leading junk entry the other side's separator created,
# which is a non-existent directory to both and is skipped rather than
# searched.  The guard is what keeps A alive for ntlibc: without it the
# ';' split would swallow A into the first junk entry.  It is a literal
# non-existent absolute path, never an empty element, so bash's
# empty-means-"." rule is not triggered.
#
# This is done ONCE, here, after every earlier PATH mutation (the base
# list, $toolShims, the $buildInputs bin dirs and $wrapperBin) has
# already happened -- rewriting it earlier would only be undone by the
# next prepend.
ntPath="$(echo "$PATH" | sed 's/:/;/g')"
export PATH="$PATH:/nova-nix-nt-path-guard;$ntPath"

prefix="$out"

# --- unpack phase ---
mkdir -p "$builddir/src"
cd "$builddir/src"
if [ -d "$src" ]; then
  cp -r "$src"/. .
else
  case "$src" in
    *.tar.gz | *.tgz)
      gunzip -c "$src" > src.tar
      tar xf src.tar
      ;;
    *.tar.xz | *.txz)
      # $unxzBin is stage0's own mescc-tools-extra unxz (stdenv/default.nix's
      # own comment says why nothing else in this chain's userland can do
      # this) -- and it carries a real, well-documented bug, worked around
      # here exactly the way every .tar.xz already vendored by this
      # bootstrap does (../bootstrap/findutils/build.kaem's own comment is
      # the fullest writeup; binutils, diffutils and gcc all carry the same
      # workaround). unxz writes its output a byte at a time with fputc and
      # returns from main() without fclose()ing or fflush()ing, so the last
      # partial 4096-byte buffer is silently dropped: output truncated to
      # floor(N/4096)*4096, exit status 0 regardless. Doubling the input as
      # two concatenated .xz streams fixes it for any real tarball: unxz
      # decompresses both and emits 2N bytes, truncated to
      # floor(2N/4096)*4096, which for any N >= 4096 is strictly greater
      # than 2N - 4096 >= N, so the whole first copy always survives; tar
      # reads the first archive and stops at its own end-of-archive marker,
      # so the (truncated) second copy is never unpacked.
      cat "$src" "$src" > doubled.tar.xz
      "$unxzBin" --file doubled.tar.xz --output src.tar
      tar xf src.tar
      ;;
    *.tar)
      tar xf "$src"
      ;;
    *)
      echo "unpack: no decompressor for $src -- this chain's own userland" \
           "handles .tar, .tar.gz (gzip.exe, gnutar) and .tar.xz" \
           "(stage0's own unxz); .bz2 needs a decompressor this stdenv" \
           "does not yet have" >&2
      exit 1
      ;;
  esac
  # cd into the single unpacked top-level directory. Anything else is
  # ambiguous -- silently picking one would build the alphabetically-first
  # entry of a multi-directory tarball -- so fail loudly instead.
  set -- */
  if [ "$#" -eq 1 ] && [ -d "$1" ]; then
    cd "$1"
  else
    echo "unpack: expected exactly one top-level directory in $src, got: $*" >&2
    exit 1
  fi
fi

# --- configure phase (autotools packages only) ---
# $dontConfigure skips this -- for packages with no ./configure, or that
# build via a hand-written makefile.
#
# Tested with [ -x ./configure ] before, and that guard was always false:
# ntlibc's stat() (src/stat/stat.c) has no shebang-sniffing ("which is not
# cheap here" -- that file's own comment), so it synthesizes the execute
# bit from the filename suffix alone (.exe/.com/.bat/.cmd/.sh -> 0755,
# anything else -> 0644) regardless of the tarball's real Unix mode bit.
# "configure" has no such suffix, so the guard was unconditionally false,
# every package's configure phase silently no-op'd (no error under set -e
# -- a false `if` isn't one), and make ran against a source tree with no
# Makefile -- measured directly against GNU hello: its GNUmakefile's own
# fallback path is `abort-due-to-no-makefile`, which is what "make: sh: No
# such file or directory" was actually coming from, not a broken shell
# lookup. Existence is the right test; running the script through this
# stdenv's own sh explicitly (not a direct ./configure exec, which would
# hit the same synthesized-permission wall as bash's own exec()) is the
# right way to invoke a suffix-less script here, the same reasoning as
# $SHELL above.
if [ -z "$dontConfigure" ] && [ -e ./configure ]; then
  "$toolShims/sh" ./configure --prefix="$prefix" $configureFlags
fi

# --- build phase ---
# $buildPhase overrides the default for packages that build differently
# (e.g. `make -f win32/Makefile.gcc`). It runs in the unpacked source dir,
# with $prefix and the toolchain already in scope.
if [ -n "$buildPhase" ]; then
  eval "$buildPhase"
else
  make $makeFlags
fi

# --- install phase ---
# $installPhase overrides the default the same way.
if [ -n "$installPhase" ]; then
  eval "$installPhase"
else
  make install prefix="$prefix"
fi

# --- fixup phase: bundle non-system DLLs so outputs are self-contained ---
# This chain has no shared-runtime DLLs of its own yet (gcc.exe/cc1.exe/
# ntlibc are all statically linked into each output by tcc's own -nostdlib
# link line in cc-wrapper.sh), so there is, for now, nothing for this phase
# to bundle beyond what a package's own buildPhase/installPhase already
# produced. Left as a real phase (not deleted) so a future DLL-producing
# package on this stdenv has somewhere to hook a real fixup, the same way
# the old MSYS2-seed stdenv's own fixupPhase did for mingw-produced DLLs.
