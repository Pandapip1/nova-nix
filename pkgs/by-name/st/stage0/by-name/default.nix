# The stage0 bootstrap is a package set of its own.  Its by-name values
# see both their siblings and the enclosing package set through the scope's
# callPackage, while the shard remains only a filesystem detail.
{ callPackage }:
let
  root = ./.;
  inShard =
    shard:
    map (pname: {
      name = pname;
      value = callPackage (root + "/${shard}/${pname}/package.nix") { };
    }) (
      builtins.filter
        (pname: builtins.pathExists (root + "/${shard}/${pname}/package.nix"))
        (builtins.attrNames (builtins.readDir (root + "/${shard}")))
    );
in
builtins.listToAttrs (
  builtins.concatMap inShard (
    builtins.filter (name: name != "default.nix") (builtins.attrNames (builtins.readDir root))
  )
)
