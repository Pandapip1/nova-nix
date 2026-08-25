{
  stage0-src,
  stage0-run,
  cc_x86_1_hex2,
  hex2-0,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "cc_x86";
  builder = hex2-0;
  args = [
    cc_x86_1_hex2
    out
  ];
}
