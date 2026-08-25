{
  stage0-src,
  stage0-run,
  M2_0_c,
  cc-x86,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M2-0.M1";
  builder = cc-x86;
  args = [
    M2_0_c
    out
  ];
  executable = false;
}
