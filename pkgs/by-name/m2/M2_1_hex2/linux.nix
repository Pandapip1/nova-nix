{
  stage0-src,
  stage0-run,
  M1,
  M2_1_M1,
  M2_1_footer_M1,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M2-1.hex2";
  builder = M1;
  args = [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    M2_1_M1
    "-f"
    M2_1_footer_M1
    "-o"
    out
  ];
}
