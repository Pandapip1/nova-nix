{
  stage0-src,
  stage0-run,
  M1_macro_0_M1,
  blood-elf-bootstrap,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M1-macro-0-footer.M1";
  builder = blood-elf-bootstrap;
  args = [
    "-f"
    M1_macro_0_M1
    "--little-endian"
    "-o"
    out
  ];
}
