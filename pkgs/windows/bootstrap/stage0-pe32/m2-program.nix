# How a C program becomes a PE32 executable, once there is a C compiler.
#
# Everything in the chain below hex2-new is assembled by hand or compiled with
# --bootstrap-mode, and each link spells its own five steps out.  Above the
# chain the steps stop varying: a program is C, it stands on the whole of
# M2libc, and the way it is compiled, assembled and linked is the same every
# time.  So it is written once, here, and kaem.nix and mescc-tools-extra.nix
# each pass a list of sources.
#
# The five steps, which are x86/mescc-tools-mini.cmd's own for hex2-new:
#
#   M2      the program and the C library, to M1 assembly, in one pass
#   catm    that, between the assembly-level libc and the end-of-image label
#   M1      to hex2
#   catm    that, after the PE header and the ntdll resolver
#   hex2    to an executable
#
# --debug and blood-elf have no counterpart here.  They exist to give the
# output an ELF symbol table, and this output is not an ELF.
{
  derivationWithMeta,
  src,
  version,
  system,
  platforms,
  stage0Arch,
  pe32Arch,
  catm,
  M2,
  M1,
  hex2-new,
}:
let
  out = builtins.placeholder "out";

  meta = {
    description = "Collection of tools written for use in bootstrapping";
    homepage = "https://github.com/Pandapip1/stage0-pe32";
    license = "gpl3Plus";
    inherit platforms;
  };

  run =
    pname: builder: args:
    derivationWithMeta {
      inherit pname version system meta;
      builder = "${builder}";
      args = map (arg: "${arg}") args;
    };
in
{
  # The whole of M2libc, in the order M2-Planet has to read it: one pass, so a
  # definition has to come before whatever uses it.  The Windows target
  # supplies what a syscall would on Linux -- ntdll.c resolves each routine by
  # name out of ntdll's export table, and the four files after it are the
  # POSIX layer written against that.
  #
  # __windows__ is what tells a source that this is the system it is being
  # compiled for.  Only one file in mescc-tools reads it, and that file is
  # kaem; see kaem.nix.
  libcSources = [
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
    "${src}/M2libc/string.c"
    "-f"
    "${src}/M2libc/stdarg.h"
    "-f"
    "${src}/M2libc/stdio.h"
    "-f"
    "${src}/M2libc/stdio.c"
    "-f"
    "${src}/M2libc/bootstrappable.c"
  ];

  # program name sources -> a PE32 executable.
  #
  # `sources` is the argument list for M2 -- the libcSources above plus one
  # -f per file of the program itself.  The store path ends in .exe, which is
  # what makes it runnable by name on Windows.
  program =
    name: sources:
    let
      prog_M1 = run "${name}.M1" M2 (
        [
          "--architecture"
          stage0Arch
        ]
        ++ sources
        ++ [
          "-o"
          out
        ]
      );

      # libc-full.M1 rather than libc-bootstrap.M1: this program uses M2libc's
      # stdio, whose stdin, stdout and stderr are globals that __init_io fills
      # in.  Without it all three are NULL and the first error path faults
      # inside fputs instead of printing the error.
      #
      # pe-end-shim.M1 ends the image with :PE_end, which is the label the PE
      # header measures against; M2-Planet emits :ELF_end, for the header it
      # was written for.
      prog-0_M1 = run "${name}-0.M1" catm [
        out
        "${src}/M2libc/${stage0Arch}/${stage0Arch}_defs.M1"
        "${src}/x86/libc-core.M1"
        "${src}/x86/libc-full.M1"
        prog_M1
        "${src}/x86/pe-end-shim.M1"
      ];

      prog_hex2 = run "${name}.hex2" M1 [
        "--architecture"
        stage0Arch
        "--little-endian"
        "-f"
        prog-0_M1
        "-o"
        out
      ];

      prog-0_hex2 = run "${name}-0.hex2" catm [
        out
        "${src}/x86/PE32-${pe32Arch}.hex2"
        "${src}/x86/ntdll-${pe32Arch}.hex2"
        prog_hex2
      ];
    in
    derivationWithMeta {
      pname = name;
      name = "${name}-${version}.exe";
      inherit version system meta;
      builder = "${hex2-new}";
      args = [
        "--architecture"
        stage0Arch
        "--little-endian"
        "--base-address"
        "0x400000"
        "-f"
        "${prog-0_hex2}"
        "-o"
        out
      ];
    };
}
