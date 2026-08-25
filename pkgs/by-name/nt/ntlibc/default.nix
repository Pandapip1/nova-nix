# ntlibc: the C library everything above tcc is built against.
#
# Mes's C library is what the chain climbs on, not what it stands on.  It
# has a bump allocator that never frees, no threads, stub signals, and a
# POSIX surface thin enough that the first real program above tcc trips over
# it.  ntlibc is this side's musl -- a full libc for the NT API, reaching
# the kernel through named ntdll exports rather than a syscall instruction.
#
# Built by tinycc.boot.tcc, the last round of the bootstrap: the same
# compiler nova-nix's own chain produced, so the library is as traced-back
# as the compiler is.
#
# The headers are the source tree's own (include/, arch/i386, arch/generic)
# plus obj/include/bits/alltypes.h, which the build generates -- so a
# consumer needs `src` on its include path as well as this output, and that
# one generated header is copied out beside the libraries.
{
  derivationWithMeta,
  system,
  platforms,
  stage0,
  tinycc,
  callPackage,
}:
let
  sources = callPackage ./bootstrap-sources.nix { };
in
derivationWithMeta {
  pname = "ntlibc";
  inherit (sources) version;
  inherit system;

  srcdir = sources.src;

  # The compiler alone.  ntlibc's generated script archives with
  # `${CC} -ar rcs', and tcc accepts -ar only as its own first argument, so
  # anything appended here would stop it being that.
  CC = tinycc.boot.tcc;

  bin_kaem = stage0.kaem;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;
  bin_cp = stage0.mescc-tools-extra.cp;
  bin_catm = stage0.mescc-tools-extra.catm;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "A C library for the Windows NT API";
    homepage = "https://github.com/Pandapip1/ntlibc";
    license = "gpl3Plus";
    inherit platforms;
  };
}
