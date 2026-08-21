# gzip 1.2.4, compiled by tcc, built by its own ./configure.
#
# The last of the tools the packages above assume: with tar and gzip both
# here, a release tarball can be opened by the programs this bootstrap built
# rather than by the ones mescc-tools-extra provided to get it started.
#
# -Dstrlwr=unused is live-bootstrap's: gzip declares strlwr for systems that
# have it, and defining the name away is simpler than teaching it that this
# one does not.
set -e

# Only the bootstrap's own programs; a configure script probes by bare name.
export PATH="$toolPath"

cd "$TMPDIR"
ungz --file "$tarball" --output gzip.tar
untar --file gzip.tar
cd "gzip-$version"

chmod +x configure

# untar restores no modification times, so everything is stamped "now" and
# configure's check that a file it just made is newer than the sources is a
# coin flip.  Wait for the clock to tick -- with bash's own $SECONDS, since
# this coreutils' `touch -t` does nothing and its `sleep` never returns.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

export CC="$CC -Dstrlwr=unused"
./configure --prefix="$out"

make AR="$AR"
mkdir -p "$out"
make install AR="$AR"

"$out/bin/gzip" --version | head -1
