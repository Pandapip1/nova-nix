# GNU coreutils 9.10, compiled by tcc against musl.
#
# The 5.0 below this one is built from live-bootstrap's makefile, which names
# the programs it compiles -- 62 of them, and not env, uname, date or stat.
# Nothing noticed until gcc: libcpp's configure runs its dependency-style
# probe through `env', and with no env every style fails and configure stops.
set -e

export PATH="$toolPath"

cd "$TMPDIR"
tar xzf "$tarball"
cd "coreutils-$version"

chmod +x configure

# tar restores no modification times; wait for the clock to tick.
tick=$SECONDS
while [ "$SECONDS" -eq "$tick" ]; do :; done

export LD=tcc
export LDFLAGS="-L ./lib"

./configure \
  --prefix="$out" \
  --build=i686-pc-linux-gnu \
  --host=i686-pc-linux-gnu \
  --disable-dependency-tracking \
  --disable-nls \
  --enable-no-install-program=stdbuf,arch,coreutils,hostname \
  gl_cv_func_getcwd_path_max="no, but it is partly working" \
  gl_cv_have_unlimited_file_name_length=no \
  gl_cv_func_copy_file_range=no \
  gl_cv_onwards_func_copy_file_range=no

# SUBDIRS=. keeps make out of gnulib-tests, which wants pthreads and headers
# from linux/ that are not here.  MAKEINFO=true because there is no makeinfo
# and the manuals are not what this is for.
make AR="$AR" MAKEINFO=true SUBDIRS=.
make install AR="$AR" MAKEINFO=true SUBDIRS=.

rm -rf "$out/share/info" "$out/share/man"

"$out/bin/env" --version | head -1
"$out/bin/uname" -m
