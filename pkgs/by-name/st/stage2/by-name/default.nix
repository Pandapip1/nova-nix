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
