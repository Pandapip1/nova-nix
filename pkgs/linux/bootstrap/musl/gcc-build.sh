# musl 1.2.6, compiled by gcc.
#
# The same C library as build.sh, built the way its authors intended: gcc can
# assemble everything tcc could not, so nothing is removed here -- the complex
# math, the i386 and x86_64 assembly routines and sigsetjmp are all built.
# It is also a shared library, with the dynamic loader and the musl-gcc
# wrapper that the compilers above this point link against.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
tar xzf "$tarball"
cd "musl-$version"

# musl's build scripts say /bin/sh, which does not exist in a build with
# nothing but this bootstrap on PATH.
sed -i "s|/bin/sh|$bashPath|" tools/*.sh
chmod 755 tools/*.sh

# popen, system and wordexp hardcode /bin/sh for the same reason; make them
# look it up on PATH instead.
sed -i 's|posix_spawn(&pid, "/bin/sh",|posix_spawnp(\&pid, "sh",|' src/stdio/popen.c src/process/system.c
sed -i 's|execl("/bin/sh", "sh", "-c",|execlp("sh", "-c",|' src/misc/wordexp.c

# configure compares timestamps; wait for the clock to tick.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

# --syslibdir puts the dynamic loader in this store path rather than /lib,
# and --enable-wrapper installs musl-gcc, which is how everything above links
# against this C library without knowing where it is.
./configure \
  --prefix="$out" \
  --build=i686-pc-linux-gnu \
  --host=i686-pc-linux-gnu \
  --syslibdir="$out/lib" \
  --enable-wrapper

make
make install

# The wrapper is a shell script and says /bin/sh too.  sed -i writes a new
# file over the old one, which loses the mode, and this one is run.
sed -i "s|/bin/sh|$bashPath|" "$out"/bin/*
chmod 755 "$out"/bin/*
ln -s ../lib/libc.so "$out/bin/ldd"

ls "$out/lib/libc.a" "$out/lib/libc.so" "$out/bin/musl-gcc"

# The wrapper names the store path it was configured with, which is the path
# it is installed at: a build that wrote somewhere else first would have
# recorded the somewhere else.
grep -q "$out/lib/musl-gcc.specs" "$out/bin/musl-gcc"
