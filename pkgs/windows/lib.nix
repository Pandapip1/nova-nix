# The small amount of lib this package set needs.
#
# nixpkgs gets these from `lib`; nova-nix has no nixpkgs to draw on while
# bootstrapping itself, so the two functions that make a package set a package
# set are defined here, in terms of builtins only.
rec {
  # callPackageWith autoArgs fn args
  #
  # Import `fn` and call it with the arguments it names, taken from `autoArgs`,
  # with `args` overriding.  This is what lets a package.nix declare its
  # dependencies as formal parameters -- { stdenv, zlib }: ... -- instead of
  # reaching across the tree with a relative import.  Modelled on nixpkgs'
  # lib.customisation.callPackageWith, minus the override machinery and the
  # spelling suggestions.
  callPackageWith =
    autoArgs: fn: args:
    let
      f = if builtins.isFunction fn then fn else import fn;
      fargs = builtins.functionArgs f;

      # Everything the function will receive: the automatic arguments it named,
      # plus the explicit ones.
      allArgs = builtins.intersectAttrs fargs autoArgs // args;

      # Formals we could not supply.  The attribute's value is true when the
      # formal has a default, so an unsupplied one is only an error if false.
      unpassed = builtins.removeAttrs fargs (builtins.attrNames allArgs);
      required = builtins.filter (name: !unpassed.${name}) (builtins.attrNames unpassed);
    in
    if required == [ ] then
      f allArgs
    else
      throw "callPackage: ${toString fn} called without required argument(s): ${builtins.concatStringsSep ", " required}";

  # makeScope newScope f
  #
  # A package set layered over an enclosing one.  `f` receives the scope being
  # defined, so a package in it may name a sibling -- hex1 is built by hex0 --
  # without that name reaching the enclosing set.  `newScope` is the enclosing
  # set's own scope constructor, which is what makes the layering work: the
  # inner set sees everything the outer one has, plus itself.
  #
  # Modelled on nixpkgs' lib.customisation.makeScope, minus overrideScope and
  # the package-set metadata.
  makeScope =
    newScope: f:
    let
      self =
        f self
        // {
          newScope = scope: newScope (self // scope);
          callPackage = self.newScope { };
        };
    in
    self;
}
