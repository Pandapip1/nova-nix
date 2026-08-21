# The file utilities every build above this bootstrap needs.
#
# Not part of the chain that produces a compiler: these are the small programs
# a build script reaches for once it has one -- mkdir, cp, chmod, rm, catm,
# replace, and the unpackers (untar, ungz, unbz2, unxz) that turn a release
# tarball into a source tree.
#
# Nothing in them needed porting.  They are ordinary C, they stand on the same
# M2libc the C-written hex2 already stands on, and the two calls they make
# that Windows has no answer for -- chmod and umask -- M2libc's Windows target
# accepts and ignores, since a Windows file has no mode bits to set.
#
# The counterpart of ../../../linux/bootstrap/stage0-posix/mescc-tools-extra.nix,
# which builds the same list from the same sources with the same tools; what
# differs is the C library underneath and the executable format on top, and
# both of those are m2-program.nix's business rather than this file's.
{
  derivationWithMeta,
  src,
  version,
  system,
  platforms,
  m2-program,
  kaem,
}:
let
  # Upstream's list, less sha3sum, which nothing above asks for.
  names = [
    "sha256sum"
    "match"
    "mkdir"
    "untar"
    "ungz"
    "unbz2"
    "unxz"
    "catm"
    "cp"
    "chmod"
    "rm"
    "replace"
    "wrap"
  ];

  tools = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = m2-program.program name (
        m2-program.libcSources
        ++ [
          "-f"
          "${src}/mescc-tools-extra/${name}.c"
        ]
      );
    }) names
  );
in
tools
// {
  # Everything above wants one directory to put on PATH, not thirteen paths.
  # Assembled by the utilities themselves: mkdir makes the directory and cp
  # fills it.  Unlike the Linux side there is no chmod pass -- a PE32 file is
  # runnable because of what is in its header, not because of a mode bit.
  bin = derivationWithMeta (
    {
      pname = "mescc-tools-extra";
      inherit version system;

      builder = kaem;
      args = [
        "--verbose"
        "--strict"
        "--file"
        ./mescc-tools-extra-bin.kaem
      ];

      meta = {
        description = "Collection of tools written for use in bootstrapping";
        homepage = "https://github.com/oriansj/mescc-tools-extra";
        inherit platforms;
        license = "gpl3Plus";
      };
    }
    # One environment variable per utility, which is how the script names
    # them: `derivation` turns every attribute into one.
    // builtins.listToAttrs (
      map (name: {
        name = "bin_${name}";
        value = tools.${name};
      }) names
    )
  );
}
