/* src/version.c, which the release process generates from build-aux and the
 * repository's own tags -- not from a .in template, so the tarball ships no
 * un-substituted copy of it at all, the way it does for paths.h.in.  What it
 * has to contain is one constant, read by src/system.h's --version handling
 * in all four programs: the version string this port is asserting, "3.8",
 * matching PACKAGE_VERSION/VERSION in config.h and this package's own
 * pname/version in default.nix.
 */
#include <config.h>
char const *Version = "3.8";
