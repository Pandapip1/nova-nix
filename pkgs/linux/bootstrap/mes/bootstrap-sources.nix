# The pinned GNU Mes source: the stage above stage0-posix.
#
# The same fork the Windows set pins, at the same revision.  Upstream has no
# Windows backend, which is why the fork exists; nothing on this side needs
# one, but one Mes for both sets is worth more than a version of its own --
# a change to the C library or to MesCC is then made once and both sets see
# it, and the two builds cannot drift into disagreeing about what Mes is.
#
# It is v0.27.1 plus twenty-seven commits, of which three are upstream's own
# post-release fixes and the rest are the Windows backend.  The tag is a
# direct ancestor, so nothing on this side lost anything by moving.
#
# To move the pin: change `rev` (and `ref`), then re-evaluate -- fetchGit
# reports the new pin's own `rev`/`narHash`, there is nothing to prefetch by
# hand.
{ }:
rec {
  # 0.27.1 plus what the branch adds; the same string the Windows set uses,
  # because it is the same source.
  version = "0.27.1-unstable-2026-08-22";

  rev = "170d4682cf9462e069e0a0ab3ed7a47b08c32604";
  ref = "windows-pe32";

  src = builtins.fetchGit {
    url = "https://github.com/Pandapip1/mes.git";
    inherit rev ref;
  };
}
