{
  stage0-src,
  stage0-run,
  hex2-0,
  hex2_linker_0_0_hex2,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "hex2-1";
  builder = hex2-0;
  args = [
    hex2_linker_0_0_hex2
    out
  ];
}
