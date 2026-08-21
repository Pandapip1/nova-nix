# GNU awk 3.0.6, compiled by tcc.
#
# Needed because a configure script uses awk -- binutils' does, and so does
# everything autotools generates.  3.0.6 is the version live-bootstrap and
# nixpkgs' minimal bootstrap settle on for a C library this small.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
ungz --file "$tarball" --output gawk.tar
untar --file gawk.tar
cd "gawk-$version"

patch -Np0 -i "$noStampPatch"

chmod +x configure

# untar restores no modification times; wait for the clock to tick so that
# configure's newer-than-the-sources check is not a coin flip.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

# Two answers configure cannot work out by running a test program here.
export ac_cv_func_getpgrp_void=yes
export ac_cv_func_tzset=yes

./configure --build=i686-pc-linux-gnu --host=i686-pc-linux-gnu --disable-nls --prefix="$out"

make gawk AR="$AR"

mkdir -p "$out/bin"
cp gawk "$out/bin/gawk"
chmod 555 "$out/bin/gawk"
cp gawk "$out/bin/awk"
chmod 555 "$out/bin/awk"

"$out/bin/awk" 'BEGIN { print "awk works" }'
