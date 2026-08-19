# GNU Mes as a PE32 executable, built by the stage0-pe32 chain.
#
# This is a translation of Mes's own kaem.windows.run, the way
# mescc-tools-boot.nix translates stage0-pe32's mescc-tools-mini.cmd.  Three
# tools, three derivations: M2-Planet compiles Mes's C to M1, M1 assembles
# that to hex2, and hex2 links it against the PE header and the ntdll
# plumbing.  All three are the ones this bootstrap just built -- the C
# compiler, assembler and linker that stage0-pe32 ends with -- so nothing
# outside the chain touches the result.
#
# What differs from Mes's GNU/Linux kaem.run, and why, is written down at the
# top of kaem.windows.run itself; the short version is that lib/windows/
# replaces lib/linux/ because Windows has no syscall a program may make
# directly, the PE header and ntdll plumbing replace the ELF header, --debug
# and blood-elf are dropped (M2-Planet then writes :ELF_end itself, and
# nothing functional is lost), and the base address is the ImageBase the PE
# header declares.
#
# Unlike the stage0 chain, these tools take their inputs as -f flags and
# their destination as -o rather than positionally, so the argument lists
# below are flag-interleaved.  The order of the sources is significant: M2-
# Planet has no linker and emits definitions in the order it reads them.
{
  derivationWithMeta,
  src,
  version,
  system,
  platforms,
  M2,
  M1,
  hex2-new,
}:
rec {
  out = builtins.placeholder "out";

  run =
    pname: builder: args:
    derivationWithMeta {
      inherit
        pname
        version
        system
        ;
      builder = "${builder}";
      args = map (arg: "${arg}") args;

      meta = {
        description = "Scheme interpreter and C compiler for bootstrapping";
        homepage = "https://www.gnu.org/software/mes/";
        license = "gpl3Plus";
        inherit platforms;
      };
    };

  # Same as `run`, but names the output with the `.exe` Windows needs to run
  # it directly -- as the stage0 chain does for its own executables.
  runExe =
    pname: builder: args:
    derivationWithMeta {
      inherit
        pname
        version
        system
        ;
      name = "${pname}-${version}.exe";
      builder = "${builder}";
      args = map (arg: "${arg}") args;

      meta = {
        description = "Scheme interpreter and C compiler for bootstrapping";
        homepage = "https://www.gnu.org/software/mes/";
        license = "gpl3Plus";
        inherit platforms;
      };
    };

  # configure.sh writes this file and nothing else that this build reads, so
  # it is written here rather than run: for a non-system libc it is exactly
  # these two lines.  Keeping it in the store also keeps the shell out of a
  # bootstrap whose whole point is not to need one.
  configH = builtins.toFile "config.h" ''
    #undef SYSTEM_LIBC
    #define MES_VERSION "0.27.1"
  '';

  # Phase-1: Mes's C to M1.  __windows__ selects lib/windows/ over lib/linux/
  # inside the sources themselves; __i386__ is the word size.
  mes_M1 = run "mes.M1" M2 [
    "--architecture"
    "x86"
    "-D"
    "__i386__=1"
    "-D"
    "__windows__=1"
    "-f"
    configH
    "-f"
    "${src}/include/mes/lib-mini.h"
    "-f"
    "${src}/include/mes/lib.h"
    "-f"
    "${src}/include/windows/x86-mes-m2/ntdll.h"
    "-f"
    "${src}/lib/windows/x86-mes-m2/crt1.c"
    "-f"
    "${src}/lib/windows/x86-mes-m2/iosb.c"
    "-f"
    "${src}/lib/mes/__init_io.c"
    "-f"
    "${src}/lib/windows/x86-mes-m2/_exit.c"
    "-f"
    "${src}/lib/windows/x86-mes-m2/_write.c"
    "-f"
    "${src}/lib/mes/globals.c"
    "-f"
    "${src}/lib/m2/cast.c"
    "-f"
    "${src}/lib/stdlib/exit.c"
    "-f"
    "${src}/lib/mes/write.c"
    "-f"
    "${src}/lib/windows/x86-mes-m2/errno.c"
    "-f"
    "${src}/lib/stub/__raise.c"
    "-f"
    "${src}/lib/windows/brk.c"
    "-f"
    "${src}/lib/linux/malloc.c"
    "-f"
    "${src}/lib/windows/x86-mes-m2/ntdll.c"
    "-f"
    "${src}/lib/string/memset.c"
    "-f"
    "${src}/lib/windows/read.c"
    "-f"
    "${src}/lib/mes/fdgetc.c"
    "-f"
    "${src}/lib/stdio/getchar.c"
    "-f"
    "${src}/lib/stdio/putchar.c"
    "-f"
    "${src}/lib/stub/__buffered_read.c"
    "-f"
    "${src}/include/errno.h"
    "-f"
    "${src}/include/fcntl.h"
    "-f"
    "${src}/lib/windows/_open3.c"
    "-f"
    "${src}/lib/windows/open.c"
    "-f"
    "${src}/lib/mes/mes_open.c"
    "-f"
    "${src}/lib/string/strlen.c"
    "-f"
    "${src}/lib/mes/eputs.c"
    "-f"
    "${src}/lib/mes/fdputc.c"
    "-f"
    "${src}/lib/mes/eputc.c"
    "-f"
    "${src}/include/time.h"
    "-f"
    "${src}/include/sys/time.h"
    "-f"
    "${src}/include/m2/types.h"
    "-f"
    "${src}/include/sys/types.h"
    "-f"
    "${src}/include/sys/utsname.h"
    "-f"
    "${src}/include/mes/mes.h"
    "-f"
    "${src}/include/mes/builtins.h"
    "-f"
    "${src}/include/mes/constants.h"
    "-f"
    "${src}/include/mes/symbols.h"
    "-f"
    "${src}/lib/mes/__assert_fail.c"
    "-f"
    "${src}/lib/mes/assert_msg.c"
    "-f"
    "${src}/lib/mes/fdputc.c"
    "-f"
    "${src}/lib/string/strncmp.c"
    "-f"
    "${src}/lib/posix/getenv.c"
    "-f"
    "${src}/lib/mes/fdputs.c"
    "-f"
    "${src}/lib/mes/ntoab.c"
    "-f"
    "${src}/lib/ctype/isdigit.c"
    "-f"
    "${src}/lib/ctype/isxdigit.c"
    "-f"
    "${src}/lib/ctype/isspace.c"
    "-f"
    "${src}/lib/ctype/isnumber.c"
    "-f"
    "${src}/lib/mes/abtol.c"
    "-f"
    "${src}/lib/stdlib/atoi.c"
    "-f"
    "${src}/lib/string/memcpy.c"
    "-f"
    "${src}/lib/stdlib/free.c"
    "-f"
    "${src}/lib/stdlib/realloc.c"
    "-f"
    "${src}/lib/string/strcpy.c"
    "-f"
    "${src}/lib/mes/itoa.c"
    "-f"
    "${src}/lib/mes/ltoa.c"
    "-f"
    "${src}/lib/mes/fdungetc.c"
    "-f"
    "${src}/lib/posix/setenv.c"
    "-f"
    "${src}/lib/windows/access.c"
    "-f"
    "${src}/include/linux/m2/kernel-stat.h"
    "-f"
    "${src}/include/sys/stat.h"
    "-f"
    "${src}/lib/windows/chmod.c"
    "-f"
    "${src}/lib/windows/ioctl3.c"
    "-f"
    "${src}/include/sys/ioctl.h"
    "-f"
    "${src}/lib/m2/isatty.c"
    "-f"
    "${src}/include/signal.h"
    "-f"
    "${src}/lib/windows/x86-mes-m2/wow64gate.c"
    "-f"
    "${src}/lib/windows/x86-mes-m2/wow64resolve.c"
    "-f"
    "${src}/lib/windows/fork.c"
    "-f"
    "${src}/include/sys/resource.h"
    "-f"
    "${src}/lib/windows/waitpid.c"
    "-f"
    "${src}/lib/windows/wait4.c"
    "-f"
    "${src}/lib/windows/execve.c"
    "-f"
    "${src}/lib/m2/execv.c"
    "-f"
    "${src}/lib/windows/gettimeofday.c"
    "-f"
    "${src}/lib/windows/clock_gettime.c"
    "-f"
    "${src}/lib/windows/time.c"
    "-f"
    "${src}/lib/windows/_getcwd.c"
    "-f"
    "${src}/include/limits.h"
    "-f"
    "${src}/lib/m2/getcwd.c"
    "-f"
    "${src}/lib/windows/dup.c"
    "-f"
    "${src}/lib/windows/dup2.c"
    "-f"
    "${src}/lib/string/strcmp.c"
    "-f"
    "${src}/lib/string/memcmp.c"
    "-f"
    "${src}/lib/windows/uname.c"
    "-f"
    "${src}/lib/windows/unlink.c"
    "-f"
    "${src}/src/builtins.c"
    "-f"
    "${src}/src/core.c"
    "-f"
    "${src}/src/display.c"
    "-f"
    "${src}/src/eval-apply.c"
    "-f"
    "${src}/src/gc.c"
    "-f"
    "${src}/src/hash.c"
    "-f"
    "${src}/src/lib.c"
    "-f"
    "${src}/src/m2.c"
    "-f"
    "${src}/src/math.c"
    "-f"
    "${src}/src/mes.c"
    "-f"
    "${src}/src/module.c"
    "-f"
    "${src}/src/posix.c"
    "-f"
    "${src}/src/reader.c"
    "-f"
    "${src}/src/stack.c"
    "-f"
    "${src}/src/string.c"
    "-f"
    "${src}/src/struct.c"
    "-f"
    "${src}/src/symbol.c"
    "-f"
    "${src}/src/variable.c"
    "-f"
    "${src}/src/vector.c"
    "-o"
    out
  ];

  # Phase-2: M1 to hex2.  crt1.M1 is where Linux's nine instructions become a
  # hundred: Windows hands a program one UTF-16 command line and nothing else,
  # so argc, argv and the environment are all built there.  pe-end.M1 closes
  # the image the way the PE header expects.
  mes_hex2 = run "mes.hex2" M1 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/lib/m2/x86/x86_defs.M1"
    "-f"
    "${src}/lib/x86-mes/x86.M1"
    "-f"
    "${src}/lib/windows/x86-mes-m2/crt1.M1"
    "-f"
    mes_M1
    "-f"
    "${src}/lib/windows/x86-mes-m2/pe-end.M1"
    "-o"
    out
  ];

  # Phase-3: link.  --base-address is the ImageBase PE32-i386.hex2 declares,
  # and hex2 here is the C one -- the hand-written hex2 takes its arguments
  # positionally and has no --base-address.
  mes-m2 = runExe "mes-m2" hex2-new [
    "--architecture"
    "x86"
    "--little-endian"
    "--base-address"
    "0x400000"
    "-f"
    "${src}/lib/m2/x86/PE32-i386.hex2"
    "-f"
    "${src}/lib/m2/x86/ntdll-i386.hex2"
    "-f"
    mes_hex2
    "-o"
    out
  ];
}
