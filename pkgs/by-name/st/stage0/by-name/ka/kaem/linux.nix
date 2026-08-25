{
  stage0-src,
  stage0-run,
  hex2,
  kaem_hex2,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "kaem";
  builder = hex2;
  args = [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    "-f"
    kaem_hex2
    "--base-address"
    "0x8048000"
    "-o"
    out
  ];
}
