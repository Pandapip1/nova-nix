# GCC 4.6.4 with C++, compiled by the GCC 4.6.4 below it.
#
# The gcc that tcc built speaks only C -- that was as far as tcc could carry
# it.  This is the same source built by that compiler, with libstdc++ and g++,
# which is what every gcc after 4.7 needs: they are written in C++ themselves.
#
# It links against the musl that gcc built rather than the one tcc built,
# because libstdc++ wants a shared C library and a dynamic loader.
{
  derivationWithMeta,
  system,
  platforms,
  gcc,
  musl,
  binutils,
  gnumake,
  gnused,
  gnugrep,
  gnutar,
  gzip,
  gawk,
  diffutils,
  findutils,
  bash,
  coreutils,
}:
let
  pname = "gcc-cxx";

  sources = import ./sources.nix { };
  inherit (sources)
    version
    gmpVersion
    mpfrVersion
    mpcVersion
    ;
in
derivationWithMeta {
  inherit
    pname
    version
    system
    gmpVersion
    mpfrVersion
    mpcVersion
    ;

  inherit (sources)
    coreTarball
    cxxTarball
    gmpTarball
    mpfrTarball
    mpcTarball
    ;

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnutar}/bin"
    "${gzip}/bin"
    "${gawk}/bin"
    "${diffutils}/bin"
    "${findutils}/bin"
    "${binutils}/bin"
    "${gcc}/bin"
    "${bash}/bin"
  ];

  muslInclude = "${musl}/include";
  muslLib = "${musl}/lib";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./cxx-build.sh
  ];

  meta = {
    description = "GNU Compiler Collection, version ${version}, with C++";
    homepage = "https://gcc.gnu.org";
    license = "gpl3Plus";
    inherit platforms;
  };
}
