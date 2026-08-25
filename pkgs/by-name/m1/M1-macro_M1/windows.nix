{
  stage0-src,
  stage0-run,
  M2,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M1-macro.M1";
  builder = M2;
  args = [
    "--architecture"
    stage0Arch
    "--bootstrap-mode"
    "-f"
    "${src}/M2libc/x86/windows/bootstrap.c"
    "-f"
    "${src}/M2libc/bootstrappable.c"
    "-f"
    "${src}/mescc-tools/stringify.c"
    "-f"
    "${src}/mescc-tools/M1-macro.c"
    "-o"
    out
  ];
  executable = false;
}
