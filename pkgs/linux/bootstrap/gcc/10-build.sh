# GCC 10.4.0, compiled by GCC 4.6.4 with C++.
#
# The first gcc here written in C++ rather than C, which is why 4.6 had to
# grow a g++ first.  10.4.0 rather than 10.5.0: 10.5 does not build with a
# compiler this old (gcc bug 110716).
set -e

export PATH="$toolPath"

cd "$TMPDIR"
for t in "$coreTarball" "$gmpTarball" "$mpfrTarball" "$mpcTarball"; do
  unxz --file "$t" --output tmp.tar
  tar xf tmp.tar
  rm tmp.tar
done
cd "gcc-$version"

# gcc builds these in tree when it finds them under these names.  Copied
# rather than linked, because gcc's build writes into them.
cp -r "../gmp-$gmpVersion" gmp
cp -r "../mpfr-$mpfrVersion" mpfr
cp -r "../mpc-$mpcVersion" mpc

# libstdc++ keys its OS-specific configuration off the target triple and has
# no entry for musl, so it picks the glibc one.  os/generic assumes nothing.
sed -i 's|"os/gnu-linux"|"os/generic"|' libstdc++-v3/configure.host

chmod +x configure

# tar restores no modification times; wait for the clock to tick.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

# The compiler underneath was built against a musl with no shared library, so
# it has no dynamic loader to name; every link says which one to use.
export CC="gcc -Wl,-dynamic-linker -Wl,$muslLib/libc.so"
export CXX="g++ -Wl,-dynamic-linker -Wl,$muslLib/libc.so"
export CFLAGS="-O1"
export CXXFLAGS="-O1"
export CFLAGS_FOR_TARGET="-O0 -Wl,-dynamic-linker -Wl,$muslLib/libc.so"
export CXXFLAGS_FOR_TARGET="$CFLAGS_FOR_TARGET"
export C_INCLUDE_PATH="$muslInclude"
export CPLUS_INCLUDE_PATH="$muslInclude"
export LIBRARY_PATH="$muslLib"

# Unlike 4.6.4, this gcc has --with-native-system-header-dir, so the headers
# are named on the command line rather than edited into the makefile.  It is
# relative to --with-sysroot.
./configure \
  --prefix="$out" \
  --build=i686-pc-linux-gnu \
  --host=i686-pc-linux-gnu \
  --with-native-system-header-dir=/include \
  --with-sysroot="$musl" \
  --enable-languages=c,c++ \
  --enable-checking=release \
  --disable-bootstrap \
  --disable-dependency-tracking \
  --disable-libmpx \
  --disable-libsanitizer \
  --disable-libssp \
  --disable-libgomp \
  --disable-libquadmath \
  --disable-libitm \
  --disable-libvtv \
  --disable-libatomic \
  --disable-libstdcxx-pch \
  --disable-lto \
  --disable-multilib \
  --disable-nls \
  --disable-plugin \
  --without-isl \
  --disable-libstdcxx-filesystem-ts \
  --disable-shared

make
make install-strip

"$out/bin/gcc" --version | head -1
"$out/bin/g++" --version | head -1
