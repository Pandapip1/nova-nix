{
  stage0-src,
  stage0-run,
  M2_Mesoplanet_1_M1,
  blood-elf,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M2-Mesoplanet-1-footer.M1";
  builder = blood-elf;
  args = [
    "--little-endian"
    "-f"
    M2_Mesoplanet_1_M1
    "-o"
    out
  ];
}
