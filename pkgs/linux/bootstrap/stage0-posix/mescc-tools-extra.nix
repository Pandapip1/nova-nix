# The file utilities every build above this bootstrap needs.
#
# Not part of the chain that produces a compiler: these are the small programs
# a build script reaches for once it has one -- mkdir, cp, chmod, rm, catm,
# replace, and the unpackers (untar, ungz, unbz2, unxz) that turn a release
# tarball into a source tree.  nova-nix's own builtin:unpack knows tar and
# zstd only, and in any case the point of a source bootstrap is that the
# unpacker is built here too.
#
# Each is compiled by M2-Planet and linked by M1 and hex2 -- the same four
# steps as every link of the chain -- rather than by M2-Mesoplanet, which
# would do it in one.  Mesoplanet finds M1 and hex2 by searching PATH, and
# there is no directory to point PATH at until these very utilities have
# assembled one, so using it here would be circular.  nixpkgs' minimal
# bootstrap breaks the same cycle the same way.
#
# The bin directory at the end is the first derivation in the tree that runs
# more than one command, and it is why the chain below bothers to build kaem:
# kaem is its builder.
{
  derivationWithMeta,
  src,
  version,
  system,
  platforms,
  stage0Arch,
  kaem,
  M2,
  M1,
  hex2,
  blood_elf_0,
}:
let
  out = builtins.placeholder "out";

  run =
    pname: builder: args:
    derivationWithMeta {
      inherit pname version system;
      builder = "${builder}";
      args = map (arg: "${arg}") args;

      meta = {
        description = "Collection of tools written for use in bootstrapping";
        homepage = "https://github.com/oriansj/mescc-tools-extra";
        license = "gpl3Plus";
        inherit platforms;
      };
    };

  # One utility, compiled and linked the way the chain links everything else.
  # M2libc's full libc rather than its core: these read and write real files.
  util = name: rec {
    M1src = run "${name}.M1" M2 [
      "--architecture"
      stage0Arch
      "-f"
      "${src}/M2libc/sys/types.h"
      "-f"
      "${src}/M2libc/stddef.h"
      "-f"
      "${src}/M2libc/sys/utsname.h"
      "-f"
      "${src}/M2libc/${stage0Arch}/linux/fcntl.c"
      "-f"
      "${src}/M2libc/fcntl.c"
      "-f"
      "${src}/M2libc/${stage0Arch}/linux/unistd.c"
      "-f"
      "${src}/M2libc/${stage0Arch}/linux/sys/stat.c"
      "-f"
      "${src}/M2libc/ctype.c"
      "-f"
      "${src}/M2libc/stdlib.c"
      "-f"
      "${src}/M2libc/stdarg.h"
      "-f"
      "${src}/M2libc/stdio.h"
      "-f"
      "${src}/M2libc/stdio.c"
      "-f"
      "${src}/M2libc/string.c"
      "-f"
      "${src}/M2libc/bootstrappable.c"
      "-f"
      "${src}/mescc-tools-extra/${name}.c"
      "--debug"
      "-o"
      out
    ];

    footer = run "${name}-footer.M1" blood_elf_0 [
      "--little-endian"
      "-f"
      M1src
      "-o"
      out
    ];

    hex2src = run "${name}.hex2" M1 [
      "--architecture"
      stage0Arch
      "--little-endian"
      "-f"
      "${src}/M2libc/${stage0Arch}/${stage0Arch}_defs.M1"
      "-f"
      "${src}/M2libc/${stage0Arch}/libc-full.M1"
      "-f"
      M1src
      "-f"
      footer
      "-o"
      out
    ];

    bin = run name hex2 [
      "--architecture"
      stage0Arch
      "--little-endian"
      "-f"
      "${src}/M2libc/${stage0Arch}/ELF-${stage0Arch}-debug.hex2"
      "-f"
      hex2src
      "--base-address"
      "0x08048000"
      "-o"
      out
    ];
  };

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
      value = (util name).bin;
    }) names
  );
in
tools
// {
  # Everything above wants one directory to put on PATH, not thirteen paths.
  # Assembled by the utilities themselves: mkdir makes the directory, cp fills
  # it, chmod makes each one runnable -- a store path is read-only when it is
  # registered, but not while it is being built.
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
        license = "gpl3Plus";
        inherit platforms;
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
