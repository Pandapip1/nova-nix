{
  stage0-src,
  stage0-run,
  M2,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "M2-Mesoplanet-1.M1";
  builder = M2;
  args = [
    "--architecture"
    "x86"
    "-f"
    "${src}/M2libc/sys/types.h"
    "-f"
    "${src}/M2libc/stddef.h"
    "-f"
    "${src}/M2libc/x86/linux/fcntl.c"
    "-f"
    "${src}/M2libc/fcntl.c"
    "-f"
    "${src}/M2libc/sys/utsname.h"
    "-f"
    "${src}/M2libc/x86/linux/unistd.c"
    "-f"
    "${src}/M2libc/x86/linux/sys/stat.c"
    "-f"
    "${src}/M2libc/ctype.c"
    "-f"
    "${src}/M2libc/stdlib.c"
    "-f"
    "${src}/M2libc/stdarg.h"
    "-f"
    "${src}/M2libc/stdio.h"
    "-f"
    "${src}/M2libc/stdio.c"
    "-f"
    "${src}/M2libc/string.c"
    "-f"
    "${src}/M2libc/bootstrappable.c"
    "-f"
    "${src}/M2-Mesoplanet/cc.h"
    "-f"
    "${src}/M2-Mesoplanet/cc_globals.c"
    "-f"
    "${src}/M2-Mesoplanet/cc_env.c"
    "-f"
    "${src}/M2-Mesoplanet/cc_reader.c"
    "-f"
    "${src}/M2-Mesoplanet/cc_spawn.c"
    "-f"
    "${src}/M2-Mesoplanet/cc_core.c"
    "-f"
    "${src}/M2-Mesoplanet/cc_macro.c"
    "-f"
    "${src}/M2-Mesoplanet/cc.c"
    "--debug"
    "-o"
    out
  ];
}
