{
  stage0-src,
  stage0-run,
  M1,
  blood_elf_1_M1,
  blood_elf_1_footer_M1,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "blood-elf-1.hex2";
  builder = M1;
  args = [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    blood_elf_1_M1
    "-f"
    blood_elf_1_footer_M1
    "-o"
    out
  ];
}
