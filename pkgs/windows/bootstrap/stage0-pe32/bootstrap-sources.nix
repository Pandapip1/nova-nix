# The pinned stage0-pe32 source: every byte the chain assembles.
#
# nixpkgs fetches its equivalent as a NAR fixed-output derivation, because the
# tool that produces the archive is itself built from nixpkgs and a plain
# fetcher would close the loop.  nova-nix has no such loop -- nothing in this
# tree is built from the bootstrap -- so the source is fetched directly.
#
# From cc_x86 up the chain compiles C, and M2-Planet -- the first C it
# compiles -- stands on M2libc's bootstrap.c.  Upstream vendors M2-Planet,
# M2libc and mescc-tools as git submodules, pinned to the exact commits
# stage0-posix itself vendors them at (nothing in any of them is
# Windows-specific, so nothing needed porting but the one bootstrap.c
# stage0-pe32 carries itself).  `submodules = true` fetches them along with
# everything else, so `src` already has `M2-Planet/`, `M2libc/` and
# `mescc-tools/` at the paths stage0-pe32's own build script
# (`x86/mescc-tools-mini.cmd`) reads them from -- a plain archive tarball
# cannot do this, since a GitHub archive does not walk git submodules.
#
# To move the pin: change `rev` (and `ref`, if it points somewhere other than
# the default branch), then re-evaluate -- fetchGit reports the new pin's own
# `rev`/`narHash`, there is nothing to prefetch by hand.
{ }:
rec {
  version = "0-unstable-2026-08-20";

  rev = "b82038daad2665475c4261ab5ceced8c7d4c1d13";
  ref = "main";

  src = builtins.fetchGit {
    url = "https://github.com/Pandapip1/stage0-pe32.git";
    inherit rev ref;
    submodules = true;
  };
}
