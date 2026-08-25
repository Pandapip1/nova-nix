# GNU tar 1.35, compiled by gcc against musl.
#
# 1.12 got the bootstrap from the mescc-tools unpackers as far as a real
# compiler, but it predates the pax extended headers that a modern release
# tarball uses -- gcc 15's stops it with "Unknown file type 'x'".  This is the
# tar that opens the sources above.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
tar xzf "$tarball"
cd "tar-$version"

chmod +x configure

# The tar that unpacked this one restores no modification times.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

# musl-gcc rather than gcc: this tar links against the shared C library, and
# the wrapper is what knows where it is.
./configure \
  --prefix="$out" \
  --build=i686-pc-linux-gnu \
  --host=i686-pc-linux-gnu \
  --disable-dependency-tracking \
  CC=musl-gcc

make
make install

"$out/bin/tar" --version | head -1
