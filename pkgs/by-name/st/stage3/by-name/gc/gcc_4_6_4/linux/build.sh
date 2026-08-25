# GCC 4.6.4, compiled by tcc against musl.
#
# The last link: a real C compiler, every byte of it traced back to the
# 181-byte hex0 seed.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
tar xzf "$coreTarball"
tar xzf "$cxxTarball"
tar xzf "$gmpTarball"
tar xzf "$mpfrTarball"
tar xzf "$mpcTarball"
cd "gcc-$version"

# gcc builds gmp, mpfr and mpc in tree when it finds them under these names.
# They are copied rather than linked, because gcc's build writes into them.
cp -r "../gmp-$gmpVersion" gmp
cp -r "../mpfr-$mpfrVersion" mpfr
cp -r "../mpc-$mpcVersion" mpc

# gcc/Makefile.in hardcodes /usr/include as the directory fixincludes reads
# the system headers from, and this gcc is too old to be told otherwise:
# --with-native-system-header-dir does not exist until later, and configure
# only warns at an option it does not know.  Left alone, fixincludes copies
# the host's glibc headers into include-fixed, and the libgcc that the new
# compiler then builds stops at a bits/endian.h that musl does not have.
#
# nixpkgs comments the line out, which works in a sandbox where there is no
# /usr/include to find.  Here it is pointed at musl's headers instead, which
# is what the option would have done.
sed -i "s|^NATIVE_SYSTEM_HEADER_DIR = /usr/include|NATIVE_SYSTEM_HEADER_DIR = $libcInclude|" gcc/Makefile.in
grep -q "^NATIVE_SYSTEM_HEADER_DIR = $libcInclude\$" gcc/Makefile.in

chmod +x configure

# tar restores no modification times; wait for the clock to tick.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

export CFLAGS="-O2"
export C_INCLUDE_PATH="$libcInclude:$PWD/mpfr/src"
export CPLUS_INCLUDE_PATH="$C_INCLUDE_PATH"

# configure cannot link a test program until gcc itself exists, so the three
# answers it would have got by running one are given directly.
export lt_cv_shlibpath_overrides_runpath=yes
export ac_cv_func_memcpy=yes
export ac_cv_func_strerror=yes

# The build and host tuples are spelled without the C library: this config.sub
# comes from autotools old enough to be confused by a four-part tuple.
./configure \
  --prefix="$out" \
  --build="$buildTriple" \
  --host="$hostTriple" \
  --target="$targetTriple" \
  --enable-checking=release \
  --disable-bootstrap \
  --disable-decimal-float \
  --disable-dependency-tracking \
  --disable-libatomic \
  --disable-libcilkrts \
  --disable-libgomp \
  --disable-libitm \
  --disable-libmudflap \
  --disable-libquadmath \
  --disable-libsanitizer \
  --disable-libssp \
  --disable-libvtv \
  --disable-lto \
  --disable-lto-plugin \
  --disable-multilib \
  --disable-nls \
  --disable-plugin \
  --disable-threads \
  --enable-languages=c \
  --enable-static \
  --disable-shared \
  --enable-threads=single \
  --disable-libstdcxx-pch \
  --disable-build-with-cxx

make
make install-strip

"$out/bin/gcc" --version | head -1
