# TinyCC rebuilt against musl.
#
# The tcc that got here was built against the Mes C library, and says so: its
# predefined macros include <mes/config.h>, so it cannot compile anything
# without that header on the include path.  This one is built against musl and
# knows nothing about Mes -- which is what makes it the compiler everything
# above uses.
#
# It is built twice.  0.9.27 is not self-hosting when linked against the Mes C
# library, but it is when linked against musl, so the first tcc-musl is
# produced by the old compiler and the second by itself.  The second is what
# is installed: a compiler that compiled itself is one whose output has been
# checked by the only test that matters here.
set -e

export PATH="$toolPath"

# The source arrives read-only, and ONE_SOURCE means tcc.c includes its
# siblings from its own directory -- so the tree has to be writable to patch
# it at all.
cd "$TMPDIR"
mkdir -p build
cp -r "$src"/. build/
chmod -R +w build
cd build

# Two edits, both from nixpkgs' minimal bootstrap.  The first teaches the
# assembler to name the r8-r15 registers, which it otherwise renders wrongly;
# the second makes a pointer difference use ptrdiff_t rather than size_t, so
# that adding a negative offset works.
sed -i 's|switch(size)|if (reg >= 8) { cstr_printf(add_str, "%r%d%c", reg, (size == 1) ? '"'"'b'"'"' : ((size == 2) ? '"'"'w'"'"' : ((size == 4) ? '"'"'d'"'"' : '"'"' '"'"'))); return; } switch(size)|' i386-asm.c
sed -i 's|vpush_type_size(pointed_type(\&vtop\[-1\].type), \&align);|vpush_type_size(pointed_type(\&vtop[-1].type), \&align); if (!(vtop[-1].type.t \& VT_UNSIGNED)) gen_cast_s(VT_PTRDIFF_T);|' tccgen.c

: > config.h

# tcc looks for libtcc1.a beside itself; musl's copy is the one to use until
# this build has made its own.
cp "$musl/lib/libtcc1.a" ./libtcc1.a

# The predefined macros, compiled in rather than read at runtime.
# -static because this tcc leaves CONFIG_TCC_ELFINTERP empty: a dynamically
# linked output names no interpreter and the kernel will not run it.
tcc -static -B "$mesLibs/lib" -DC2STR -o c2str conftest.c
./c2str include/tccdefs.h tccdefs_.h

build_tcc() {
  "$1" -v -static -o "$2" \
    -D TCC_TARGET_I386=1 \
    -D CONFIG_TCCDIR=\"\" \
    -D CONFIG_TCC_CRTPREFIX=\"{B}\" \
    -D CONFIG_TCC_ELFINTERP=\"/musl/loader\" \
    -D CONFIG_TCC_LIBPATHS=\"{B}\" \
    -D CONFIG_TCC_SYSINCLUDEPATHS=\"$musl/include\" \
    -D TCC_LIBGCC=\"libc.a\" \
    -D TCC_LIBTCC1=\"libtcc1.a\" \
    -D CONFIG_TCC_STATIC=1 \
    -D CONFIG_USE_LIBGCC=1 \
    -D TCC_VERSION=\"0.9.27\" \
    -D ONE_SOURCE=1 \
    -D TCC_MUSL=1 \
    -D CONFIG_TCC_PREDEFS=1 \
    -D CONFIG_TCC_SEMLOCK=0 \
    -D CONFIG_TCC_BACKTRACE=0 \
    -B . \
    -B "$3" \
    tcc.c
}

# First: built by the compiler that came before, which still needs its own
# library path.
build_tcc tcc tcc-musl "$mesLibs/lib"

# Its own libtcc1, compiled by the new compiler against musl.
#
# Both runtime sources, not just the C one.  libtcc1 is the compiler's
# runtime -- the helpers tcc emits calls to for arithmetic the instruction set
# will not do in one step -- and leaving half of it out is not a link error:
# the calls resolve to whatever else is around, and casts from floating point
# to integer quietly produce zero.
rm -f libtcc1.a
./tcc-musl -B "$musl/lib" -c -D HAVE_CONFIG_H=1 lib/libtcc1.c
./tcc-musl -B "$musl/lib" -c lib/alloca.S
./tcc-musl -B "$musl/lib" -ar libtcc1.a libtcc1.o alloca.o

# Second: built by itself.  This is the one that is kept.
build_tcc ./tcc-musl tcc-musl-2 "$musl/lib"

mkdir -p "$out/bin" "$out/lib"
cp tcc-musl-2 "$out/bin/tcc"
chmod 555 "$out/bin/tcc"

# -B names one directory, not a search path -- tcc's TCC_OPTION_B replaces the
# library path rather than appending to it, and this tcc resolves both
# CONFIG_TCC_CRTPREFIX and CONFIG_TCC_LIBPATHS from it.  So the crt objects and
# musl's archives are copied in beside libtcc1.a: everything a link needs is
# then reachable from a single -B, and no caller has to know that the C library
# lives somewhere else.
cp "$musl"/lib/*.a "$musl"/lib/*.o "$out/lib/"

# ... with the freshly built libtcc1.a last, so it wins over the copy musl
# carries, which was compiled by the older Mes-libc tcc.  The copy arrived
# read-only, as everything does from a store path, so it is removed rather
# than written over.
rm -f "$out/lib/libtcc1.a"
cp libtcc1.a "$out/lib/libtcc1.a"

"$out/bin/tcc" -v
