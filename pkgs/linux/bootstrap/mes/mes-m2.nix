# GNU Mes as an ELF executable, built by the stage0-posix chain.
#
# A translation of Mes's own kaem.run -- the script that builds mes-m2, the
# Mes interpreter compiled by M2-Planet rather than by a C compiler that came
# from somewhere else.  The Windows set's mes-m2.nix is the same translation
# of kaem.windows.run, and the two are worth reading side by side.
#
# Four phases: M2-Planet compiles the whole interpreter as one translation
# unit (there is no separate compilation here -- every source is on one
# command line), blood-elf makes the symbol table that lets a debugger read
# the result, M1 assembles, and hex2 links.
#
# config.h is normally written by ./configure.  Nothing here runs configure,
# so the two definitions Mes needs are written straight to the store: this is
# the M2 build, so SYSTEM_LIBC is undefined -- Mes's own C library is what it
# stands on.
{
  derivationWithMeta,
  src,
  version,
  system,
  platforms,
  M2,
  M1,
  hex2,
  blood-elf,
}:
rec {
  out = builtins.placeholder "out";

  configH = builtins.toFile "config.h" ''
    #undef SYSTEM_LIBC
    #define MES_VERSION "0.27.1"
  '';

  run =
    pname: builder: args:
    derivationWithMeta {
      inherit pname version system;
      builder = "${builder}";
      args = map (arg: "${arg}") args;

      meta = {
        description = "Scheme interpreter and C compiler for bootstrapping";
        homepage = "https://www.gnu.org/software/mes/";
        license = "gpl3Plus";
        inherit platforms;
      };
    };

  # Phase-1: compile.  Every source of the interpreter, in upstream's order;
  # include/mes/config.h is the generated one above.
  mes_M1 = run "mes.M1" M2 [
    "--debug"
    "--architecture"
    "x86"
    "-D"
    "__i386__=1"
    "-D"
    "__linux__=1"
    "-f"
    configH
    "-f"
    "${src}/include/mes/lib-mini.h"
    "-f"
    "${src}/include/mes/lib.h"
    "-f"
    "${src}/lib/linux/x86-mes-m2/crt1.c"
    "-f"
    "${src}/lib/mes/__init_io.c"
    "-f"
    "${src}/lib/linux/x86-mes-m2/_exit.c"
    "-f"
    "${src}/lib/linux/x86-mes-m2/_write.c"
    "-f"
    "${src}/lib/mes/globals.c"
    "-f"
    "${src}/lib/m2/cast.c"
    "-f"
    "${src}/lib/stdlib/exit.c"
    "-f"
    "${src}/lib/mes/write.c"
    "-f"
    "${src}/include/linux/x86/syscall.h"
    "-f"
    "${src}/lib/linux/x86-mes-m2/syscall.c"
    "-f"
    "${src}/lib/stub/__raise.c"
    "-f"
    "${src}/lib/linux/brk.c"
    "-f"
    "${src}/lib/linux/malloc.c"
    "-f"
    "${src}/lib/string/memset.c"
    "-f"
    "${src}/lib/linux/read.c"
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
    "${src}/lib/linux/_open3.c"
    "-f"
    "${src}/lib/linux/open.c"
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
    "${src}/lib/linux/access.c"
    "-f"
    "${src}/include/linux/m2/kernel-stat.h"
    "-f"
    "${src}/include/sys/stat.h"
    "-f"
    "${src}/lib/linux/chmod.c"
    "-f"
    "${src}/lib/linux/ioctl3.c"
    "-f"
    "${src}/include/sys/ioctl.h"
    "-f"
    "${src}/lib/m2/isatty.c"
    "-f"
    "${src}/include/signal.h"
    "-f"
    "${src}/lib/linux/fork.c"
    "-f"
    "${src}/lib/m2/execve.c"
    "-f"
    "${src}/lib/m2/execv.c"
    "-f"
    "${src}/include/sys/resource.h"
    "-f"
    "${src}/lib/linux/wait4.c"
    "-f"
    "${src}/lib/linux/waitpid.c"
    # After fork.c, execve.c and waitpid.c, which are what it is made of:
    # M2-Planet is one-pass and a definition has to come before whatever uses
    # it.  system* only reaches for spawn where there is no fork, so here this
    # is compiled and never called; src/posix.c names it either way.
    "-f"
    "${src}/lib/posix/spawn.c"
    "-f"
    "${src}/lib/linux/gettimeofday.c"
    "-f"
    "${src}/lib/linux/clock_gettime.c"
    "-f"
    "${src}/lib/m2/time.c"
    "-f"
    "${src}/lib/linux/_getcwd.c"
    "-f"
    "${src}/include/limits.h"
    "-f"
    "${src}/lib/m2/getcwd.c"
    "-f"
    "${src}/lib/linux/dup.c"
    "-f"
    "${src}/lib/linux/dup2.c"
    "-f"
    "${src}/lib/string/strcmp.c"
    "-f"
    "${src}/lib/string/memcmp.c"
    "-f"
    "${src}/lib/linux/uname.c"
    "-f"
    "${src}/lib/linux/unlink.c"
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

  # Phase-2: the symbol table, so the linked result is readable by a debugger.
  #
  # kaem.run passes --little-endian twice here: once as $blood_elf_flag, whose
  # default is that same string, and once outright.  Saying it once means the
  # same thing to blood-elf.
  mes_blood_elf_M1 = run "mes.blood-elf-M1" blood-elf [
    "--little-endian"
    "-f"
    mes_M1
    "-o"
    out
  ];

  # Phase-3: assemble, with the architecture's macros and the crt1 that hands
  # main its argc and argv.
  mes_hex2 = run "mes.hex2" M1 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/lib/m2/x86/x86_defs.M1"
    "-f"
    "${src}/lib/x86-mes/x86.M1"
    "-f"
    "${src}/lib/linux/x86-mes-m2/crt1.M1"
    "-f"
    mes_M1
    "-f"
    mes_blood_elf_M1
    "-o"
    out
  ];

  # Phase-4: link.  --base-address is where the ELF header says the image
  # begins.
  mes-m2 = run "mes-m2" hex2 [
    "--architecture"
    "x86"
    "--little-endian"
    "--base-address"
    "0x1000000"
    "-f"
    "${src}/lib/m2/x86/ELF-x86.hex2"
    "-f"
    mes_hex2
    "-o"
    out
  ];

}
