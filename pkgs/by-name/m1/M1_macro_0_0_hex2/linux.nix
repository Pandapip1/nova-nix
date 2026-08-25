{
  stage0-src,
  stage0-run,
  M1_macro_0_hex2,
  catm,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M1-macro-0-0.hex2";
  builder = catm;
  args = [
    out
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    M1_macro_0_hex2
  ];
}
