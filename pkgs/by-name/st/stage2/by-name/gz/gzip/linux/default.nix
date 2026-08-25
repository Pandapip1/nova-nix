# gzip 1.2.4, compiled by tcc.
#
# The last of the tools the packages above assume.  With tar and gzip both
# built here, a release tarball can be opened by this bootstrap's own
# programs rather than by the unpackers mescc-tools-extra supplied to get it
# started.
{
  derivationWithMeta,
  system,
  platforms,
  stage0,
  tinycc,
  gnumake,
  gnused,
  gnugrep,
  bash,
  coreutils,
  mesInclude,
}:
let
  pname = "gzip";
  version = "1.2.4";

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/gzip/gzip-${version}.tar.gz";
    sha256 = "1ca41818a23c9c59ef1d5e1d00c0d5eaa2285d931c0fb059637d7c0cc02ad967";
  };

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${tinycc.compiler}/bin"
    "${bash}/bin"
    "${stage0.mescc-tools-extra.bin}/bin"
  ];

  CC = "${tinycc.compiler}/bin/tcc -static -B ${tinycc.libs}/lib -I ${mesInclude}";
  AR = "${tinycc.compiler}/bin/tcc -ar";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./build.sh
  ];

  meta = {
    description = "GNU zip compression program";
    homepage = "https://www.gnu.org/software/gzip";
    license = "gpl3Plus";
    inherit platforms;
  };
}
