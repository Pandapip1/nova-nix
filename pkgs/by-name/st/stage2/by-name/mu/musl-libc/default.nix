# musl 1.2.6, compiled by tcc: the C library that replaces Mes's.
#
# Everything below this point was compiled against a C library written to be
# small enough to bootstrap, and the packages show it -- versions chosen for
# what they do not need, patches for strcoll and mbstate_t, a coreutils whose
# touch cannot set a timestamp.  musl is a real C library.  From here up, a
# program can expect what its authors expected.
{
  derivationWithMeta,
  system,
  platforms,
  stage0,
  tinycc,
  gnumake,
  gnupatch,
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

  fetchurl = import <nix/fetchurl.nix>;
in
derivationWithMeta {
  inherit pname version system;

  tarball = sources.src;

  # tcc cannot assemble the backward jecxz that sigsetjmp uses.
  sigsetjmpPatch = fetchurl {
    url = "https://raw.githubusercontent.com/fosslinux/live-bootstrap/d98f97e21413efc32c770d0356f1feda66025686/sysa/musl-1.1.24/patches/sigsetjmp.patch";
    name = "sigsetjmp.patch";
    sha256 = "c1dd807afd733c95f2deaf77dda8aea79a7520c2b354906ab80ca5de06cae0f5";
  };

  toolPath = builtins.concatStringsSep ":" [
    "${coreutils}/bin"
    "${gnumake}/bin"
    "${gnused}/bin"
    "${gnugrep}/bin"
    "${gnupatch}/bin"
    "${gnutar}/bin"
    "${gzip}/bin"
    "${tinycc.compiler}/bin"
    "${bash}/bin"
  ];

  bashPath = "${bash}/bin/bash";
  libtcc1 = "${tinycc.libs}/lib/libtcc1.a";

  CC = "${tinycc.compiler}/bin/tcc -static -B ${tinycc.libs}/lib";
  AR = "${tinycc.compiler}/bin/tcc -ar";

  builder = "${bash}/bin/bash";
  args = [
    "-e"
    ./build.sh
  ];

  meta = {
    description = "An efficient, small, quality libc implementation";
    homepage = "https://musl.libc.org";
    license = "mit";
    inherit platforms;
  };
}
