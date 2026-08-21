# The pinned GNU Mes source: the stage above stage0-posix.
#
# Upstream, from savannah, at the 0.27.1 release tag.  The Windows set pins a
# fork instead, because upstream has no Windows backend; nothing on this side
# needs one, so this is the release as published.
#
# To move the pin: change `rev` (and `ref`), then re-evaluate -- fetchGit
# reports the new pin's own `rev`/`narHash`, there is nothing to prefetch by
# hand.
{ }:
rec {
  version = "0.27.1";

  # refs/tags/v0.27.1 (an annotated tag; this is the commit it names).
  rev = "c331d801da386ba752f3fe92d0538102a90e988d";
  ref = "refs/tags/v0.27.1";

  src = builtins.fetchGit {
    url = "https://git.savannah.gnu.org/git/mes.git";
    inherit rev ref;
  };

  # ldexpl, which 0.27.1 does not have and mainline TinyCC needs: tccpp.c
  # calls it when it parses a floating-point constant, and without it tcc
  # links with an undefined symbol.
  #
  # Upstream added it after the release, on a branch rather than in a tag, so
  # it is pinned as its own revision and one file is taken from it.  nixpkgs'
  # minimal bootstrap vendors a copy of this same file for the same reason,
  # saying the Mes GitLab force-pushes too often to link to; savannah is
  # where the commit actually lives, and a revision there does not move.
  ldexpl = {
    rev = "315238d4cc26b9f64849d74f07c7f56343cadeae";
    ref = "wip-bootstrap-x86_64";
  };

  ldexplSrc = builtins.fetchGit {
    url = "https://git.savannah.gnu.org/git/mes.git";
    inherit (ldexpl) rev ref;
  };

  ldexplFile = "${ldexplSrc}/lib/math/ldexpl.c";
}
