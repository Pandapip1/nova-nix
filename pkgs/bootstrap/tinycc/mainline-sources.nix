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
# The fork's own mob, pinned by explicit rev rather than by the
# ntlibc-toolchain branch name this used to track. ntlibc-toolchain was a
# bookmark at the same commit this pin used to sit on (69eed4d3) and does not
# move on its own; mob has since carried that commit forward as an ancestor,
# so pinning mob is a strict superset, not a divergence -- confirmed against
# the fork directly, not assumed: `git log fork/ntlibc-toolchain --not
# fork/mob` is empty, `git merge-base --is-ancestor 69eed4d3 fork/mob`
# succeeds, and mob's tccpe.c/libtcc.c still carry the --delay-all work
# ntlibc's own build needs (its Makefile links two tests with --delay-all;
# its $ORIGIN-style resolution in src/internal/rpath.c/delayload.c depends on
# the delay-load thunk that flag enables). mob additionally carries the
# .file/PARSE_FLAG_TOK_STR fix (a real upstream parser bug -- clearing the
# flag on `.file` and never restoring it broke every `tok == TOK_STR` check
# for the rest of the translation unit, including a `.type` SIGSEGV), a
# PE-COFF object reader, and PE section-alignment work.
#
# rev is a merge commit (6118fc91): fetchGit is given the full rev so a
# shallow/single-commit fetch assumption elsewhere is not relied on.
{ }:
rec {
  version = "unstable-2026-08-25";

  rev = "6118fc91b1435a64bb3539bf03c0de87e75ef3b5";
  ref = "mob";

  src = builtins.fetchGit {
    url = "https://github.com/Pandapip1/tinycc.git";
    inherit rev ref;
  };
}
