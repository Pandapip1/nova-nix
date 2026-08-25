{
  stage0-src,
  stage0-run,
  M2_0_M1,
  catm,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M2-0-0.M1";
  builder = catm;
  args = [
    out
    "${src}/M2libc/x86/x86_defs.M1"
    "${src}/x86/libc-core.M1"
    "${src}/x86/libc-mes.M1"
    M2_0_M1
  ];
  executable = false;
}
