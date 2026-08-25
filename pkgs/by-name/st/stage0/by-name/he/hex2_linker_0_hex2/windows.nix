{
  stage0-src,
  stage0-run,
  catm,
  hex2_linker_hex2,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "hex2_linker-0.hex2";
  builder = catm;
  args = [
    out
    "${src}/x86/PE32-${pe32Arch}.hex2"
    "${src}/x86/ntdll-${pe32Arch}.hex2"
    hex2_linker_hex2
  ];
  executable = false;
}
