# GCC 4.6.4 with C++, compiled by the GCC 4.6.4 below it.
#
# The gcc that tcc built speaks only C, because that is all tcc could carry it
# far enough to build.  This one is the same source built by that compiler,
# with libstdc++ and g++ -- which is what every gcc after 4.7 needs, being
# written in C++ itself.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
tar xzf "$coreTarball"
tar xzf "$cxxTarball"
tar xzf "$gmpTarball"
tar xzf "$mpfrTarball"
tar xzf "$mpcTarball"
cd "gcc-$version"

# gcc builds these in tree when it finds them under these names.  Copied
# rather than linked, because gcc's build writes into them.
cp -r "../gmp-$gmpVersion" gmp
cp -r "../mpfr-$mpfrVersion" mpfr
cp -r "../mpc-$mpcVersion" mpc

# As in the C-only build: 4.6.4 predates --with-native-system-header-dir, and
# configure only warns at an option it does not know, so the directory
# fixincludes reads goes into the makefile directly.  Left alone it is
# /usr/include, and the host's headers are not this bootstrap's.
sed -i "s|^NATIVE_SYSTEM_HEADER_DIR = /usr/include|NATIVE_SYSTEM_HEADER_DIR = $muslInclude|" gcc/Makefile.in
grep -q "^NATIVE_SYSTEM_HEADER_DIR = $muslInclude\$" gcc/Makefile.in

# libstdc++ keys its OS-specific configuration off the target triple and has
# no entry for musl, so it picks the glibc one.  os/generic is the one that
# assumes nothing.
sed -i 's|"os/gnu-linux"|"os/generic"|' libstdc++-v3/configure.host

chmod +x configure

# tar restores no modification times; wait for the clock to tick.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

# -O1 rather than -O2: 4.6.4 compiling itself at -O2 is where this compiler's
# own optimiser is least exercised, and the target flags drop to -O0 because
# libstdc++'s startup code is built before there is anything to test it with.
#
# The dynamic linker is named on every link.  The gcc below was configured
# against the static, tcc-built musl and so has no interpreter it can point
# at; without this its own configure cannot run the program it just compiled
# and stops at "cannot run C compiled programs".
export CC="gcc -Wl,-dynamic-linker -Wl,$muslLib/libc.so"
export CFLAGS="-O1"
export CXXFLAGS="-O1"
export CFLAGS_FOR_TARGET="-O0 -Wl,-dynamic-linker -Wl,$muslLib/libc.so"
export CXXFLAGS_FOR_TARGET="$CFLAGS_FOR_TARGET"
export C_INCLUDE_PATH="$muslInclude"
export CPLUS_INCLUDE_PATH="$muslInclude"
export LIBRARY_PATH="$muslLib"

# The build and host tuples are spelled without the C library: this config.sub
# comes from autotools old enough to be confused by a four-part tuple.
./configure \
  --prefix="$out" \
  --build=i686-pc-linux-gnu \
  --host=i686-pc-linux-gnu \
  --enable-languages=c,c++ \
  --enable-checking=release \
  --disable-bootstrap \
  --disable-dependency-tracking \
  --disable-libgomp \
  --disable-libmudflap \
  --disable-libquadmath \
  --disable-libssp \
  --disable-libstdcxx-pch \
  --disable-lto \
  --disable-multilib \
  --disable-nls \
  --disable-libsanitizer \
  --disable-shared

make
make install-strip

"$out/bin/gcc" --version | head -1
"$out/bin/g++" --version | head -1
