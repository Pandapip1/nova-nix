# nova-nix stage-1 stdenv: the Windows genericBuild, on this chain's own
# from-scratch toolchain.
#
# Run by this chain's own bash.exe (bootstrap/bash) as a derivation's
# builder. stdenv/default.nix passes the package via the environment:
#   $src           source tarball or directory
#   $out           install prefix (the output store path)
#   $gccBin, $binutilsBin, $coreutilsBin, $gnusedBin, $gnugrepBin,
#   $gawk5Bin, $findutilsBin, $diffutilsBin, $gnumakeBin, $gnupatchBin,
#   $gzipBin, $gnutarBin       this chain's own userland, one bin dir each
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

export PATH="$coreutilsBin:$gnusedBin:$gnugrepBin:$gawk5Bin:$findutilsBin:$diffutilsBin:$gnumakeBin:$gnupatchBin:$gzipBin:$gnutarBin:$binutilsBin:$gccBin"

builddir="$PWD"
mkdir -p "$builddir/tmp"
export TMPDIR="$builddir/tmp" TMP="$builddir/tmp" TEMP="$builddir/tmp"

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
wrapperBin="$builddir/wrappers"
mkdir -p "$wrapperBin"
cp "$ccWrapperSrc" "$wrapperBin/gcc"
cp "$ccWrapperSrc" "$wrapperBin/cc"
chmod +x "$wrapperBin/gcc" "$wrapperBin/cc"
export PATH="$wrapperBin:$PATH"
export CC=gcc

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
    *.tar)
      tar xf "$src"
      ;;
    *)
      echo "unpack: no decompressor for $src -- this chain's own userland" \
           "only handles .tar and .tar.gz (gzip.exe, gnutar); .xz/.bz2 need" \
           "a decompressor this stdenv does not yet have" >&2
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
if [ -z "$dontConfigure" ] && [ -x ./configure ]; then
  ./configure --prefix="$prefix" $configureFlags
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
