# The pinned stage0-posix source: every byte the chain assembles.
#
# nixpkgs fetches its equivalent as a NAR fixed-output derivation, because the
# tool that produces the archive is itself built from nixpkgs and a plain
# fetcher would close the loop.  nova-nix has no such loop -- nothing in this
# tree is built from the bootstrap -- so the source is fetched directly.
#
# Upstream vendors M2-Planet, M2libc, mescc-tools and the bootstrap seeds as
# git submodules, and the build script reads them at those paths, so
# `submodules = true` is what makes `src` complete.  A GitHub archive tarball
# cannot stand in: it does not walk submodules.
#
# The seed comes from the same fetch, and its executable bit with it -- git
# records bootstrap-seeds/POSIX/x86/hex0-seed as 100755, and fetchGit restores
# that.  On Linux the bit is the only thing that makes the seed runnable, so
# the chain would not start without it.
#
# To move the pin: change `rev` (and `ref`, if it points somewhere other than
# the default branch), then re-evaluate -- fetchGit reports the new pin's own
# `rev`/`narHash`, there is nothing to prefetch by hand.
{ }:
rec {
  version = "0-unstable-2026-07-05";

  rev = "643598041bf7639883874fe2cdc9d9693c9b03d5";
  ref = "master";

  src = builtins.fetchGit {
    url = "https://github.com/oriansj/stage0-posix.git";
    inherit rev ref;
    submodules = true;
  };
}
