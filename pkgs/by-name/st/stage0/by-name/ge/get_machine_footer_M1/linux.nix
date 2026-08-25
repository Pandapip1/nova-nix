{
  stage0-src,
  stage0-run,
  blood_elf,
  get_machine_M1,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "get_machine-footer.M1";
  builder = blood_elf;
  args = [
    "--little-endian"
    "-f"
    get_machine_M1
    "-o"
    out
  ];
}
