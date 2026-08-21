# GNU findutils 4.10.0, compiled by tcc against musl.
#
# gcc's build runs find, so this comes before it.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
unxz --file "$tarball" --output findutils.tar
tar xf findutils.tar
cd "findutils-$version"

# gnulib's chdir_long is only compiled when configure decides PATH_MAX is not
# a usable bound, and here it decides wrongly and leaves the call with nothing
# behind it.  chdir is what chdir_long falls back to anyway.
sed -i 's/chdir_long/chdir/' gl/lib/save-cwd.c

chmod +x configure

# tar restores no modification times; wait for the clock to tick.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

export LD=tcc
./configure \
  --prefix="$out" \
  --build=i686-pc-linux-gnu \
  --host=i686-pc-linux-gnu \
  --disable-dependency-tracking

make
make install

"$out/bin/find" --version | head -1
