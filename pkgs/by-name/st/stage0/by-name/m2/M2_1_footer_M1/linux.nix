{
  stage0-src,
  stage0-run,
  M2_1_M1,
  blood_elf,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M2-1-footer.M1";
  builder = blood_elf;
  args = [
    "--little-endian"
    "-f"
    M2_1_M1
    "-o"
    out
  ];
}
