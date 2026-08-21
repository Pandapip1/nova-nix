# The pinned TinyCC source: janneke's bootstrappable fork.
#
# Mainline TinyCC cannot be compiled by MesCC; this fork is the one that can,
# and Mes's own README names it as the next step above Mes.  The revision is
# the one nixpkgs' minimal-bootstrap pins for Mes 0.27.1, and it sits on the
# fork's mes-0.27 branch -- the branch that tracks this Mes.
#
# The version is 0.9.27 by the tree's own VERSION file, not the 0.9.26 the
# fork is often described by.
{ }:
rec {
  version = "0.9.27-unstable-2024-07-07";

  rev = "ea3900f6d5e71776c5cfabcabee317652e3a19ee";
  ref = "mes-0.27";

  src = builtins.fetchGit {
    url = "https://gitlab.com/janneke/tinycc.git";
    inherit rev ref;
  };
}
