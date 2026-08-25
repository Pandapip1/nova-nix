{
  stage0-run,
  stage0-src,
  hex0,
}:
let
  mkStage0 = stage0-run;
in
mkStage0 {
  pname = "hex1";
  builder = hex0;
  args = [
    "${stage0-src.src}/x86/hex1_${stage0-src.stage0Arch}.hex0"
    (builtins.placeholder "out")
  ];
}
