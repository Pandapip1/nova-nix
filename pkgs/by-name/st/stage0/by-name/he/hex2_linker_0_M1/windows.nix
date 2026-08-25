{
  stage0-src,
  stage0-run,
  catm,
  hex2_linker_M1,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "hex2_linker-0.M1";
  builder = catm;
  args = [
    out
    "${src}/M2libc/x86/x86_defs.M1"
    "${src}/x86/libc-core.M1"
    "${src}/x86/libc-full.M1"
    hex2_linker_M1
    "${src}/x86/pe-end-shim.M1"
  ];
  executable = false;
}
