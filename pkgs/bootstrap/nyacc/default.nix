# Nyacc: the parser modules MesCC loads.  Source only -- there is nothing to
# build, so the scope exposes the tree and the module directory within it.
#
# Shared by every package set: pure Scheme, saying nothing about the platform
# MesCC runs on or compiles for.
{ lib, newScope }:

lib.makeScope newScope (
  self:
  with self;
  {
    inherit (callPackage ./bootstrap-sources.nix { }) version src;

    # What goes on GUILE_LOAD_PATH.  Mes splits that variable on colons, so on
    # Windows this has to be quoted by whoever sets it -- see the Mes fork's
    # search-path-quote.
    guilePath = "${src}/module";
  }
)
