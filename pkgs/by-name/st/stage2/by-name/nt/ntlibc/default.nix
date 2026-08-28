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
  stdenv,
  system,
  platforms,
  stage0,
  tinycc,
  callPackage,
  targetTriple,
}:
let
  sources = callPackage ./bootstrap-sources.nix { };
  targetArch =
    if targetTriple == "i686-pc-pe" then "i386"
    else if targetTriple == "x86_64-pc-pe" then "x86_64"
    else throw "ntlibc: unsupported target triple ${targetTriple}";
in
stdenv.mkDerivation {
  pname = "ntlibc";
  inherit (sources) version;
  inherit system;

  srcdir = sources.src;

  # The compiler alone.  ntlibc's generated script archives with
  # `${CC} -ar rcs', and tcc accepts -ar only as its own first argument, so
  # anything appended here would stop it being that.
  CC = "${tinycc}/bin/tcc";
  inherit targetArch;
  libtcc1 = "${tinycc.libs or tinycc}/lib/libtcc1.a";
  chkstkMsSrc = ./chkstk-ms.S;
  ioCompatSrc = ./compat/io.h;
  directCompatSrc = ./compat/direct.h;
  processCompatSrc = ./compat/process.h;

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

  passthru = {
    inherit targetArch targetTriple;
    includePaths = [
      "${sources.src}/include"
      "${sources.src}/arch/${targetArch}"
      "${sources.src}/arch/generic"
    ];
  };

  meta = {
    description = "A C library for the Windows NT API";
    homepage = "https://github.com/Pandapip1/ntlibc";
    license = "gpl3Plus";
    inherit platforms;
  };
}
