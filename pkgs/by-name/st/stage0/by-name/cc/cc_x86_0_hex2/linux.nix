{
  stage0-src,
  stage0-run,
  M0,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "cc_x86-0.hex2";
  builder = M0;
  args = [
    "${src}/x86/cc_x86.M1"
    out
  ];
}
