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

  # The system every link builds for: the chain emits 32-bit ELF binaries, so
  # this is i686-linux rather than the host's x86_64-linux.  A 64-bit host runs
  # them directly, the way nix does with extra-platforms -- system says what
  # the output is, not what built it.
  system = "i686-linux";

  # The architecture as stage0-posix spells it in the names of the programs:
  # hex0_x86.hex0, hex2_x86.hex1, M0_x86.hex2.
  stage0Arch = "x86";
}
