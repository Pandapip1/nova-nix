{
  stage0-src,
  stage0-run,
  M1_macro_1_hex2,
  hex2_1,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M1";
  builder = hex2_1;
  args = [
    "--architecture"
    "x86"
    "--little-endian"
    "--base-address"
    "0x8048000"
    "-f"
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    "-f"
    M1_macro_1_hex2
    "-o"
    out
  ];
}
