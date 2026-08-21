# GCC 15.3.0, compiled by GCC 10.4.0.
#
# The end of the ladder: a current compiler, every byte behind it traced to
# the 181-byte hex0 seed.  Three gccs to get here, because each one is written
# in a language only the one below it could compile -- 4.6 in C for tcc, 4.6's
# g++ for gcc 10, and gcc 10 for this.
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

# libstdc++ keys its OS-specific configuration off the target triple, which
# says gnu here and means musl.  os/generic assumes nothing.
sed -i 's|"os/gnu-linux"|"os/generic"|' libstdc++-v3/configure.host

chmod +x configure

# tar restores no modification times; wait for the clock to tick.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

# gcc 10 was built against a musl with no shared library of its own to name,
# so every link says which dynamic loader to use.
export CC="gcc -Wl,-dynamic-linker -Wl,$muslLib/libc.so"
export CXX="g++ -Wl,-dynamic-linker -Wl,$muslLib/libc.so"
export CFLAGS="-O1"
export CXXFLAGS="-O1"
export CFLAGS_FOR_TARGET="-O0 -Wl,-dynamic-linker -Wl,$muslLib/libc.so"
export CXXFLAGS_FOR_TARGET="$CFLAGS_FOR_TARGET"
export LIBRARY_PATH="$muslLib"

# The header directory is absolute and the sysroot is /, rather than the
# sysroot-relative pair gcc 10 uses: there is no root to be relative to here.
./configure \
  --prefix="$out" \
  --build=i686-pc-linux-gnu \
  --host=i686-pc-linux-gnu \
  --with-native-system-header-dir="$muslInclude" \
  --with-sysroot=/ \
  --enable-languages=c,c++ \
  --enable-checking=release \
  --enable-static \
  --disable-shared \
  --disable-bootstrap \
  --disable-dependency-tracking \
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
  --without-isl

make
make install-strip

# The gdb pretty-printers and the manuals are not used by anything above.
rm -rf "$out"/share/gcc-*/python "$out/share/man" "$out/share/info"

"$out/bin/gcc" --version | head -1
"$out/bin/g++" --version | head -1
