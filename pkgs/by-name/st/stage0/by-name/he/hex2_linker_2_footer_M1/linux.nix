{
  stage0-src,
  stage0-run,
  blood-elf,
  hex2_linker_2_M1,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "hex2_linker-2-footer.M1";
  builder = blood-elf;
  args = [
    "-f"
    hex2_linker_2_M1
    "--little-endian"
    "-o"
    out
  ];
}
