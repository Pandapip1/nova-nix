# The pinned mainline TinyCC source.
#
# The bootstrappable fork stops at 0.9.27 and carries changes made to let
# MesCC compile it; this is the project's TinyCC fork, which the bootstrap
# fork's last round is able to build and which everything above wants instead.
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
# rev is a merge commit lineage: fetchGit is given the full rev so a
# shallow/single-commit fetch assumption elsewhere is not relied on.
#
# Bumped past 6118fc91 to 7d9b1b53: lands the real-`gcc -S` GAS directive
# gaps fix (.zero, .section flags/type/entsize and its default type from
# name, .p2align empty-middle and max-skip, .comm/.local/.lcomm,
# .uleb128/.sleb128, forward local-label arithmetic, sym@PLT, cltq/sall/
# salq) -- differentially tested against GNU as. Also fixes a silent-
# miscompile in `movl $imm, sym(%rip)` under a real (non-tcc) linker (the
# %rip correction landed on the stored displacement; tcc's own linker
# compensated so `tcc -run` always looked fine, but GNU ld linked 4 bytes
# off -- any gcc-linked-by-a-real-linker result from before this fix may be
# silently wrong even if it looked fine under this chain's own tcc linker,
# though this chain has never linked with anything but its own tcc). Also
# hardens the PE-COFF reader itself: a silent-relocation-loss bug (a
# truncated count made it exit 0 having discarded every relocation, no
# diagnostic -- the exact objcopy failure mode the reader exists to
# prevent) and a 4-byte-patch SIGSEGV, both fixed, 180,000 fuzz inputs
# clean afterward. `.file` no longer remaps diagnostic line numbers (every
# earlier assembler error's line number in this project's own history may
# have been wrong), and inline-asm's separate off-by-one is fixed too.
#
# Still broken as of this pin, noted so a stall reads as expected rather
# than a fresh regression: SSE2 scalar float (movsd/addsd/cvtss2sd) is
# unknown-opcode, so any translation unit with floating point still fails
# to assemble -- the next real blocker. `.cfi_*` are accepted and dropped
# with a warning (no .eh_frame -- survivable for C, not C++/_Unwind_*).
# `.loc` is unimplemented, so `gcc -S -g` still doesn't assemble. `.type`/
# `.size` before a label are dropped, so tcc-assembled objects carry no
# symbol sizes.
{ }:
rec {
  version = "unstable-2026-08-25b";

  rev = "7d9b1b534e2a622b03f9b31e3e77c73c552a6efe";
  ref = "mob";

  src = builtins.fetchGit {
    url = "https://github.com/Pandapip1/tinycc.git";
    inherit rev ref;
  };
}
