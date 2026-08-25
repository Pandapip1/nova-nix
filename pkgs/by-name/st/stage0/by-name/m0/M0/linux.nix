{
  stage0-src,
  stage0-run,
  M0_hex2,
  hex2-bootstrap,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M0";
  builder = hex2-bootstrap;
  args = [
    M0_hex2
    out
  ];
}
