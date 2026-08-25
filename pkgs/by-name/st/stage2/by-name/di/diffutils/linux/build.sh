# GNU diffutils 3.8, compiled by tcc.
#
# binutils' configure runs cmp, and gcc's build compares generated files with
# what it already has; neither works without diffutils.
#
# The tarball is .tar.xz, which is what mescc-tools-extra's unxz is for --
# there is no xz program in this bootstrap, and decompressing is all that is
# needed.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
unxz --file "$tarball" --output diffutils.tar
untar --file diffutils.tar
cd "diffutils-$version"

chmod +x configure

# untar restores no modification times; wait for the clock to tick.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

export LD=tcc
./configure --prefix="$out" --build=i686-pc-linux-gnu --host=i686-pc-linux-gnu

make AR="$AR"

# The tarball ships doc/diffutils.info already built, but untar restores no
# modification times, so make cannot tell it is newer than the .texi it comes
# from and tries to run a makeinfo that this bootstrap does not have.  Marking
# it current says what is already true.
touch doc/diffutils.info

make install AR="$AR"

"$out/bin/cmp" --version | head -1
