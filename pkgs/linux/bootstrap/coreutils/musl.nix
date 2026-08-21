# GNU coreutils 9.10, compiled by tcc against musl.
#
# The 5.0 in default.nix is built from live-bootstrap's makefile, which names
# the programs it compiles: 62 of them, and not env, uname, date or stat.
# Nothing above noticed until gcc, whose libcpp configure runs its
# dependency-style probe through `env' -- with no env every style fails and
# configure stops with "no usable dependency style found".
#
# stdbuf is not installed because libstdbuf.so cannot be built into a static
# link, and getcwd's PATH_MAX answers are given rather than probed.
{
  derivationWithMeta,
  system,
  platforms,
  tinycc,
  gnumake,
  gnused,
  gnugrep,
  gnutar,
  gzip,
  gawk,
  bash,
  coreutils,
}:
let
  pname = "coreutils";
  version = "9.10";

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/coreutils/coreutils-${version}.tar.gz";
    sha256 = "e0bde1fb68509447fc723cf2517e8a8c7fa46769919bb7490ed350a2e9238562";
  };

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnutar}/bin"
    "${gzip}/bin"
    "${gawk}/bin"
    "${tinycc}/bin"
    "${bash}/bin"
  ];

  CC = "${tinycc}/bin/tcc -B ${tinycc}/lib";
  AR = "${tinycc}/bin/tcc -ar";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./musl-build.sh
  ];

  meta = {
    description = "GNU Core Utilities, linked against musl";
    homepage = "https://www.gnu.org/software/coreutils";
    license = "gpl3Plus";
    inherit platforms;
  };
}
