{
  stage0-src,
  stage0-run,
  M0,
  hex2_linker_0_M1,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "hex2_linker.hex2";
  builder = M0;
  args = [
    hex2_linker_0_M1
    out
  ];
  executable = false;
}
