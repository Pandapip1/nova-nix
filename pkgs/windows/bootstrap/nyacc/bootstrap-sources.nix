# The pinned Nyacc source: the parser generator MesCC is written against.
#
# Nyacc is not vendored in the Mes tree -- Mes names it as an outside
# dependency -- and MesCC reaches for `(nyacc lang c99 parser)` the moment it
# is loaded, so it has to be on the load path before anything can be compiled.
#
# The version is not a free choice.  Mes 0.27.1 is built against 1.09.1, and
# 1.09.2 and up break it: Mes cannot parse a block comment below top level,
# which those releases introduce.  See Mes's own INSTALL, and nixpkgs'
# minimal-bootstrap, which pins the same release for the same reason.
#
# Fetched from the tag rather than the release tarball because Nyacc ships as
# .tar.gz: gzip is not something this bootstrap has yet, and the git tree
# carries the same Scheme.  Nothing here is built -- Nyacc is pure Scheme, so
# the modules are used where they lie.
{ }:
rec {
  version = "1.09.1";

  # refs/tags/V1.09.1 (an annotated tag; this is the commit it names).
  rev = "a88fa2498b1026a33e0c97746735740a057f6fbf";
  ref = "refs/tags/V1.09.1";

  src = builtins.fetchGit {
    url = "https://git.savannah.nongnu.org/git/nyacc.git";
    inherit rev ref;
  };
}
