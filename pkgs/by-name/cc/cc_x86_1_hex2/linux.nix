{
  stage0-src,
  stage0-run,
  catm,
  cc_x86_0_hex2,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "cc_x86-1.hex2";
  builder = catm;
  args = [
    out
    "${src}/x86/ELF-i386.hex2"
    cc_x86_0_hex2
  ];
}
