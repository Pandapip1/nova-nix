{
  stage0-run,
  stage0-src,
  hex2-bootstrap,
}:
let
  mkStage0 = stage0-run;
in
mkStage0 {
  pname = "catm";
  builder = hex2-bootstrap;
  args = [
    "${stage0-src.src}/x86/catm_${stage0-src.stage0Arch}.hex2"
    (builtins.placeholder "out")
  ];
}
