# musl 1.2.6, compiled by tcc.
#
# The C library that replaces Mes's.  Everything below this was compiled
# against a libc written to be small enough to bootstrap, with the gaps that
# implies -- no locale, no strcoll, a touch that cannot set a timestamp.  musl
# is a real one, and from here up a program can expect what its authors
# expected.
#
# The source is opened with the tar and gzip this bootstrap built, not with
# the mescc-tools-extra unpackers: those got the chain as far as having real
# ones.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
tar xzf "$tarball"
cd "musl-$version"

# tcc cannot assemble a backward jecxz, which is what sigsetjmp uses.
patch -Np0 -i "$sigsetjmpPatch"

# tcc has no complex types, and musl's complex math is the only user.
rm -rf src/complex

# musl's configure and build scripts say /bin/sh, which does not exist in a
# build with nothing but this bootstrap on PATH.
sed -i "s|/bin/sh|$bashPath|" tools/*.sh
chmod 755 tools/*.sh

# popen, system and wordexp hardcode /bin/sh for the same reason; make them
# look it up on PATH instead.
sed -i 's|posix_spawn(&pid, "/bin/sh",|posix_spawnp(\&pid, "sh",|' src/stdio/popen.c src/process/system.c
sed -i 's|execl("/bin/sh", "sh", "-c",|execlp("sh", "-c",|' src/misc/wordexp.c

# @PLT is not a specifier tcc's assembler accepts.  The calls reach the PLT
# regardless, so saying so is redundant here.
sed -i 's|@PLT||' src/math/x86_64/expl.s
sed -i 's|@PLT||' src/signal/x86_64/sigsetjmp.s

# These use asm constraints tcc does not implement ('x' and 't').  musl has a
# pure C implementation of each and falls back to it when the asm is absent.
rm -f src/math/i386/*.c
rm -f src/math/x86_64/*.c

# untar is not what opened this tarball, but configure still compares
# timestamps; wait for the clock to tick, as tar and gzip do.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

./configure --prefix="$out" --build=i686-pc-linux-gnu --host=i686-pc-linux-gnu --disable-shared CC="$CC"

# The archive rules say `$(AR) rc`, and this tcc refuses a flag cluster after
# -ar: it scans every argument for the operations it does not support, and
# "-ar" itself contains an 'a'.  Without a cluster it creates the archive,
# which is what `rc` asked for.
sed -i 's|$(AR) rc|$(AR)|' Makefile

# RANLIB=true because there is no ranlib here and tcc's ar writes the index
# itself.  SYSCALL_NO_TLS because this musl is not being built with thread
# local storage the way a hosted compiler would give it.
make AR="$AR" RANLIB=true CFLAGS="-DSYSCALL_NO_TLS"
make install AR="$AR" RANLIB=true

# libtcc1.a holds the compiler's own helpers -- the long division and shift
# routines tcc emits calls to -- and belongs beside the C library that
# programs will link against.
cp "$libtcc1" "$out/lib/libtcc1.a"

ls "$out/lib/libc.a"
