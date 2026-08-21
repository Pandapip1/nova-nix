# GNU awk 5.3.2, compiled by tcc against musl.
#
# 3.0.6 (mes.nix) is small enough for the Mes C library but too old for the
# subs.awk that a modern config.status generates -- it stops at the first line
# continuation.  This is the awk everything above the C library uses; 3.0.6
# exists only to build it.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
tar xzf "$tarball"
cd "gawk-$version"

chmod +x configure

# tar restores no modification times here either; wait for the clock to tick
# so that configure's newer-than-the-sources check is not a coin flip.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

export LD=tcc
./configure \
  --prefix="$out" \
  --build=i686-pc-linux-gnu \
  --host=i686-pc-linux-gnu \
  --disable-nls \
  --disable-dependency-tracking

make
make install

"$out/bin/awk" 'BEGIN { print "awk works" }'
