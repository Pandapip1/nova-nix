{
  stage0-run,
  stage0-src,
  hex1,
}:
let
  mkStage0 = stage0-run;
in
mkStage0 {
  pname = if stage0-src.executableSuffix == "" then "hex2-0" else "hex2";
  builder = hex1;
  args = [
    "${stage0-src.src}/x86/hex2_${stage0-src.stage0Arch}.hex1"
    (builtins.placeholder "out")
  ];
}
