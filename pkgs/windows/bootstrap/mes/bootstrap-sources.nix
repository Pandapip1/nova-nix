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

  rev = "a837e37c341d1c539ca00bf8b4ebd0e100a5fc2b";
  ref = "windows-pe32-ntcall";

  src = builtins.fetchGit {
    url = "https://github.com/Pandapip1/mes.git";
    inherit rev ref;
  };
}
