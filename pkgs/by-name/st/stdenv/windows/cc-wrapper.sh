#!/bin/bash
# nova-nix stage-1 cc-wrapper, on this chain's own from-scratch toolchain.
#
# Installed onto the build's PATH under "gcc" and "cc", ahead of the real
# gcc.exe, so every compiler invocation flows through here. Exists to hide
# two real, proven gaps in bootstrap/gcc's own gcc.exe (see stdenv/default.nix
# for the full writeup, and bootstrap/gcc/build.kaem's own tail for where
# each was found):
#
#   1. `gcc.exe -c foo.c -o foo.o` never actually creates foo.o -- a real
#      libiberty mkstemps() bug reached through the driver's own temp-file
#      dance for the .s intermediate. The proven-working path is `-S`
#      (cc1 emits assembly directly, no temp file), so a `-c` invocation is
#      rewritten here into `gcc.exe ... -S` followed by this chain's own
#      tcc `-c` on the resulting assembly -- exactly the recipe
#      bootstrap/gcc/build.kaem's own installed-as-as.exe tcc is meant for,
#      just driven directly instead of through gcc.exe's own unverified
#      "as" exec.
#   2. gcc.exe has no working driver-mediated link at all (never attempted
#      by bootstrap/gcc's own build -- explicitly out of scope in its
#      default.nix). Any invocation that asks for a final linked
#      executable -- `-c`-then-link in one call, or a bare
#      `gcc foo.c -o foo.exe` -- is done here by compiling every .c source
#      the same -S+tcc-c way, then linking everything (those objects, any
#      .o/.a already on the command line, and any -l/-L already on it)
#      with tcc directly, using the exact recipe
#      bootstrap/gcc/build.kaem's own hello.exe functional test already
#      proved end to end: -nostdlib, ntlibc's own crt1.o, -lgcc from this
#      package's own libgcc.a, then -lc -lntdll last for ntlibc's own
#      syscall surface.
#
# `-S`, `-E`, `-M`/`-MM` invocations (preprocess-only, or cc1 emitting
# assembly directly -- neither one touches the driver's own broken
# temp-file path) are passed straight through to the real gcc.exe, plus
# this chain's own ntlibc include dirs appended so headers resolve even
# when a package's own -I list does not already cover arch/i386 or
# arch/generic (bootstrap/gcc's own baked-in CROSS_INCLUDE_DIR default
# only covers ntlibcSrc/include -- see its build.kaem's own
# "CROSS_INCLUDE_DIR / TOOL_INCLUDE_DIR" comment and the hello3.c
# zero-flag test it qualifies).
#
# `ar`/`ranlib` need no shim at all: binutils' own ar.exe/ranlib.exe (this
# chain's own binutils, already proven against tcc-produced objects by
# every earlier package in the chain) are put on PATH directly, unwrapped.
#
# No bash arrays anywhere in this file, on purpose: this chain's own bash
# (pkgs/by-name/ba/bash/windows) builds with an empty config.h (see that
# package's default.nix) and never defines ARRAY_VARS -- bash-2.05b's own
# config.h.in leaves it #undef by default, meaning array support
# (`var=(...)`, `var+=(...)`) is compiled out of this bash entirely, not
# merely mode-dependent. Measured directly: `wine bash.exe cc-wrapper.sh
# -o a.exe x.c`, invoked as plain "bash" (not "sh", so POSIX-mode was not
# the variable) still failed with "line 48: syntax error near unexpected
# token `('" -- line 48 was the first `incFlags=(...)` this file used to
# have. Every list below is a plain, space-separated string instead
# (matching $configureFlags/$makeFlags's own convention elsewhere in this
# stdenv), which costs nothing here: every path this whole chain passes
# around is a /tmp or /nix/store path, never one containing a space.

set -e

incFlags="-I$NN_NTLIBC_SRC_INCLUDE -I$NN_NTLIBC_ARCH_I386 -I$NN_NTLIBC_ARCH_GENERIC -I$NN_NTLIBC_INCLUDE"

realGcc="$NN_GCC/gcc.exe"

# --- classify the invocation ---
# allArgs: a copy of the original argument line, for passthrough mode
# below -- the while loop consumes "$@" itself via shift, so by the time
# passthrough mode is known, "$@" would otherwise be empty.
allArgs="$*"
mode=link
outFile=""
sources=""
otherArgs=""

while [ "$#" -gt 0 ]; do
  a="$1"
  case "$a" in
    -c)
      if [ "$mode" = link ]; then mode=compile; fi
      ;;
    -S | -E | -M | -MM)
      mode=passthrough
      ;;
    -o)
      shift
      outFile="$1"
      ;;
    *.c)
      sources="$sources $a"
      otherArgs="$otherArgs $a"
      ;;
    *)
      otherArgs="$otherArgs $a"
      ;;
  esac
  shift
done

if [ "$mode" = passthrough ]; then
  exec "$realGcc" $allArgs $incFlags
fi

# --- compile every .c source to a real object, via -S + tcc -c ---
# (the proven-working path for both `compile` and `link` mode: `link` mode
# still needs each source turned into an object before the final tcc link.)
objs=""
tmpdir="${TMPDIR:-.}/cc-wrapper.$$"
mkdir -p "$tmpdir"
trap 'rm -rf "$tmpdir"' EXIT

# otherArgs still contains the .c sources themselves (needed so gcc.exe's
# own -S call sees them alongside -I/-D/-O and the rest); build a
# source-free copy for the sole flags gcc.exe -S actually wants, adding
# -c/-o back in per-source below instead of trusting the original -c/-o.
flagsOnly=""
for a in $otherArgs; do
  case "$a" in
    *.c) ;;
    *) flagsOnly="$flagsOnly $a" ;;
  esac
done

# sourceCount: whether this is a single-source compile (the only case
# $outFile may name the object directly, matching gcc's own -c -o rule).
sourceCount=0
for src in $sources; do
  sourceCount=$((sourceCount + 1))
done

srcIndex=0
for src in $sources; do
  base="$(basename "$src" .c)"
  asmFile="$tmpdir/$base.$srcIndex.s"
  srcIndex=$((srcIndex + 1))

  "$realGcc" $flagsOnly $incFlags -S -o "$asmFile" "$src"

  if [ "$mode" = compile ] && [ -n "$outFile" ] && [ "$sourceCount" = 1 ]; then
    objFile="$outFile"
  else
    objFile="$base.o"
  fi

  "$NN_TCC" -c -o "$objFile" "$asmFile"
  objs="$objs $objFile"
done

if [ "$mode" = compile ]; then
  # Compile-only: done, nothing to link.
  exit 0
fi

# --- link mode: tcc directly, never gcc.exe's own (unverified) link ---
# Non-source args (already-compiled .o/.a, -l/-L, and anything else on the
# line) pass straight through to the link; only the .c sources were pulled
# out above to be compiled first.
linkArgs=""
for a in $otherArgs; do
  case "$a" in
    *.c) ;;
    *) linkArgs="$linkArgs $a" ;;
  esac
done

finalOut="${outFile:-a.exe}"

exec "$NN_TCC" \
  -B "$NN_NTLIBC_LIB" -nostdlib "$NN_NTLIBC_LIB/crt1.o" \
  -o "$finalOut" \
  $objs $linkArgs \
  -L "$NN_GCC_LIBDIR" -lgcc \
  -L "$NN_NTLIBC_LIB" -lc -lntdll
