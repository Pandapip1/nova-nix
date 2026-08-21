# The tar source, shared by the two builds of it.
#
# Both compile the same 1.12; only the C library underneath differs, so the
# fetch lives here rather than being written out twice.
{ }:
let
  version = "1.12";

  fetchurl = import <nix/fetchurl.nix>;
in
{
  inherit version;

  src = fetchurl {
    url = "https://ftp.gnu.org/gnu/tar/tar-${version}.tar.gz";
    sha256 = "c6c37e888b136ccefab903c51149f4b7bd659d69d4aea21245f61053a57aa60a";
  };
}
