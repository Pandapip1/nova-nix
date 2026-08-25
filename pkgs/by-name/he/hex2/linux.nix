{
  stage0-src,
  stage0-run,
  hex2_1,
  hex2_linker_2_hex2,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "hex2";
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
    hex2_linker_2_hex2
    "-o"
    out
  ];
}
