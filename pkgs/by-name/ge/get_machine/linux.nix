{
  stage0-src,
  stage0-run,
  get_machine_hex2,
  hex2,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "get_machine";
  builder = hex2;
  args = [
    "--architecture"
    "x86"
    "--little-endian"
    "--base-address"
    "0x08048000"
    "-f"
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    "-f"
    get_machine_hex2
    "-o"
    out
  ];
}
