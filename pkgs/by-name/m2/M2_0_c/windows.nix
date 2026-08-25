{
  stage0-src,
  stage0-run,
  catm,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M2-0.c";
  builder = catm;
  args = [
    out
    "${src}/M2libc/x86/windows/bootstrap.c"
    "${src}/M2-Planet/cc.h"
    "${src}/M2libc/bootstrappable.c"
    "${src}/M2-Planet/cc_globals.c"
    "${src}/M2-Planet/cc_reader.c"
    "${src}/M2-Planet/cc_strings.c"
    "${src}/M2-Planet/cc_types.c"
    "${src}/M2-Planet/cc_emit.c"
    "${src}/M2-Planet/cc_core.c"
    "${src}/M2-Planet/cc_macro.c"
    "${src}/M2-Planet/cc.c"
  ];
  executable = false;
}
