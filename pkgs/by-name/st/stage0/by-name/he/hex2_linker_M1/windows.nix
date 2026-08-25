{
  stage0-src,
  stage0-run,
  M2,
}:
let
  inherit (stage0-src) src stage0Arch;
  inherit (stage0-src) pe32Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "hex2_linker.M1";
  builder = M2;
  args = [
    "--architecture"
    stage0Arch
    "-D"
    "__windows__=1"
    "-f"
    "${src}/M2libc/sys/types.h"
    "-f"
    "${src}/M2libc/stddef.h"
    "-f"
    "${src}/M2libc/sys/utsname.h"
    "-f"
    "${src}/M2libc/x86/windows/ntdll.c"
    "-f"
    "${src}/M2libc/x86/windows/unistd.c"
    "-f"
    "${src}/M2libc/x86/windows/process.c"
    "-f"
    "${src}/M2libc/x86/windows/fcntl.c"
    "-f"
    "${src}/M2libc/fcntl.c"
    "-f"
    "${src}/M2libc/x86/windows/sys/stat.c"
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
    "${src}/mescc-tools/hex2.h"
    "-f"
    "${src}/mescc-tools/hex2_linker.c"
    "-f"
    "${src}/mescc-tools/hex2_word.c"
    "-f"
    "${src}/mescc-tools/hex2.c"
    "-o"
    out
  ];
  executable = false;
}
