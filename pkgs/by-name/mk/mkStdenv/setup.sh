set -eu

# The tool directories mkStdenv computed, under a name that survives the trip.
#
# A derivation's PATH attribute CANNOT be delivered to a Windows builder as
# PATH.  wine's dlls/ntdll/unix/env.c:331-340 (is_special_env_var) imports a
# Unix `PATH=' into the Win32 environment as WINE_HOST_PATH -- along with
# PWD, HOME, TEMP, TMP, TMPDIR and every XDG_* -- and the Win32 PATH the
# builder actually sees is rebuilt from the registry instead
# (add_registry_environment, same file).  Measured, not inferred: libgreet
# failed at this script's first `mkdir' with "command not found" while its
# own derivation's PATH named a coreutils bin dir that was present the whole
# time.  $stdenvToolPath carries the identical list under a name wine leaves
# alone; PATH is rebuilt from it here, on both platforms, so there is one
# rule rather than a per-platform one.
#
# It is also what the Windows section further down shims: that section needs
# the *tool* directories on their own, without a package's buildInputs mixed
# in, so the value is kept as well as exported.
stdenvToolPath="${stdenvToolPath-${PATH-}}"
export PATH="$stdenvToolPath"

# Bootstrap-sized nixpkgs generic setup. Inputs are discovered before they are
# activated: propagated dependency files are followed recursively, then each
# input's nix-support/setup-hook is sourced.

runHook() {
    local hookName="$1" hookValue hooksName hookValues hook
    shift

    if test "$(type -t "$hookName" 2>/dev/null || :)" = function; then
        "$hookName" "$@"
    else
        eval "hookValue=\${$hookName-}"
        if test -n "$hookValue"; then
            eval "$hookValue"
        fi
    fi

    hooksName="${hookName%Hook}Hooks"
    eval "hookValues=\${$hooksName-}"
    for hook in $hookValues; do
        if test "$(type -t "$hook" 2>/dev/null || :)" = function; then
            "$hook" "$@"
        else
            eval "$hook"
        fi
    done
}

addHook() {
    local hookName="${1%Hook}Hooks" hook="$2"
    eval "$hookName=\"\${$hookName-} $hook\""
}

addToSearchPath() {
    local varName="$1" path="$2" oldPath
    test -d "$path" || return 0
    eval "oldPath=\${$varName-}"
    if test -n "$oldPath"; then
        eval "$varName=\"$oldPath:$path\""
    else
        eval "$varName=\"$path\""
    fi
    export "$varName"
}

# Store paths cannot contain whitespace. These six accumulators correspond to
# nixpkgs' build/build, build/host, build/target, host/host, host/target and
# target/target dependency roles, but also work with the bootstrap's Bash 2.05.
pkgsBuildBuild=""
pkgsBuildHost=""
pkgsBuildTarget=""
pkgsHostHost=""
pkgsHostTarget=""
pkgsTargetTarget=""

setAccumVar() {
    case "$1:$2" in
        -1:-1) accumVar=pkgsBuildBuild ;;
        -1:0) accumVar=pkgsBuildHost ;;
        -1:1) accumVar=pkgsBuildTarget ;;
        0:0) accumVar=pkgsHostHost ;;
        0:1) accumVar=pkgsHostTarget ;;
        1:1) accumVar=pkgsTargetTarget ;;
        *) echo "invalid dependency role $1:$2" >&2; exit 1 ;;
    esac
}

inputSeen() {
    local roleInputs
    setAccumVar "$2" "$3"
    eval "roleInputs=\${$accumVar-}"
    case " $roleInputs " in
        *" $1 "*) return 0 ;;
        *) return 1 ;;
    esac
}

findInputs() {
    local pkg="$1" hostOffset="$2" targetOffset="$3"
    local depSpec relHost depRest relTarget depFile nextHost nextTarget propagatedLine propagatedInput
    inputSeen "$pkg" "$hostOffset" "$targetOffset" && return 0
    test -e "$pkg" || {
        echo "build input $pkg does not exist" >&2
        exit 1
    }
    setAccumVar "$hostOffset" "$targetOffset"
    eval "$accumVar=\"\${$accumVar-} $pkg\""

    for depSpec in \
        '-1:-1:propagated-build-build-deps' \
        '-1:0:propagated-native-build-inputs' \
        '-1:1:propagated-build-target-deps' \
        '0:0:propagated-host-host-deps' \
        '0:1:propagated-build-inputs' \
        '1:1:propagated-target-target-deps'
    do
        relHost=${depSpec%%:*}
        depRest=${depSpec#*:}
        relTarget=${depRest%%:*}
        depFile=${depRest#*:}

        if test "$relHost" -le 0; then nextHost=$((relHost + hostOffset)); else nextHost=$((relHost - 1 + targetOffset)); fi
        if test "$relTarget" -le 0; then nextTarget=$((relTarget + hostOffset)); else nextTarget=$((relTarget - 1 + targetOffset)); fi
        test "$nextHost" -ge -1 && test "$nextHost" -le 1 || continue
        test "$nextTarget" -ge -1 && test "$nextTarget" -le 1 || continue
        test "$nextHost" -le "$nextTarget" || continue

        if test -f "$pkg/nix-support/$depFile"; then
            while read propagatedLine; do
                for propagatedInput in $propagatedLine; do
                    findInputs "$propagatedInput" "$nextHost" "$nextTarget"
                done
            done < "$pkg/nix-support/$depFile"
        fi
    done
}

: "${depsBuildBuild=}" "${depsBuildBuildPropagated=}" \
  "${nativeBuildInputs=}" "${propagatedNativeBuildInputs=}" \
  "${depsBuildTarget=}" "${depsBuildTargetPropagated=}" \
  "${depsHostHost=}" "${depsHostHostPropagated=}" \
  "${buildInputs=}" "${propagatedBuildInputs=}" \
  "${depsTargetTarget=}" "${depsTargetTargetPropagated=}" \
  "${defaultNativeBuildInputs=}" "${defaultBuildInputs=}"

for pkg in $depsBuildBuild $depsBuildBuildPropagated; do findInputs "$pkg" -1 -1; done
for pkg in $nativeBuildInputs $propagatedNativeBuildInputs; do findInputs "$pkg" -1 0; done
for pkg in $depsBuildTarget $depsBuildTargetPropagated; do findInputs "$pkg" -1 1; done
for pkg in $depsHostHost $depsHostHostPropagated; do findInputs "$pkg" 0 0; done
for pkg in $buildInputs $propagatedBuildInputs; do findInputs "$pkg" 0 1; done
for pkg in $depsTargetTarget $depsTargetTargetPropagated; do findInputs "$pkg" 1 1; done
# Default inputs are intentionally discovered last, exactly as in nixpkgs.
for pkg in $defaultNativeBuildInputs; do findInputs "$pkg" -1 0; done
for pkg in $defaultBuildInputs; do findInputs "$pkg" 0 1; done

activatePackage() {
    local pkg="$1" hostOffset="$2"
    # Match nixpkgs' native-input PATH rule. In non-strict builds every input
    # remains visible for compatibility; strict cross builds expose only tools
    # whose host is the build platform.
    if test -z "${strictDeps-}" || test "$hostOffset" -le -1; then
        addToSearchPath PATH "$pkg/bin"
    fi
    if test -f "$pkg/nix-support/setup-hook"; then
        setupHookPath="$pkg/nix-support/setup-hook"
        . "$setupHookPath"
    fi
}

for pkg in $pkgsBuildBuild $pkgsBuildHost $pkgsBuildTarget; do activatePackage "$pkg" -1; done
for pkg in $pkgsHostHost $pkgsHostTarget; do activatePackage "$pkg" 0; done
for pkg in $pkgsTargetTarget; do activatePackage "$pkg" 1; done

# --- dependency flags ---
# Start from EMPTY flag sets: host-inherited CPPFLAGS/LDFLAGS would inject
# ambient -I/-L directories ahead of the declared buildInputs, silently
# leaking undeclared dependencies into every configure/make line.  This is
# what makes `stdenv.mkDerivation { buildInputs = [ libgreet ]; }` mean
# anything at all: greeter's own Makefile spells $(CPPFLAGS)/$(LDFLAGS) and
# gets greet.h and -lgreet from here, nowhere else.
CPPFLAGS=""
LDFLAGS=""
for pkg in $pkgsHostHost $pkgsHostTarget; do
    CPPFLAGS="$CPPFLAGS -I$pkg/include"
    LDFLAGS="$LDFLAGS -L$pkg/lib"
done
export CPPFLAGS LDFLAGS

# ---------------------------------------------------------------------------
# --- Windows execution environment ---
# ---------------------------------------------------------------------------
# Everything from here to the end of this `if' exists because this chain's
# Windows side runs under wine, on ntlibc, with a bash-2.05b that does not
# agree with ntlibc about what PATH even is.  Each item below was found by
# driving the real binaries; none of it is defensive.  $windowsStdenv is set
# only by the Windows stdenv (see st/stdenv/package.nix), so the whole block
# is inert on Linux.
#
# There is no cygdrive-style path mapping anywhere in here, unlike the old
# MSYS2-seed stdenv this chain replaced: bash and every tool it built are
# ntlibc-linked native programs, not a POSIX-emulation layer over Win32
# paths, and every earlier kaem-driven package in this chain already passes
# /nix/store paths straight through to them with no translation -- so
# neither does this.
if test -n "${windowsStdenv-}"; then

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

# ... and chdir there, so that every path the build derives from $PWD from
# here on -- `pwd`, configure's own ac_pwd, a Makefile's $(CURDIR) -- is in
# the form this chain can actually chdir BACK to.  Measured: with the drive
# letter left in place, GNU hello's configure died on its very first sanity
# check (the `ac_pwd_ls_di=`cd "$ac_pwd" && ls -di .`' round trip) with
#   ./configure: line 1: cd: Z:/tmp/.../hello-2.12.3: No such file or directory
#   configure: error: working directory cannot be determined
# -- bash's own `pwd' produced a drive-lettered form that bash's own `cd'
# then refused.  This is the same asymmetry the mkdir note above describes,
# reached from the other end.
cd "$builddir"

# All of this stdenv's own scratch lives under ONE dot-prefixed directory.
# That is not cosmetic: unpackPhase below decides the source root with
# `set -- *', and a visible tmp/, tool-shims/ or wrappers/ sitting next to
# the unpacked tarball would make that check see more than one entry and
# fail.  A leading dot is invisible to the glob and to nothing else.
scratch="$builddir/.nn-stdenv"
mkdir -p "$scratch/tmp"
export TMPDIR="$scratch/tmp" TMP="$scratch/tmp" TEMP="$scratch/tmp"

# --- bare-name and .exe-suffixed tool shims ---
# Two separate, independently-measured problems, one directory.
#
# (a) Every package in this chain's own userland except coreutils installs
# its binaries with a real .exe suffix (gnutar's tar.exe, gzip's gunzip.exe,
# gnumake's make.exe, gnused's sed.exe, and so on -- see each package's own
# build.kaem "install" section); coreutils alone installs bare names (cp,
# mkdir, ...). This chain's own bash PATH search has no PATHEXT-style ".exe"
# fallback (found directly: `tar xf' and `gunzip -c', with tar.exe/
# gunzip.exe genuinely present on PATH, both fail "command not found").
# autoconf-generated ./configure scripts and plain Makefiles invoke sed,
# grep, awk, make and the rest by their bare, extensionless names
# throughout, so the fix has to be general: bare-named copies of every .exe
# in this chain's userland, ahead of the real bin dirs on PATH.
#
# (b) The mirror image, and it is not merely a spelling problem: ntlibc
# cannot execute a suffix-less file by PATH search AT ALL.
# src/process/find_program.c's __find_program tries each PATH entry as
# `dir\name' and then as `dir\name.exe', and gates both on access(p, X_OK)
# -- and ntlibc's access (src/unistd/access.c) is faccessat over its own
# stat, whose mode is synthesized from the FILENAME (src/stat/stat.c: a name
# ending .exe/.com/.bat/.cmd/.sh gets 0755, anything else 0644), NTFS having
# no per-file execute bit to read.  So bare `mkdir' fails X_OK, `mkdir.exe'
# does not exist, and every execvp of a coreutils name fails no matter what
# is on PATH.  Measured directly, and it is what the PATH fix further down
# alone did NOT solve: making PATH ';'-parseable, on its own, left libgreet's
# install recipe failing exactly as before with `make: mkdir: No such file or
# directory'.
#
# A fix for (b) is in flight upstream in ntlibc but has NOT landed, and
# nothing coming fixes (a).  Both halves stay.
#
# So: for every tool binary, install BOTH spellings into one directory --
# the bare name for bash's exact-name lookup, the .exe name for ntlibc's.
# $compilerBin is deliberately excluded: "gcc"/"cc" get the native
# cc-wrapper shim below instead of a bare pass-through alias, and nothing
# above the compiler needs cc1.exe/as.exe by their own bare names.
toolShims="$scratch/tool-shims"
mkdir -p "$toolShims"
shimOldIFS="$IFS"
IFS=":"
set -- $stdenvToolPath
IFS="$shimOldIFS"
for dir in "$@"; do
  test -n "$dir" || continue
  test "$dir" != "${compilerBin-}" || continue
  test -d "$dir" || continue
  for f in "$dir"/*; do
    test -f "$f" || continue
    # basename-with-.exe-stripped, without exec'ing basename: one fewer
    # thing that has to already work before the shims exist.
    base="${f##*/}"
    base="${base%.exe}"
    cp "$f" "$toolShims/$base"
    cp "$f" "$toolShims/$base.exe"
  done
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
# execvp() call -- not just this one -- fails no matter what is
# actually on PATH. Measured directly: gnumake's shell search for bare
# "sh" failed this exact way even with bash's own sh.exe correctly on
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

# --- cc-wrapper: route every compiler call through the -S+tcc shim ---
# This chain's gcc.exe has two real, load-bearing gaps, both found by
# driving the real binary (see st/stage3/.../gcc_4_6_4/windows/build.kaem's
# own tail): `gcc.exe -c foo.c -o foo.o' never actually creates the
# driver-managed temporary, and full driver-mediated linking has never been
# proven at all.  cc-wrapper.c hides both: `-c' becomes `gcc.exe -S' plus
# `tcc -c' on the resulting assembly, and any real link is done by invoking
# tcc directly with the one proven recipe (-nostdlib, ntlibc's crt1.o,
# -L ntlibc/lib -lc -lntdll).
#
# It is compiled as a native PE, and that is NECESSARY, not a convenience.
# Wine's NtCreateUserProcess (dlls/ntdll/unix/process.c) escapes to the
# native host via fork_and_exec() whenever the exec TARGET is not a loadable
# PE.  A #!-script is not a PE, so wine execv()s the script itself and the
# LINUX KERNEL honours its `#!/bin/sh' line, running the HOST shell.  Three
# separate wine defects then bite: the spawn returns success with a NULL
# process handle (ntlibc maps STATUS_INVALID_HANDLE -> EBADF, exit 126); the
# escaped child's stdout goes to /dev/null; and a native unix child cannot
# inherit a Win32 pipe at all (CreatePipe builds an NT named pipe whose ends
# have no unix fd), so command substitution loses its output regardless.
# Two of those are not fixable upstream in the near term and the third is
# not enough on its own.  Rewriting a helper script's shebang is strictly
# worse, not better: wine never reads the shebang, the kernel does, and
# `#!/nix/store/.../sh.exe' names a PE with no binfmt_misc entry -- the
# "unable to find an interpreter for gcc.exe" wall, reached from a new
# direction.  Keeping every exec target a PE is the whole strategy.
#
# The extensionless copies serve bash's exact-name lookup; the .exe copies
# serve ntlibc's execvp lookup, exactly as for the tool shims above.
wrapperBin="$scratch/wrappers"
mkdir -p "$wrapperBin"
"$NN_TCC" \
  -B "$NN_NTLIBC_LIB" \
  -nostdinc \
  -I "$NN_NTLIBC_SRC_INCLUDE" \
  -I "$NN_NTLIBC_ARCH_I386" \
  -I "$NN_NTLIBC_ARCH_GENERIC" \
  -I "$NN_NTLIBC_INCLUDE" \
  -nostdlib "$NN_NTLIBC_LIB/crt1.o" \
  -o "$wrapperBin/gcc.exe" "$ccWrapperSrc" \
  -L "$NN_NTLIBC_LIB" -lc -lntdll
cp "$wrapperBin/gcc.exe" "$wrapperBin/gcc"
cp "$wrapperBin/gcc.exe" "$wrapperBin/cc.exe"
cp "$wrapperBin/gcc.exe" "$wrapperBin/cc"
chmod +x "$wrapperBin/gcc.exe" "$wrapperBin/gcc" "$wrapperBin/cc.exe" "$wrapperBin/cc"
export PATH="$wrapperBin:$PATH"
# Overrides the $CC mkStdenv put in the environment: the wrapper does not
# exist until the line above runs, so its path cannot be known at eval time,
# and the wrapper takes its ntlibc/gcc/tcc inputs from the NN_* variables
# rather than from flags on its own command line.
export CC="$wrapperBin/gcc.exe"

# --- and the same absolute-path rule for the archiver ---
# $CC above is absolute because make's fast path bypasses bash's PATH
# lookup. The same rule applies to every tool name a Makefile invokes, and
# it applies to real .exe binaries too: the ':'-vs-';' PATH split
# documented at $SHELL above.  make does not route every recipe line
# through $SHELL -- GNU make's construct_command_argv_internal takes a
# fast path for any line with no shell metacharacters and execs the
# program directly, which reaches ntlibc's execvp
# (src/process/find_program.c) and its Windows-style ';'-delimited PATH
# parse.  This chain's PATH is colon-joined for bash's sake, so every
# such bare-name exec fails no matter what is on PATH.
#
# Measured directly, and this is exactly how it surfaces: libgreet's own
# Makefile has two recipe lines, `$(CC) -c greet.c -o greet.o' and
# `$(AR) rcs libgreet.a greet.o'.  The first succeeded -- $CC is absolute
# -- and the second failed with `make: ar: No such file or directory'
# with $toolShims/ar (a real bare-named copy of binutils' own ar.exe)
# present and on PATH the whole time.
#
# AR and RANLIB are what a Makefile actually spells (`AR ?= ar' is the
# conventional line, and make's own built-in default for $(AR) is the
# bare name "ar"), so those are the two exported here.  nm/objcopy/ld are
# not: nothing in this package set invokes them from a Makefile, and a
# package that does should get its own absolute value rather than have
# this list grow speculatively.
export AR="$toolShims/ar"
export RANLIB="$toolShims/ranlib"

# --- and, for every bare name NOT reachable through a Makefile variable ---
# $CC/$AR/$RANLIB above only cover the names a Makefile happens to spell
# as a variable.  libgreet's install recipe spells `mkdir -p ...' and
# `cp ...' outright, and there is no $(MKDIR)/$(CP) to override: with
# $AR fixed, the very next failure was `make: mkdir: No such file or
# directory', same fast-path execvp, same ';'-vs-':' PATH split.  That
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
# list, the buildInputs bin dirs activatePackage added, $toolShims and
# $wrapperBin) has already happened -- rewriting it earlier would only be
# undone by the next prepend.  ${PATH//:/;} is bash-2.05b's own pattern
# substitution, used in place of a `sed' pipeline so this line does not
# itself depend on a subprocess.
export PATH="$PATH:/nova-nix-nt-path-guard;${PATH//:/;}"

fi
# --- end Windows execution environment ---

# CONFIG_SHELL, not SHELL.  configure's own line 284 is
#   SHELL=${CONFIG_SHELL-/bin/sh}
# an UNSET-ONLY default keyed on CONFIG_SHELL, so an exported $SHELL is
# discarded and clobbered to the literal string /bin/sh.  On Windows that is
# verbatim what the failure said: `configure: error: cannot run /bin/sh
# ./build-aux/config.sub', from configure:6864-6865
#   $SHELL "${ac_aux_dir}config.sub" sun4 >/dev/null 2>&1 ||
#     as_fn_error $? "cannot run $SHELL ${ac_aux_dir}config.sub" ...
# -- $SHELL already expanded, /bin/sh being a HOST path this chain has no
# business exec'ing.  Setting CONFIG_SHELL instead also drives configure's
# own re-exec (configure:134's `exec $CONFIG_SHELL ...'), skips the shell
# hunt at :142-282 (which otherwise scans /bin, /usr/bin and $PATH for a
# host shell), and reaches Makefile.in's `SHELL = @SHELL@' -- make's recipe
# shell for the whole build AND install phase -- and config.status
# (configure:33083).
export CONFIG_SHELL="${CONFIG_SHELL-$SHELL}"

unpackPhase() {
    runHook preUnpack
    if test -d "$src"; then
        if test -n "${windowsStdenv-}"; then
            # `cp -R src dest' with dest absent, and `chmod -R', are both
            # untested against this chain's coreutils 5.0 on ntlibc; copying
            # the contents of an existing directory is the form the Windows
            # side has actually driven.  Nothing here needs the u+w pass:
            # ntlibc synthesizes a file's mode from its name, so a store
            # path's read-only bit was never real to begin with.
            mkdir -p source
            cd source
            cp -r "$src"/. .
            cd ..
        else
            cp -R "$src" source
            chmod -R u+w source
        fi
        sourceRoot=source
    elif test -n "${windowsStdenv-}"; then
        # Every intermediate goes under $scratch, never next to the unpacked
        # tree: `set -- *' below would otherwise count src.tar as a second
        # top-level entry and reject the tarball.  Nothing here uses a pipe,
        # either -- see the cc-wrapper note above for why a Win32 pipe is
        # worth avoiding when a plain file will do.
        case "$src" in
            *.tar)
                tar xf "$src"
                ;;
            *.tar.gz | *.tgz)
                gunzip -c "$src" > "$scratch/src.tar"
                tar xf "$scratch/src.tar"
                ;;
            *.tar.xz | *.txz)
                # $unxzBin is stage0's own mescc-tools-extra unxz -- nothing
                # else in this chain's Windows userland can decompress xz at
                # all -- and it carries a real, well-documented bug, worked
                # around here exactly the way every .tar.xz already vendored
                # by this bootstrap does (st/stage2/.../findutils/windows's
                # own comment is the fullest writeup; binutils, diffutils and
                # gcc all carry the same workaround).  unxz writes its output
                # a byte at a time with fputc and returns from main() without
                # fclose()ing or fflush()ing, so the last partial 4096-byte
                # buffer is silently dropped: output truncated to
                # floor(N/4096)*4096, exit status 0 regardless.  Doubling the
                # input as two concatenated .xz streams fixes it for any real
                # tarball: unxz decompresses both and emits 2N bytes,
                # truncated to floor(2N/4096)*4096, which for any N >= 4096 is
                # strictly greater than 2N - 4096 >= N, so the whole first
                # copy always survives; tar reads the first archive and stops
                # at its own end-of-archive marker, so the (truncated) second
                # copy is never unpacked.
                cat "$src" "$src" > "$scratch/doubled.tar.xz"
                "$unxzBin" --file "$scratch/doubled.tar.xz" --output "$scratch/src.tar"
                tar xf "$scratch/src.tar"
                ;;
            *)
                echo "mkStdenv: no decompressor for $src -- this chain's Windows" \
                     "userland handles .tar, .tar.gz (gzip.exe, gnutar) and" \
                     ".tar.xz (stage0's own unxz)" >&2
                exit 1
                ;;
        esac
        if test -z "${sourceRoot-}"; then
            set -- *
            if test "$#" -ne 1 || ! test -d "$1"; then
                echo "mkStdenv: unpacking $src did not produce one directory" >&2
                exit 1
            fi
            sourceRoot="$1"
        fi
    else
        case "$src" in
            *.tar) tar xf "$src" ;;
            # The stage2 tar is GNU tar 1.12.  It predates compression
            # autodetection, so feed compressed archives to it explicitly.
            *.tar.gz|*.tgz) gzip -dc "$src" | tar xf - ;;
            *.tar.xz|*.txz) unxz -c "$src" | tar xf - ;;
            *) echo "mkStdenv: do not know how to unpack $src" >&2; exit 1 ;;
        esac
        if test -z "${sourceRoot-}"; then
            set -- *
            if test "$#" -ne 1 || ! test -d "$1"; then
                echo "mkStdenv: unpacking $src did not produce one directory" >&2
                exit 1
            fi
            sourceRoot="$1"
        fi
    fi
    cd "$sourceRoot"
    runHook postUnpack
}

patchPhase() {
    runHook prePatch
    for patch in ${patches-}; do
        if test -n "${windowsStdenv-}"; then
            # Avoid handing a redirected stdin descriptor through Wine.  The
            # ntlibc process stack can intermittently lose that descriptor;
            # GNU patch's input-file option keeps the file open in patch.exe.
            patch ${patchFlags--p1} -i "$patch"
        else
            patch ${patchFlags--p1} < "$patch"
        fi
    done
    runHook postPatch
}

configurePhase() {
    runHook preConfigure
    # Existence, not executability.  On Windows `test -x ./configure' is
    # unconditionally FALSE: ntlibc's stat() (src/stat/stat.c) does no
    # shebang sniffing ("which is not cheap here" -- that file's own
    # comment) and synthesizes the execute bit from the filename suffix
    # alone, and "configure" has no suffix.  That guard used to make this
    # whole phase a silent no-op -- a false `if' is not an error under
    # `set -e' -- and make then ran against a tree with no Makefile, which
    # is where GNU hello's `abort-due-to-no-makefile' fallback came from.
    if test -f ./configure; then
        if test -n "${windowsStdenv-}"; then
            windowsConfigureSetup
        fi
        "$CONFIG_SHELL" ./configure --prefix="$out" ${configureFlags-}
    fi
    runHook postConfigure
}

# Two more presets configure needs on Windows, because it does not route
# every subprocess through the shell it is handed.  Split out of
# configurePhase so a package overriding that phase can still call it.
windowsConfigureSetup() {
    # Autoconf's end-of-run cache serializer and exit-trap diagnostic dump are
    # nests of command substitutions and pipelines.  Under this chain's
    # bash/ntlibc process stack, every pipeline reader retains its own write
    # handle, so each nest waits forever for EOF after configure has completed
    # all of its actual feature checks.  GNU hello 2.12.3 reaches the first at
    # the `cat >confcache' block immediately after deciding whether to use NLS
    # and the second after config.status has generated every output: in each
    # case several sh.exe processes sleep in read(2) while holding both ends
    # of their input pipe open.
    #
    # The generic builder does not request a config cache, so serializing one
    # has no value here; the trap's variable dump is diagnostic-only.  Remove
    # both generated blocks when the script has Autoconf's standard cache
    # marker.  Keep this conditional: hand-written configure scripts, and
    # generated versions with a different cache implementation, pass through
    # byte-for-byte instead of being guessed at.  The trap remains installed,
    # still records the exit status, and still performs its cleanup.
    if grep -q '^cat >confcache <<\\_ACEOF$' ./configure; then
        configureNoCache="$scratch/configure-no-cache"
        sed '
/^  # Save into config.log some information that might help in debugging\.$/,/^  } >&5$/c\
  echo "$as_me: exit $exit_status" >&5
/^cat >confcache <<\\_ACEOF$/,/^rm -f confcache$/c\
: # nova-nix: cache serialization disabled for the Windows process stack
' ./configure > "$configureNoCache"
        cp "$configureNoCache" ./configure
    fi

    # ac_executable_extensions: the general answer to the synthesized-exec-bit
    # wall described at the tool shims above, for every AC_PATH_PROG /
    # AC_CHECK_PROG in the script.  Each probe accepts a candidate only
    # through
    #   as_fn_executable_p () { test -f "$1" && test -x "$1"; }
    # (configure:372-375), and `test -x' is unconditionally false for an
    # extensionless file here.  The search loop is
    #   for ac_exec_ext in '' $ac_executable_extensions; do
    #     ac_path_FOO="$as_dir$ac_prog$ac_exec_ext"
    #     as_fn_executable_p "$ac_path_FOO" || continue
    # so with the variable empty the ONLY name ever tried is the bare one,
    # which can never pass.  Measured: with CONFIG_SHELL and --build in
    # place, hello's next failure was
    #   configure: error: no acceptable egrep could be found in <PATH>
    # with gnugrep's grep.exe/egrep.exe/fgrep.exe present and on PATH the
    # whole time -- the probe simply never spelled the ".exe".
    #
    # This chain's userland installs real .exe files and the shim directory
    # above gives everything else a ".exe" spelling too, so ".exe" is the one
    # extension that makes every probe resolve.  It is the same thing
    # autoconf's own DJGPP/Cygwin support uses this variable for; ours is
    # simply not a case autoconf sets it for automatically.  The bare name is
    # still tried FIRST ('' leads the list) and still always fails, so this
    # cannot make a probe pick up a file it could not have executed anyway.
    export ac_executable_extensions=".exe"

    # INSTALL, because CONFIG_SHELL alone is NOT enough.  configure:4286 sets
    # ac_install_sh="${as_dir}install-sh -c" and :4506 does
    # INSTALL=$ac_install_sh with no $SHELL anywhere -- a direct-exec site.
    # It propagates through :4514-4518 into Makefile.in's own
    # INSTALL/INSTALL_DATA and fires across all of `make install'.
    #
    # And it is guaranteed to fire, not conditional on a missing system
    # install: the PATH probe at :4437 accepts a candidate only through
    # as_fn_executable_p, so an extensionless coreutils `install' can never
    # pass it and the install-sh fallback is always taken.
    #
    # Preset INSTALL rather than ac_cv_path_install because :4437 is
    # `if test -z "$INSTALL"; then' -- a preset short-circuits the probe
    # entirely -- and configure's own comment at :4499-4501 says that cache
    # var is deliberately not cached for a source dir.  The path must be
    # ABSOLUTE: config.status (configure:34119-34121) passes
    # `[\\/$]* | ?:[\\/]*' through untouched but glues $ac_top_build_prefix
    # onto anything relative -- onto the SHELL, not the script.  The
    # drive-letter strip mirrors $builddir above.  install-sh is named as an
    # ARGUMENT to a real PE shell, never exec'd directly, for the reason the
    # cc-wrapper comment gives.
    #
    # Deliberately NOT preset: am_cv_prog_cc_c_o.  configure:6397's
    # `CC="$am_aux_dir/compile $CC"' (gated on :6390) is a third potential
    # direct-exec site, but the cc-wrapper does support -c -o, so that cache
    # var should come out `yes' on its own.  Pinning it would hide a real
    # cc-wrapper regression behind a cache variable; let it fail visibly.
    local srcAbs auxdir
    srcAbs="$PWD"
    case "$srcAbs" in
      ?:*) srcAbs="${srcAbs#?:}" ;;
    esac
    for auxdir in . build-aux config scripts aux; do
        if test -e "./$auxdir/install-sh"; then
            export INSTALL="$CONFIG_SHELL $srcAbs/$auxdir/install-sh -c"
            break
        fi
    done
}

runMake() {
    # A makefile assignment overrides an exported SHELL.  Coreutils 5.0's
    # shipped GNUmakefile does exactly that with `SHELL = /bin/sh', before it
    # includes the configure-generated Makefile, so its first $(shell ...)
    # and every recipe otherwise try a nonexistent host path.  A command-line
    # variable has higher precedence than the makefile and still names the
    # same PE shell selected above.  Linux keeps make's ordinary semantics.
    if test -n "${windowsStdenv-}"; then
        make "SHELL=$SHELL" "$@"
    else
        make "$@"
    fi
}

buildPhase() {
    runHook preBuild
    if test -n "${buildScript-}"; then
        "$SHELL" -e "$buildScript"
    elif test -n "${buildRetries-}"; then
        # Opt-in recovery for large bootstrap builds whose young native
        # process/compiler stack can sporadically lose one child.  Keep-going
        # passes retain every successful object; the final ordinary make is
        # mandatory and is the only pass allowed to decide success.
        buildAttempt=1
        while test "$buildAttempt" -lt "$buildRetries"; do
            runMake -k ${makeFlags-} && break
            buildAttempt=$((buildAttempt + 1))
        done
        runMake ${makeFlags-}
    else
        runMake ${makeFlags-}
    fi
    runHook postBuild
}

checkPhase() {
    runHook preCheck
    runMake ${checkTarget-check} ${checkFlags-}
    runHook postCheck
}

installPhase() {
    runHook preInstall
    # prefix=$out on the command line, not just --prefix at configure time:
    # a hand-written Makefile (libgreet's, greeter's) has no ./configure to
    # have told it where $out is, and spells `prefix ?= /usr/local'.  An
    # autotools Makefile is handed the same value it already computed from
    # --prefix, so this is a no-op there.
    runMake install prefix="$out" ${installFlags-}
    runHook postInstall
}

fixupPhase() {
    runHook preFixup
    runHook fixupOutput
    recordPropagatedDependencies
    if test -n "${setupHook-}"; then
        mkdir -p "$out/nix-support"
        cp "$setupHook" "$out/nix-support/setup-hook"
    fi
    runHook postFixup
}

installCheckPhase() {
    runHook preInstallCheck
    runMake ${installCheckTarget-installcheck} ${installCheckFlags-}
    runHook postInstallCheck
}

distPhase() {
    runHook preDist
    runMake ${distTarget-dist} ${distFlags-}
    runHook postDist
}

recordPropagatedDependency() {
    local varName="$1" fileName="$2" values
    eval "values=\${$varName-}"
    test -n "$values" || return 0
    mkdir -p "$out/nix-support"
    printf '%s\n' $values > "$out/nix-support/$fileName"
}

recordPropagatedDependencies() {
    recordPropagatedDependency depsBuildBuildPropagated propagated-build-build-deps
    recordPropagatedDependency propagatedNativeBuildInputs propagated-native-build-inputs
    recordPropagatedDependency depsBuildTargetPropagated propagated-build-target-deps
    recordPropagatedDependency depsHostHostPropagated propagated-host-host-deps
    recordPropagatedDependency propagatedBuildInputs propagated-build-inputs
    recordPropagatedDependency depsTargetTargetPropagated propagated-target-target-deps
}

runPhase() {
    local curPhase="$1" phaseBody
    echo "Running phase: $curPhase"
    case "$curPhase" in
        unpackPhase) test -z "${dontUnpack-}" || return 0 ;;
        patchPhase) test -z "${dontPatch-}" || return 0 ;;
        configurePhase) test -z "${dontConfigure-}" || return 0 ;;
        buildPhase) test -z "${dontBuild-}" || return 0 ;;
        checkPhase) test -n "${doCheck-}" || return 0 ;;
        installPhase) test -z "${dontInstall-}" || return 0 ;;
        fixupPhase) test -z "${dontFixup-}" || return 0 ;;
        installCheckPhase) test -n "${doInstallCheck-}" || return 0 ;;
        distPhase) test -n "${doDist-}" || return 0 ;;
    esac
    eval "phaseBody=\${$curPhase-}"
    if test -n "$phaseBody"; then eval "$phaseBody"; else "$curPhase"; fi
}

genericBuild() {
    if test -n "${buildCommand-}"; then
        eval "$buildCommand"
        return
    fi
    if test -z "${phases-}"; then
        phases="${prePhases-} unpackPhase patchPhase ${preConfigurePhases-} configurePhase ${preBuildPhases-} buildPhase checkPhase ${preInstallPhases-} installPhase ${preFixupPhases-} fixupPhase installCheckPhase ${preDistPhases-} distPhase ${postPhases-}"
    fi
    for curPhase in $phases; do runPhase "$curPhase"; done
}

runHook preHook
genericBuild
runHook postHook
