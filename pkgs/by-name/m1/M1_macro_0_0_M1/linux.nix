{
  stage0-src,
  stage0-run,
  M1_macro_0_M1,
  M1_macro_0_footer_M1,
  catm,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M1-macro-0-0.M1";
  builder = catm;
  args = [
    out
    "${src}/M2libc/x86/x86_defs.M1"
    "${src}/M2libc/x86/libc-core.M1"
    M1_macro_0_M1
    M1_macro_0_footer_M1
  ];
}
