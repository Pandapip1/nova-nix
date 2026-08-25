# The pinned TinyCC source: Janneke's bootstrappable fork.
#
# The project's mainline fork is used as soon as TinyCC can self-host.  It
# cannot be fed directly to MesCC: at the current mob pin MesCC loses the
# parse in TCCState (reported at `jmp_buf`) and then fails expression lowering.
{ }:
rec {
  version = "0.9.27-unstable-2024-07-07";

  rev = "ea3900f6d5e71776c5cfabcabee317652e3a19ee";
  ref = "mes-0.27";

  src = builtins.fetchGit {
    url = "https://gitlab.com/janneke/tinycc.git";
    inherit rev ref;
  };
}
