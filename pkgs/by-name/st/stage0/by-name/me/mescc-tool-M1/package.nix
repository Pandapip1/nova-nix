{
  platform,
  stage0-src,
  stage0-run,
  M2,
}:
{
  name,
  sources,
}:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
  libcSources =
    if platform == "windows" then
      [
        "-D" "__windows__=1"
        "-f" "${src}/M2libc/sys/types.h"
        "-f" "${src}/M2libc/stddef.h"
        "-f" "${src}/M2libc/sys/utsname.h"
        "-f" "${src}/M2libc/x86/windows/ntdll.c"
        "-f" "${src}/M2libc/x86/windows/unistd.c"
        "-f" "${src}/M2libc/x86/windows/process.c"
        "-f" "${src}/M2libc/x86/windows/fcntl.c"
        "-f" "${src}/M2libc/fcntl.c"
        "-f" "${src}/M2libc/x86/windows/sys/stat.c"
        "-f" "${src}/M2libc/ctype.c"
        "-f" "${src}/M2libc/stdlib.c"
        "-f" "${src}/M2libc/string.c"
        "-f" "${src}/M2libc/stdarg.h"
        "-f" "${src}/M2libc/stdio.h"
        "-f" "${src}/M2libc/stdio.c"
        "-f" "${src}/M2libc/bootstrappable.c"
      ]
    else
      [
        "-f" "${src}/M2libc/sys/types.h"
        "-f" "${src}/M2libc/stddef.h"
        "-f" "${src}/M2libc/sys/utsname.h"
        "-f" "${src}/M2libc/${stage0Arch}/linux/fcntl.c"
        "-f" "${src}/M2libc/fcntl.c"
        "-f" "${src}/M2libc/${stage0Arch}/linux/unistd.c"
        "-f" "${src}/M2libc/${stage0Arch}/linux/sys/stat.c"
        "-f" "${src}/M2libc/ctype.c"
        "-f" "${src}/M2libc/stdlib.c"
        "-f" "${src}/M2libc/stdarg.h"
        "-f" "${src}/M2libc/stdio.h"
        "-f" "${src}/M2libc/stdio.c"
        "-f" "${src}/M2libc/string.c"
        "-f" "${src}/M2libc/bootstrappable.c"
      ];
in
stage0-run {
  pname = "${name}.M1";
  builder = M2;
  args =
    [ "--architecture" stage0Arch ]
    ++ libcSources
    ++ builtins.concatMap (source: [ "-f" "${src}/${source}" ]) sources
    ++ (if platform == "linux" then [ "--debug" ] else [ ])
    ++ [ "-o" out ];
  executable = false;
}
