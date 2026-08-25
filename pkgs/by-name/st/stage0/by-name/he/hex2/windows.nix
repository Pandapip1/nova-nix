{
  stage0-src,
  stage0-run,
  hex2-0,
  hex2_linker_0_hex2,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "hex2-new";
  builder = hex2-0;
  args = [
    hex2_linker_0_hex2
    out
  ];
}
