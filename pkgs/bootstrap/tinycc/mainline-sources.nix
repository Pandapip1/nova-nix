# The pinned mainline TinyCC source.
#
# The bootstrappable fork stops at 0.9.27 and carries changes made to let
# MesCC compile it; this is upstream TinyCC, which the fork's last round is
# able to build and which everything above wants instead.  The revision is
# the one nixpkgs' minimal-bootstrap pins -- or was, until ntlibc needed
# thread-local storage.
#
# ntlibc's errno is a __thread int, which is what C and POSIX ask errno to
# be and what the PE TLS directory exists for.  Upstream added Windows TLS
# for i386, x86-64 and arm64 in 38059770 (2026-07-28), after the revision
# nixpkgs pins (cb41cbfe, 2025-12-03) -- before it, __thread is not a
# keyword at all and a file using one fails to parse.  So the pin moves
# forward to a revision that carries it.
#
# Fetched by git rather than from repo.or.cz's snapshot service, which now
# answers an anti-bot challenge page instead of a tarball -- what comes back
# is HTML, and no hash of it means anything.  The git protocol is unaffected.
#
# The fork's ntlibc-toolchain branch, not repo.or.cz's mob (the fork's own
# mob is a plain mirror of it).  It is upstream mob plus six commits:
# -Wl,--delay-all and the delay-load import emission behind it, the split
# between delay-load and ordinary imports, and a tccasm fix for an "=m"
# operand on an array struct member reached through a pointer.  ntlibc needs
# all of it -- its Makefile links the delay-load tests with --delay-all, and
# its own $ORIGIN-style resolution (src/internal/rpath.c, delayload.c) works
# by intercepting imports that a delay-load thunk, not the loader, resolves.
# Without the flag those two tests are the only ones in its suite that
# cannot even be built.
{ }:
rec {
  version = "unstable-2026-08-23";

  rev = "69eed4d346f31dea12d61b99f60298d2f59f66be";
  ref = "ntlibc-toolchain";

  src = builtins.fetchGit {
    url = "https://github.com/Pandapip1/tinycc.git";
    inherit rev ref;
  };
}
