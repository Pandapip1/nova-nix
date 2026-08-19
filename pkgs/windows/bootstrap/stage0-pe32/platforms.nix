# Platform-specific constants for the stage0-pe32 chain.
#
# There is only one target today, so these are constants rather than a lookup
# keyed on the host platform as nixpkgs' platforms.nix is; the file exists so
# that a second target is a table here instead of a sweep through the chain.
{ }:
{
  # meta.platforms
  platforms = [
    "x86-windows"
    "x86_64-windows"
  ];

  # The system every link builds for: the chain emits 32-bit PE32 binaries, so
  # this is x86-windows rather than the host's x86_64-windows.  A 64-bit
  # Windows host runs them under WoW64 regardless, the way a 64-bit Linux host
  # configured with extra-platforms runs i686-linux derivations directly --
  # nix does not require system to match the host's own, only that something
  # present can execute it.
  system = "x86-windows";

  # The architecture as stage0-pe32 spells it in the names of the programs:
  # hex0_x86.hex0, hex2_x86.hex1, M0_x86.hex2.
  stage0Arch = "x86";

  # ... and as it spells it in the two files that are not programs:
  # PE32-i386.hex2 and ntdll-i386.hex2.  Upstream stage0-posix draws the same
  # distinction, naming its programs after x86 and its header after i386.
  pe32Arch = "i386";
}
