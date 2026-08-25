{
  stage0-src,
  stage0-run,
  catm,
  cc_x86_0_hex2,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "cc_x86.hex2";
  builder = catm;
  args = [
    out
    "${src}/x86/PE32-${pe32Arch}.hex2"
    "${src}/x86/ntdll-${pe32Arch}.hex2"
    cc_x86_0_hex2
  ];
  executable = false;
}
