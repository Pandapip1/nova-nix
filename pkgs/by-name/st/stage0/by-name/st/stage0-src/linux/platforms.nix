# Platform-specific constants for the stage0-posix chain.
#
# There is only one target today, so these are constants rather than a lookup
# keyed on the host platform as nixpkgs' platforms.nix is; the file exists so
# that a second target is a table here instead of a sweep through the chain.
{ }:
{
  # meta.platforms
  platforms = [
    "i686-linux"
    "x86_64-linux"
  ];

  # Nix's derivation system identifies the platform that runs the builder.
  # The seed and early compiler outputs are i686 ELF binaries, but they run as
  # part of this bootstrap on the x86_64 Linux build platform.
  system = "x86_64-linux";

  # The architecture as stage0-posix spells it in the names of the programs:
  # hex0_x86.hex0, hex2_x86.hex1, M0_x86.hex2.
  stage0Arch = "x86";
}
