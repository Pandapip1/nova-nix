# derivation, plus the metadata nix's builtin has no room for.
#
# `derivation` turns every attribute it is given into an environment variable
# for the builder, so it cannot carry an attrset like `meta`.  nixpkgs solves
# this in lib.customisation; the bootstrap cannot reach nixpkgs, so it has its
# own -- see pkgs/os-specific/linux/minimal-bootstrap/utils.nix, which exists
# for the same reason.
#
# `meta` and `passthru` are stripped before the derivation is built and put
# back on the result afterwards, so they describe the package without changing
# what is built: adding a description must not change a store path.
#
# The result is a plain attrset rather than nixpkgs' lib.extendDerivation
# wrapper, which is enough for interpolation (`${pkg}` still finds outPath) and
# for naming a dependency.
{ }:
attrs:
let
  meta = attrs.meta or { };
  passthru = attrs.passthru or { };

  drv = derivation (
    builtins.removeAttrs attrs [
      "meta"
      "passthru"
    ]
    // {
      # Redefined from pname/version so that a package may still set `name`
      # outright, as `derivation` requires one either way.
      name = attrs.name or "${attrs.pname}-${attrs.version}";
    }
  );
in
drv // passthru // { inherit meta passthru; }
