# GNU sed 4.0.9, compiled by tcc against musl.
#
# The same sed as default.nix, from the same makefile -- what changes is the C
# library under it.  Built against Mes's, getc and ungetc on stdin do not
# agree with each other: sed's test_eof reads a character, pushes it back and
# gets EOF, so `$' matches the first line of a pipe and `N' ends the script.
# A modern config.status pipes its substitution table through
# `sed '/^[^""]/{N;s/\n//}'', which under that sed emits one line instead of
# the whole table -- and every configure downstream then fails while creating
# its Makefile.
#
# Nothing in sed is wrong, so nothing here is patched: it is compiled against
# a C library whose stdio holds up.  4.0.9 still needs no configure of its
# own, which is why the version does not move either.
{
  derivationWithMeta,
  system,
  platforms,
  stage0,
  tinycc,
  gnumake,
  bash,
  coreutils,
}:
let
  pname = "gnused-musl";

  sources = import ./sources.nix { };
  inherit (sources) version;
in
derivationWithMeta {
  inherit pname version system;

  tarball = sources.src;
  inherit (sources) makefile;

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${tinycc}/bin"
    "${stage0.mescc-tools-extra.bin}/bin"
  ];

  CC = "${tinycc}/bin/tcc -static -B ${tinycc}/lib";
  AR = "${tinycc}/bin/tcc -ar";

  # Anything but "mes": the makefile compiles lib/getline for the Mes C
  # library and lib/alloca for one that has getline already, which musl does.
  libc = "musl";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./build.sh
  ];

  meta = {
    description = "GNU sed, a batch stream editor, linked against musl";
    homepage = "https://www.gnu.org/software/sed";
    license = "gpl3Plus";
    inherit platforms;
  };
}
