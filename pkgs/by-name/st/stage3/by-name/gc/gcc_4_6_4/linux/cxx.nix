# GCC 4.6.4 with C++, compiled by the GCC 4.6.4 below it.
#
# The gcc that tcc built speaks only C -- that was as far as tcc could carry
# it.  This is the same source built by that compiler, with libstdc++ and g++,
# which is what every gcc after 4.7 needs: they are written in C++ themselves.
#
# It links against the musl that gcc built rather than the one tcc built,
# because libstdc++ wants a shared C library and a dynamic loader.
{
  stdenv,
  system,
  platforms,
  platform,
  isLinux,
  buildTriple,
  hostTriple,
  targetTriple,
  stage0,
  gcc,
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
  pname = "gcc-cxx";
  executableSuffix = stage0.executableSuffix;

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
    "${gcc}/bin"
    "${bash}/bin"
  ];

  inherit
    platform
    buildTriple
    hostTriple
    targetTriple
    executableSuffix
    ;
  libcInclude = "${libc}/include";
  libcLib = "${libc}/lib";
  isLinuxString = if isLinux then "1" else "";
  dynamicLinker = if isLinux then "${libc}/lib/libc.so" else "";

  gccCommand = "${gcc}/bin/gcc${executableSuffix}";
  makeCommand = "${gnumake}/bin/make${executableSuffix}";
  tarCommand = "${gnutar}/bin/tar${executableSuffix}";
  gzipCommand = "${gzip}/bin/gzip${executableSuffix}";
  sedCommand = "${gnused}/bin/sed${executableSuffix}";
  grepCommand = "${gnugrep}/bin/grep${executableSuffix}";
  cpCommand = stage0.mescc-tools-extra.cp;
  chmodCommand = stage0.mescc-tools-extra.chmod;

  buildScript = ./cxx-build.sh;

  meta = {
    description = "GNU Compiler Collection, version ${version}, with C++";
    homepage = "https://gcc.gnu.org";
    license = "gpl3Plus";
    inherit platforms;
  };
}
