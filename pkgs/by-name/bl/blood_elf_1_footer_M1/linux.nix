{
  stage0-src,
  stage0-run,
  blood-elf-bootstrap,
  blood_elf_1_M1,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "blood-elf-1-footer.M1";
  builder = blood-elf-bootstrap;
  args = [
    "--little-endian"
    "-f"
    blood_elf_1_M1
    "-o"
    out
  ];
}
