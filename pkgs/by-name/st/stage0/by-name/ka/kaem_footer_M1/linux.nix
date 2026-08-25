{
  stage0-src,
  stage0-run,
  blood-elf-bootstrap,
  kaem_M1,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "kaem-footer.M1";
  builder = blood-elf-bootstrap;
  args = [
    "-f"
    kaem_M1
    "--little-endian"
    "-o"
    out
  ];
}
