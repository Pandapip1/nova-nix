{
  platform,
  stage0-src,
  stage0-run,
  catm,
  blood-elf-bootstrap,
}:
name: M1src:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
if platform == "windows" then
  stage0-run {
    pname = "${name}-0.M1";
    builder = catm;
    args = [
      out
      "${src}/M2libc/${stage0Arch}/${stage0Arch}_defs.M1"
      "${src}/x86/libc-core.M1"
      "${src}/x86/libc-full.M1"
      M1src
      "${src}/x86/pe-end-shim.M1"
    ];
    executable = false;
  }
else
  stage0-run {
    pname = "${name}-footer.M1";
    builder = blood-elf-bootstrap;
    args = [ "--little-endian" "-f" M1src "-o" out ];
    executable = false;
  }
