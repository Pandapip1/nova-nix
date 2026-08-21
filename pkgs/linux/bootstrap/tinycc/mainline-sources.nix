# The pinned mainline TinyCC source.
#
# The bootstrappable fork stops at 0.9.27 and carries changes made to let
# MesCC compile it; this is upstream TinyCC, which the fork's last round is
# able to build and which everything above wants instead.  The revision is
# the one nixpkgs' minimal-bootstrap pins.
#
# Fetched by git rather than from repo.or.cz's snapshot service, which now
# answers an anti-bot challenge page instead of a tarball -- what comes back
# is HTML, and no hash of it means anything.  The git protocol against the
# same host is unaffected.
{ }:
rec {
  version = "unstable-2025-12-03";

  rev = "cb41cbfe717e4c00d7bb70035cda5ee5f0ff9341";
  ref = "mob";

  src = builtins.fetchGit {
    url = "https://repo.or.cz/tinycc.git";
    inherit rev ref;
  };
}
