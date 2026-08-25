# musl 1.2.6, compiled by gcc.
#
# The same C library as default.nix, built the way its authors intended: gcc
# assembles everything tcc could not, so nothing is removed -- the complex
# math, the i386 and x86_64 assembly and sigsetjmp are all built.  It is a
# shared library too, with the dynamic loader and the musl-gcc wrapper that
# the compilers above this point link against; the tcc-built one is static
# only, which was all tcc could produce.
{
  derivationWithMeta,
  system,
  platforms,
  gcc,
  binutils,
  gnumake,
  gnused,
  gnugrep,
  gnutar,
  gzip,
  bash,
  coreutils,
}:
let
  pname = "musl";

  sources = import ./sources.nix { };
  inherit (sources) version;
in
derivationWithMeta {
  inherit pname version system;

  tarball = sources.src;

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnutar}/bin"
    "${gzip}/bin"
    "${binutils}/bin"
    "${gcc}/bin"
    "${bash}/bin"
  ];

  bashPath = "${bash}/bin/bash";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./gcc-build.sh
  ];

  meta = {
    description = "An efficient, small, quality libc implementation";
    homepage = "https://musl.libc.org";
    license = "mit";
    inherit platforms;
  };
}
