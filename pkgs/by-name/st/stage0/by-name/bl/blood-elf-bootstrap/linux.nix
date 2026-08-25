{
  stage0-src,
  stage0-run,
  blood_elf_0_0_hex2,
  hex2-bootstrap,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "blood-elf-0";
  builder = hex2-bootstrap;
  args = [
    blood_elf_0_0_hex2
    out
  ];
}
