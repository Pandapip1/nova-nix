# GNU diffutils 3.8, compiled by tcc.
#
# binutils' configure runs cmp, and gcc's build compares generated files
# against what it has; neither gets far without this.
{
  derivationWithMeta,
  system,
  platforms,
  tinycc,
  gnumake,
  gnused,
  gnugrep,
  gawk,
  bash,
  coreutils,
  stage0,
}:
let
  pname = "diffutils";
  version = "3.8";

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/diffutils/diffutils-${version}.tar.xz";
    sha256 = "a6bdd7d1b31266d11c4f4de6c1b748d4607ab0231af5188fc2533d0ae2438fec";
  };

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gawk}/bin"
    "${tinycc}/bin"
    "${bash}/bin"
    "${stage0.mescc-tools-extra.bin}/bin"
  ];

  # Compiled against musl, not the Mes C library: diffutils 3.8's configure
  # looks for socklen_t and stops when it cannot find one, which is the point
  # at which a package has outgrown the libc that got the bootstrap started.
  CC = "${tinycc}/bin/tcc -static -B ${tinycc}/lib";
  AR = "${tinycc}/bin/tcc -ar";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./build.sh
  ];

  meta = {
    description = "Commands for showing the differences between files";
    homepage = "https://www.gnu.org/software/diffutils";
    license = "gpl3Plus";
    inherit platforms;
  };
}
