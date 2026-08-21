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
}
