{
  stage0-src,
  stage0-run,
  M2,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M1-macro-0.M1";
  builder = M2;
  args = [
    "--architecture"
    "x86"
    "-f"
    "${src}/M2libc/x86/linux/bootstrap.c"
    "-f"
    "${src}/M2libc/bootstrappable.c"
    "-f"
    "${src}/mescc-tools/stringify.c"
    "-f"
    "${src}/mescc-tools/M1-macro.c"
    "--bootstrap-mode"
    "--debug"
    "-o"
    out
  ];
}
