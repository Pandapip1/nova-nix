{
  stage0-src,
  stage0-run,
  M1_macro_0_0_hex2,
  hex2-bootstrap,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M1-0";
  builder = hex2-bootstrap;
  args = [
    M1_macro_0_0_hex2
    out
  ];
}
