{
  stage0-src,
  stage0-run,
  M0,
  M1_macro_0_0_M1,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M1-macro-0.hex2";
  builder = M0;
  args = [
    M1_macro_0_0_M1
    out
  ];
}
