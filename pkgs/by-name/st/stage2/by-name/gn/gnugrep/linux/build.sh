# GNU grep 2.4, compiled by tcc.
#
# 2.4 is old enough to compile against the Mes C library without patches --
# the only thing it needs is a makefile, since its own comes from a configure
# this bootstrap cannot run.
set -e

# Only the bootstrap's own programs; see gnused for why.
export PATH="$toolPath"

cd "$TMPDIR"
ungz --file "$tarball" --output grep.tar
untar --file grep.tar
cd "grep-$version"

cp "$makefile" Makefile

make CC="$CC" AR="$AR"
make install CC="$CC" AR="$AR" PREFIX="$out"

"$out/bin/grep" --version | head -1
