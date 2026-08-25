{
  stage0-src,
  stage0-run,
  catm,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M0.hex2";
  builder = catm;
  args = [
    out
    "${src}/x86/ELF-i386.hex2"
    "${src}/x86/M0_x86.hex2"
  ];
}
