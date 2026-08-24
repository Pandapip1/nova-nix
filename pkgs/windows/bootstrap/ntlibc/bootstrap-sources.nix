# The pinned ntlibc source: the C library the Windows chain targets once
# there is a real compiler to build it with.
#
# Mes's C library got the bootstrap as far as a self-hosting tcc and is not
# meant to go further -- it has no threads, no real signals, a bump
# allocator that never frees, and a POSIX surface thin enough that anything
# above tcc trips over it.  ntlibc is the counterpart of musl on the Linux
# side: the library everything after tcc is built against.
#
# Pinned the same way stage0-pe32 and Mes are -- one revision, fetched,
# nothing vendored.
#
# To move the pin: change `rev` (and `ref`, if it points somewhere other
# than the branch below), then re-evaluate -- fetchGit reports the new
# pin's own `rev`/`narHash`, there is nothing to prefetch by hand.
{ }:
rec {
  version = "0-unstable-2026-08-24";

  rev = "a9d3b48c2ae6b3656b8ed82730f9f15df1c6fd10";
  ref = "main";

  src = builtins.fetchGit {
    url = "https://github.com/Pandapip1/ntlibc.git";
    inherit rev ref;
  };
}
