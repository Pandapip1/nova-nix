{
  stage0-src,
  stage0-run,
  M1_macro_1_M1,
  blood-elf,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M1-macro-1-footer.M1";
  builder = blood-elf;
  args = [
    "-f"
    M1_macro_1_M1
    "--little-endian"
    "-o"
    out
  ];
}
