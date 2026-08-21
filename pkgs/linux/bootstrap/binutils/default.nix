# GNU binutils 2.46.0, compiled by tcc against musl.
#
# The assembler and linker gcc needs.  tcc has its own of both, and they got
# the bootstrap this far, but gcc emits assembly that only gas assembles and
# expects a linker that reads gnu ld's scripts.
#
# --disable-gprofng because it needs bison, --disable-gold and
# --disable-plugins because neither is wanted here, and --with-lib-path=: so
# that libbfd and libopcodes do not land on the default search path.
{
  derivationWithMeta,
  system,
  platforms,
  tinycc,
  gnumake,
  gnupatch,
  gnused,
  gnugrep,
  gnutar,
  gawk,
  diffutils,
  bash,
  coreutils,
  stage0,
}:
let
  pname = "binutils";
  version = "2.46.0";

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/binutils/binutils-${version}.tar.xz";
    sha256 = "d75a94f4d73e7a4086f7513e67e439e8fcdcbb726ffe63f4661744e6256b2cf2";
  };

  deterministicPatch = ./deterministic.patch;
  attributePatch = ./fix-tinycc-attribute.patch;

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnupatch}/bin"
    "${gnutar}/bin"
    "${gawk}/bin"
    "${diffutils}/bin"
    "${tinycc}/bin"
    "${bash}/bin"
    "${stage0.mescc-tools-extra.bin}/bin"
  ];

  bashPath = "${bash}/bin/bash";
  truePath = "${coreutils}/bin/true";

  CC = "${tinycc}/bin/tcc -static -B ${tinycc}/lib";
  AR = "${tinycc}/bin/tcc -ar";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./build.sh
  ];

  meta = {
    description = "Tools for manipulating binaries (linker, assembler, etc.)";
    homepage = "https://www.gnu.org/software/binutils";
    license = "gpl3Plus";
    inherit platforms;
  };
}
