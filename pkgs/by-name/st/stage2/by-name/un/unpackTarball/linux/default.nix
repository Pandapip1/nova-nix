# Unpack a gzipped tarball with the tools this bootstrap built.
#
# Everything above tcc arrives as a release tarball rather than a git tree,
# because that is what the projects publish and what their build scripts
# expect to find.  fetchGit cannot help there, and a store path is read-only,
# so a package that has to patch its source unpacks it first: untar writing
# into $out IS the copy, which matters because mescc-tools-extra's cp handles
# one file at a time and nothing here can copy a tree.
{
  stdenv,
  system,
  platforms,
  stage0,
}:
{
  name,
  version,
  tarball,
}:
stdenv.mkDerivation {
  pname = name;
  inherit version system;

  inherit tarball;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;
  bin_ungz = stage0.mescc-tools-extra.ungz;
  bin_untar = stage0.mescc-tools-extra.untar;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "Unpacked ${name} source";
    inherit platforms;
  };
}
