# GNU tar 1.12, compiled by tcc.
#
# The first package here that runs its own ./configure.  Every package below
# had its configure replaced by a hand-written makefile and a list of -D
# flags, because kaem could not run a configure script and there was no shell
# that could.  There is now: this is what bash was built for, and from here
# up a package can be built the way its authors intended.
#
# 1.12 rather than anything newer: 1.13 and later want more of a C library
# than Mes provides.
set -e

# Only the bootstrap's own programs; a configure script probes for tools by
# bare name, and the host's must not be what it finds.
export PATH="$toolPath"

cd "$TMPDIR"
ungz --file "$tarball" --output tar.tar
untar --file tar.tar
cd "tar-$version"

# untar does not restore the executable bit, and configure has to run.
chmod +x configure

# ...nor does it restore modification times: every unpacked file lands with
# the current time.  configure creates a file and checks that it is newer than
# the distributed ones, which is a coin flip when they share a timestamp --
# `ls -t` falls back to name order, and it stops with "newly created file is
# older than distributed files".
#
# Waiting for the clock to tick settles it, and it has to be done with bash's
# own $SECONDS.  Nothing else here can: this coreutils, compiled against the
# Mes C library, accepts `touch -t` and `touch -d` and silently does nothing,
# and its `sleep` never returns.  A busy loop costs under a second and
# depends on no program at all.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

export CC="$CC"
./configure --build=i686-pc-linux-gnu --host=i686-pc-linux-gnu --disable-nls --prefix="$out"

# The archive rule says `$(AR) cru` outright, so overriding ARFLAGS cannot
# reach it -- the cluster is in the rule, not in a variable.  sed takes it
# out, which is what sed was built for.  This tcc refuses a flag cluster after
# -ar: it scans every argument for the operations it does not support, and
# "-ar" itself contains an 'a'.
for makefile in Makefile lib/Makefile src/Makefile; do
  [ -f "$makefile" ] || continue
  sed 's|$(AR) cru|$(AR)|' "$makefile" > "$makefile.new"
  mv "$makefile.new" "$makefile"
done

make AR="$AR"
make install AR="$AR"

"$out/bin/tar" --version | head -1
