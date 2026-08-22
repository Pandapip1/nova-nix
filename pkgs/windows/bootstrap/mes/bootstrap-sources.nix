# The pinned GNU Mes source: the stage above stage0-pe32.
#
# Upstream Mes has no Windows backend; this is the branch that adds one, and
# it is pinned the same way stage0-pe32 is -- one revision, fetched, nothing
# vendored.  `submodules` is not set because Mes has none.
#
# To move the pin: change `rev` (and `ref`, if it points somewhere other than
# the branch below), then re-evaluate -- fetchGit reports the new pin's own
# `rev`/`narHash`, there is nothing to prefetch by hand.
{ }:
rec {
  # Mes's own version, plus the date of the Windows-backend commit: this is
  # 0.27.1 with a backend upstream does not carry yet.
  version = "0.27.1-unstable-2026-08-22";

  rev = "170d4682cf9462e069e0a0ab3ed7a47b08c32604";
  ref = "windows-pe32";

  src = builtins.fetchGit {
    url = "https://github.com/Pandapip1/mes.git";
    inherit rev ref;
  };
}
