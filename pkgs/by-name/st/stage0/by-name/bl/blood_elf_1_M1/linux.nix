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
  pname = "blood-elf-1.M1";
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
    "${src}/M2libc/bootstrappable.c"
    "-f"
    "${src}/mescc-tools/stringify.c"
    "-f"
    "${src}/mescc-tools/blood-elf.c"
    "--debug"
    "-o"
    out
  ];
}
