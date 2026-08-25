{
  stage0-src,
  stage0-run,
  M2_0_0_hex2,
  hex2-bootstrap,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M2";
  builder = hex2-bootstrap;
  args = [
    M2_0_0_hex2
    out
  ];
}
