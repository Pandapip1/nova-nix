{
  stage0-src,
  stage0-run,
  blood_elf_0_hex2,
  catm,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "blood-elf-0-0.hex2";
  builder = catm;
  args = [
    out
    "${src}/M2libc/x86/ELF-x86.hex2"
    blood_elf_0_hex2
  ];
}
