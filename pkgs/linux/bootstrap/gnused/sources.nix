# The sed source, shared by the two builds of it.
#
# Both compile the same 4.0.9 from the same live-bootstrap makefile; only the
# C library underneath differs, so the fetches live here rather than being
# written out twice.
{ }:
let
  version = "4.0.9";

  fetchurl = import <nix/fetchurl.nix>;
in
{
  inherit version;

  src = fetchurl {
    url = "https://ftp.gnu.org/gnu/sed/sed-${version}.tar.gz";
    sha256 = "c365874794187f8444e5d22998cd5888ffa47f36def4b77517a808dec27c0600";
  };

  # sed's own Makefile comes from a configure script that needs a sed to run,
  # so the makefile comes from live-bootstrap instead.
  makefile = fetchurl {
    url = "https://raw.githubusercontent.com/fosslinux/live-bootstrap/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/sed-4.0.9/mk/main.mk";
    name = "main.mk";
    sha256 = "cad7c18d085399d640e23a7feb70b36a378ed7f7dd5053c350f49707622e2e70";
  };
}
