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
# is HTML, and no hash of it means anything.  The git protocol against the
# same host is unaffected.
{ }:
rec {
  version = "unstable-2026-08-04";

  rev = "2ba12e83b3599ca8f5d50c179fe5138fe956f0c9";
  ref = "mob";

  src = builtins.fetchGit {
    url = "https://repo.or.cz/tinycc.git";
    inherit rev ref;
  };
}
