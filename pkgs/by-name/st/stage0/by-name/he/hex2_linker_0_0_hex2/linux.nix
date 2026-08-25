{
  stage0-src,
  stage0-run,
  catm,
  hex2_linker_0_hex2,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "hex2_linker-0-0.hex2";
  builder = catm;
  args = [
    out
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    hex2_linker_0_hex2
  ];
}
