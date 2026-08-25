{
  stage0-src,
  stage0-run,
  M1_0,
  M1_macro_1_M1,
  M1_macro_1_footer_M1,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M1-macro-1.hex2";
  builder = M1_0;
  args = [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    M1_macro_1_M1
    "-f"
    M1_macro_1_footer_M1
    "-o"
    out
  ];
}
