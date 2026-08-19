# The chain above hex0, one derivation per link.
#
# This is a translation of stage0-pe32's x86/mescc-tools-mini.cmd into nix, the
# way nixpkgs' mescc-tools-boot.nix translates stage0-posix's
# mescc-tools-mini-kaem.kaem.  Upstream needs a shell to sequence the early
# chain -- cmd.exe there, kaem on POSIX -- because it has nothing else that can
# order one program's output into the next one's input.  Here each link is a
# derivation and nova-nix orders them, so that shell has no counterpart.
#
# Every program in the chain takes its destination as an argument rather than
# reading $out from the environment, so the output path is passed as
# builtins.placeholder "out" and the builder substitutes the real path before
# spawning.  Note that catm takes its destination *first* and its inputs after,
# while the assemblers take one input and then the destination.
#
# Warning: none of these binaries carry debug information, so a debugger will
# show addresses and not names.  The corresponding annotated sources in `src`
# are the way to read them.
{
  derivationWithMeta,
  src,
  version,
  system,
  platforms,
  stage0Arch,
  pe32Arch,
  hex0,
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
        description = "Collection of tools written for use in bootstrapping";
        homepage = "https://github.com/Pandapip1/stage0-pe32";
        license = "gpl3Plus";
        inherit platforms;
      };
    };

  # Same as `run`, but for a link that is itself a PE32 executable rather
  # than an intermediate hex2/M1/C artifact -- its store path gets the
  # `.exe` suffix Windows requires to run it directly, matching the names
  # upstream's own mescc-tools-mini.cmd gives them (hex1.exe, M2.exe, ...).
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
        description = "Collection of tools written for use in bootstrapping";
        homepage = "https://github.com/Pandapip1/stage0-pe32";
        license = "gpl3Plus";
        inherit platforms;
      };
    };

  ################################
  # Phase-1 Build hex1 from hex0 #
  ################################

  hex1 = runExe "hex1" hex0 [
    "${src}/x86/hex1_${stage0Arch}.hex0"
    out
  ];

  # hex1 adds single-character labels and relative pointers, which is enough to
  # write something that is not a straight transcription of machine code.

  ################################
  # Phase-2 Build hex2 from hex1 #
  ################################

  hex2 = runExe "hex2" hex1 [
    "${src}/x86/hex2_${stage0Arch}.hex1"
    out
  ];

  # hex2 adds long labels, absolute addresses and five pointer widths, which
  # makes it an effective linker for every later stage.

  ###############################
  # Phase-3 Build catm from hex2 #
  ###############################

  catm = runExe "catm" hex2 [
    "${src}/x86/catm_${stage0Arch}.hex2"
    out
  ];

  # catm removes the need for a shell's redirection by providing the equivalent
  # as catm output_file input1 input2 ... inputN.  Everything below this line
  # is assembled from several files at once, which is why it comes first.

  ##############################
  # Phase-4 Build M0 from hex2 #
  ##############################

  # PE32-i386.hex2 is the header stub: a PE32 header whose sizes are written as
  # hex2 expressions over the program that follows it, so a program only has to
  # define _start and end with :PE_end.  ntdll-i386.hex2 is the Windows
  # plumbing every program in the chain needs -- finding ntdll through the PEB,
  # resolving exports by name, opening argv[1] and argv[2], one-byte reads and
  # writes.  Neither is a program, so both are concatenated onto one.
  M0_hex2 = run "M0.hex2" catm [
    out
    "${src}/x86/PE32-${pe32Arch}.hex2"
    "${src}/x86/ntdll-${pe32Arch}.hex2"
    "${src}/x86/M0_${stage0Arch}.hex2"
  ];

  M0 = runExe "M0" hex2 [
    M0_hex2
    out
  ];

  # M0 is the architecture-specific version of M1: macros, strings and
  # width-prefixed immediates.  It is single-architecture by design and will be
  # replaced by the C version of M1 once there is a C compiler to build it.

  #################################
  # Phase-5 Build cc_x86 from M0 #
  #################################

  # cc_x86 compiles the subset of C that M2-Planet is written in, and is the
  # last link in the chain written by hand -- everything above it is compiled.
  # It needs the header and the shared plumbing concatenated onto it exactly
  # as M0 did, since it is M0 that assembles it and M0 knows nothing of PE32
  # or ntdll on its own.
  cc_x86-0_hex2 = run "cc_x86-0.hex2" M0 [
    "${src}/x86/cc_${stage0Arch}.M1"
    out
  ];

  cc_x86_hex2 = run "cc_x86.hex2" catm [
    out
    "${src}/x86/PE32-${pe32Arch}.hex2"
    "${src}/x86/ntdll-${pe32Arch}.hex2"
    cc_x86-0_hex2
  ];

  cc_x86 = runExe "cc_x86" hex2 [
    cc_x86_hex2
    out
  ];

  ##############################
  # Phase-6 Build M2 from cc_x86 #
  ##############################

  # M2-Planet is a C compiler with more of the language than cc_x86 has, and
  # the first C the chain compiles rather than hand-assembles.  M2-Planet and
  # M2libc's bootstrappable.c are upstream's, unmodified; the fork's
  # x86/windows/bootstrap.c is stage0-pe32's own port of linux/bootstrap.c --
  # argc/argv from the PEB, fgetc/fputc/open/close through ntdll-i386.hex2,
  # and malloc as a bump allocator over the same zero-filled memory M0 and
  # cc_x86 already use.  x86_defs.M1 and libc-core.M1 are what that C compiles
  # against once cc_x86 has turned it into M1.
  M2-0_c = run "M2-0.c" catm [
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

  M2-0_M1 = run "M2-0.M1" cc_x86 [
    M2-0_c
    out
  ];

  # libc-core.M1 is the plumbing every link shares; the file after it picks
  # which C library the program gets.  _start calls :__libc_init and catm
  # decides what that name means -- libc-bootstrap.M1 defines it as a no-op,
  # libc-full.M1 as __init_malloc plus __init_io.  Upstream carries the same
  # split in libc-full.M1's own _start, but ours is far longer than upstream's
  # nine lines and cannot be duplicated per mode.
  M2-0-0_M1 = run "M2-0-0.M1" catm [
    out
    "${src}/M2libc/x86/x86_defs.M1"
    "${src}/x86/libc-core.M1"
    "${src}/x86/libc-bootstrap.M1"
    M2-0_M1
  ];

  M2-0_hex2 = run "M2-0.hex2" M0 [
    M2-0-0_M1
    out
  ];

  M2-0-0_hex2 = run "M2-0-0.hex2" catm [
    out
    "${src}/x86/PE32-${pe32Arch}.hex2"
    "${src}/x86/ntdll-${pe32Arch}.hex2"
    M2-0_hex2
  ];

  M2 = runExe "M2" hex2 [
    M2-0-0_hex2
    out
  ];

  ###############################
  # Phase-7 Build M1 from M2 #
  ###############################

  # M1-macro is a fuller assembler than M0: more label and pointer widths, and
  # several architectures in one binary.  It is compiled by M2 like any other
  # program rather than hand-assembled.  Upstream's POSIX chain runs this
  # stage's output through blood-elf first, to add an ELF symbol table purely
  # so objdump and gdb can read it; there is no PE equivalent worth building
  # and nothing here needs one, so that step is skipped and PE32-i386.hex2
  # stands in unchanged.
  #
  # M2's own C is upstream's, unmodified, so it always ends its output with
  # :ELF_end -- the label its ELF header expects -- while PE32-i386.hex2
  # expects :PE_end.  pe-end-shim.M1 defines :PE_end at that same address, so
  # the vendored source needs no patch.
  M1-macro_M1 = run "M1-macro.M1" M2 [
    "--architecture"
    stage0Arch
    "--bootstrap-mode"
    "-f"
    "${src}/M2libc/x86/windows/bootstrap.c"
    "-f"
    "${src}/M2libc/bootstrappable.c"
    "-f"
    "${src}/mescc-tools/stringify.c"
    "-f"
    "${src}/mescc-tools/M1-macro.c"
    "-o"
    out
  ];

  M1-macro-0_M1 = run "M1-macro-0.M1" catm [
    out
    "${src}/M2libc/x86/x86_defs.M1"
    "${src}/x86/libc-core.M1"
    "${src}/x86/libc-bootstrap.M1"
    M1-macro_M1
    "${src}/x86/pe-end-shim.M1"
  ];

  M1-macro_hex2 = run "M1-macro.hex2" M0 [
    M1-macro-0_M1
    out
  ];

  M1-macro-0_hex2 = run "M1-macro-0.hex2" catm [
    out
    "${src}/x86/PE32-${pe32Arch}.hex2"
    "${src}/x86/ntdll-${pe32Arch}.hex2"
    M1-macro_hex2
  ];

  M1 = runExe "M1" hex2 [
    M1-macro-0_hex2
    out
  ];

  ####################################
  # Phase-8 Build hex2-new from M2 #
  ####################################

  # hex2 from C.  The hand-written hex2 built everything up to here; this one
  # replaces it, and unlike that one it is not limited to a fixed label table.
  #
  # It needs a real preprocessor -- hex2.h spells `#define max_string 4096`
  # where M1-macro.c used an enum -- so this stage drops --bootstrap-mode.
  # That in turn means the full M2libc rather than x86/windows/bootstrap.c:
  # stdio.c's FILE and its buffering, standing on the POSIX layer in
  # x86/windows's unistd.c, process.c, fcntl.c and sys/stat.c.  All of it now
  # lives in the M2libc fork rather than in stage0-pe32's own tree.
  #
  # That layer is C rather than assembly because of ntdll.c, which resolves a
  # routine by NAME (__ntdll_resolve) so compiled C can call one without a
  # hand-written M1 stub per routine.  Resolving by name is what retires
  # ntdll-slots.h here: the fixed NT_* slots ntdll-i386.hex2 still fills are
  # read by name only by the hand-assembled stages below it.
  hex2_linker_M1 = run "hex2_linker.M1" M2 [
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

  # libc-full.M1 rather than libc-bootstrap.M1: this is the first link whose C
  # actually uses M2libc's stdio, and its stdin/stdout/stderr are globals that
  # __init_io fills in.  Without it all three are NULL and every error path
  # faults inside fputs instead of printing the error.
  hex2_linker-0_M1 = run "hex2_linker-0.M1" catm [
    out
    "${src}/M2libc/x86/x86_defs.M1"
    "${src}/x86/libc-core.M1"
    "${src}/x86/libc-full.M1"
    hex2_linker_M1
    "${src}/x86/pe-end-shim.M1"
  ];

  hex2_linker_hex2 = run "hex2_linker.hex2" M0 [
    hex2_linker-0_M1
    out
  ];

  hex2_linker-0_hex2 = run "hex2_linker-0.hex2" catm [
    out
    "${src}/x86/PE32-${pe32Arch}.hex2"
    "${src}/x86/ntdll-${pe32Arch}.hex2"
    hex2_linker_hex2
  ];

  hex2-new = runExe "hex2-new" hex2 [
    hex2_linker-0_hex2
    out
  ];
}
