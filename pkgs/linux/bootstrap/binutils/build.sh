# GNU binutils 2.46.0, compiled by tcc against musl.
#
# The assembler and linker.  tcc has its own of both and got the bootstrap
# this far on them, but gcc emits assembly that only gas assembles and
# expects a linker that reads gnu ld's scripts.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
# unxz from mescc-tools-extra only decompresses; the unpacking is GNU tar's,
# because mescc-tools-extra's untar cannot write a symlink whose target does
# not fit in the header's own field, and binutils has several.
unxz --file "$tarball" --output binutils.tar
tar xf binutils.tar
cd "binutils-$version"

patch -Np1 -i "$deterministicPatch"
patch -Np1 -i "$attributePatch"

# The three scripts autotools calls out to start with a /bin/sh that is not
# this bootstrap's.
sed -i "s|/bin/sh|$bashPath|" missing install-sh mkinstalldirs

# sed -i writes a new file over the old one, which loses the mode: these three
# are run as programs.
chmod +x missing install-sh mkinstalldirs

# libtool sorts its symbol list through NL2SP, and without a sort in front of
# it the order depends on the order the objects were read.  Upstream libtool's
# 74c8993c178a1386ea5e2363a01d919738402f30.
sed -i 's/| \$NL2SP/| sort | $NL2SP/' ltmain.sh

# binutils regenerates its manuals unless makeinfo is present; there is no
# makeinfo here and the manuals are not what this is for.
mkdir aliases
cp "$truePath" aliases/makeinfo
chmod +x aliases/makeinfo
export PATH="$PWD/aliases:$PATH"

# untar restores no modification times; wait for the clock to tick.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

# configure's own probe for this runs the shell until it fails, which takes
# long enough to look like a hang.
export lt_cv_sys_max_cmd_len=32768

# tcc predefines neither __LITTLE_ENDIAN__ nor the __BYTE_ORDER__ that
# binutils reads instead.
export CFLAGS="-D__LITTLE_ENDIAN__=1"

./configure \
  --prefix="$out" \
  --build=i686-pc-linux-gnu \
  --host=i686-pc-linux-gnu \
  --with-sysroot=/ \
  --disable-dependency-tracking \
  --disable-nls \
  --enable-deterministic-archives \
  --disable-gprofng \
  --enable-new-dtags \
  --with-lib-path=: \
  --disable-gold \
  --disable-plugins

make all-libiberty all-gas all-bfd all-libctf all-zlib all-gprof
make all-ld
make
make install

# gprof, addr2line and elfedit are not used by anything above, and the
# manuals were never built.
rm -f "$out/bin/gprof" "$out/bin/addr2line" "$out/bin/elfedit"
rm -rf "$out/share/info" "$out/share/man"

"$out/bin/ld" --version | head -1
"$out/bin/as" --version | head -1
