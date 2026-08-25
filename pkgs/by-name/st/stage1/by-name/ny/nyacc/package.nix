# Nyacc: the parser modules MesCC loads.  Source only -- there is nothing to
# build, so the scope exposes the tree and the module directory within it.
#
# It belongs to stage1 because Mes and the Mes-to-TinyCC transition consume
# it.  It is still a source-only scope rather than a derivation.
{ lib, newScope }:

lib.makeScope newScope (
  self:
  with self;
  rec {
    version = "1.09.1";
    src = builtins.fetchGit {
      url = "https://git.savannah.nongnu.org/git/nyacc.git";
      ref = "refs/tags/V${version}";
      rev = "a88fa2498b1026a33e0c97746735740a057f6fbf";
    };

    # What goes on GUILE_LOAD_PATH.  Mes splits that variable on colons, so on
    # Windows this has to be quoted by whoever sets it -- see the Mes fork's
    # search-path-quote.
    guilePath = "${src}/module";
  }
)
