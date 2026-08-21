# GNU tar 1.12, compiled by tcc against musl.
#
# Same source and same version as the tar below it; what the C library buys is
# modification times.  Built against Mes's, tar restores none of them, so
# every file in an unpacked tree lands with the extraction time in extraction
# order -- and make then reads a distributed aclocal.m4 as older than the
# configure.ac beside it and tries to run an aclocal that is not here.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
gunzip < "$tarball" > tar.tar
tar xf tar.tar
cd "tar-$version"

chmod +x configure

# The tar that unpacked this one restores no modification times either.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

export LD=tcc

# Answers configure would otherwise get by running a program it cannot link
# until the C library is in place.
export ac_cv_sizeof_unsigned_long=4
export ac_cv_sizeof_long_long=8
export ac_cv_header_netdb_h=no

./configure --build=i686-pc-linux-gnu --host=i686-pc-linux-gnu --disable-nls --prefix="$out"

# The archive rule says `$(AR) cru' outright, so overriding ARFLAGS cannot
# reach it.  This tcc refuses a flag cluster after -ar: it scans every
# argument for the operations it does not support, and "-ar" itself has an 'a'.
for makefile in Makefile lib/Makefile src/Makefile; do
  [ -f "$makefile" ] || continue
  sed -i 's|$(AR) cru|$(AR)|' "$makefile"
done

make AR="$AR"
make install AR="$AR"

"$out/bin/tar" --version | head -1
