# GCC 4.6.4, compiled by tcc against musl.
#
# The last link in the chain: a real C compiler, every byte of it traced back
# to the 181-byte hex0 seed.
#
# 4.6.4 because it is the newest gcc that tcc can still compile -- later ones
# are written in C++ and need a C++ compiler to build, which is what this one
# goes on to provide.  gmp, mpfr and mpc are unpacked into the source tree,
# which is how gcc's build expects to find them when there is no system copy.
{
  stdenv,
  system,
  platforms,
  buildTriple,
  hostTriple,
  targetTriple,
  tinycc,
  libc,
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
  pname = "gcc";

  sources = import ./sources.nix { };
  inherit (sources)
    version
    gmpVersion
    mpfrVersion
    mpcVersion
    ;
in
stdenv.mkDerivation {
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
    "${tinycc}/bin"
    "${bash}/bin"
  ];

  inherit buildTriple hostTriple targetTriple;
  libcInclude = "${libc}/include";

  CC = "${tinycc}/bin/tcc -B ${tinycc}/lib";
  AR = "${tinycc}/bin/tcc -ar";

  buildScript = ./build.sh;

  meta = {
    description = "GNU Compiler Collection, version ${version}";
    homepage = "https://gcc.gnu.org";
    license = "gpl3Plus";
    inherit platforms;
  };
}
