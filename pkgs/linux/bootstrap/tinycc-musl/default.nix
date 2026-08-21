# TinyCC rebuilt against musl.
#
# The tcc below this was built against the Mes C library and carries it in its
# predefined macros -- it cannot compile anything without <mes/config.h> on
# the include path.  This one knows only musl, and is the compiler everything
# above uses.
#
# Built twice: 0.9.27 does not self-host against the Mes C library but does
# against musl, so the first is produced by the old compiler and the second by
# itself.  The second is installed.
{
  derivationWithMeta,
  system,
  platforms,
  tinycc,
  musl,
  gnumake,
  gnused,
  gnugrep,
  gnutar,
  gzip,
  bash,
  coreutils,
}:
let
  pname = "tinycc-musl";
in
derivationWithMeta {
  inherit pname system;
  inherit (tinycc) version;

  src = tinycc.mainlineSrc;
  musl = "${musl}";
  mesLibs = tinycc.libs;

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnutar}/bin"
    "${gzip}/bin"
    "${tinycc.compiler}/bin"
    "${bash}/bin"
  ];

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./build.sh
  ];

  meta = {
    description = "Small, fast, and embeddable C compiler, linked against musl";
    homepage = "https://repo.or.cz/w/tinycc.git";
    license = "lgpl21Only";
    inherit platforms;
  };
}
