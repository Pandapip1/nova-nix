{
  stage0-src,
  stage0-run,
  M2_0_hex2,
  catm,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M2-0-0.hex2";
  builder = catm;
  args = [
    out
    "${src}/x86/PE32-${pe32Arch}.hex2"
    "${src}/x86/ntdll-${pe32Arch}.hex2"
    M2_0_hex2
  ];
  executable = false;
}
