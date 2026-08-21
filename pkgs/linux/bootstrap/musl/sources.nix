# The musl source, shared by the two builds of it.
#
# Both compile the same 1.2.6; what differs is the compiler underneath and,
# with it, how much of musl can be built at all.
{ }:
let
  version = "1.2.6";

  fetchurl = import <nix/fetchurl.nix>;
in
{
  inherit version;

  src = fetchurl {
    url = "https://musl.libc.org/releases/musl-${version}.tar.gz";
    sha256 = "d585fd3b613c66151fc3249e8ed44f77020cb5e6c1e635a616d3f9f82460512a";
  };
}
