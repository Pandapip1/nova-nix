# The chain above hex0, one derivation per link.
#
# A translation of stage0-posix's x86/mescc-tools-mini-kaem.kaem and
# x86/mescc-tools-full-kaem.kaem into nix, the
# way nixpkgs' mescc-tools-boot.nix translates the same file, and the way
# ../../../windows/bootstrap/stage0-pe32/mescc-tools-boot.nix translates the
# Windows fork's cmd script.  Upstream needs kaem to sequence these because it
# has nothing else that can order one program's output into the next one's
# input; here each link is a derivation and nova-nix orders them, so kaem has
# no counterpart -- except as a program: the last phases build kaem itself,
# because everything ABOVE this bootstrap is written against it as a shell.
#
# Every program takes its destination as an argument rather than reading $out,
# so the output path is passed as builtins.placeholder "out" and the builder
# substitutes the real path before spawning.  catm takes its destination
# FIRST and its inputs after; the assemblers take input then destination; M1,
# hex2 and M2 take -o.
#
# The generated part of this file is the argument lists, which are upstream's
# own, in upstream's order.
{
  derivationWithMeta,
  src,
  version,
  system,
  platforms,
  hex0,
}:
rec {
  out = builtins.placeholder "out";

  run =
    pname: builder: args:
    derivationWithMeta {
      inherit pname version system;
      builder = "${builder}";
      args = map (arg: "${arg}") args;

      meta = {
        description = "Collection of tools written for use in bootstrapping";
        homepage = "https://github.com/oriansj/stage0-posix";
        license = "gpl3Plus";
        inherit platforms;
      };
    };

  ############################
  # Phase-1  hex1, from hex0 #
  ############################

  hex1 = run "hex1" hex0 [
    "${src}/x86/hex1_x86.hex0"
    out
  ];

  ############################
  # Phase-2  hex2, from hex1 #
  ############################

  hex2_0 = run "hex2-0" hex1 [
    "${src}/x86/hex2_x86.hex1"
    out
  ];

  #####################################################################
  # Phase-3  catm, so a file can be built from pieces without a shell #
  #####################################################################

  catm = run "catm" hex2_0 [
    "${src}/x86/catm_x86.hex2"
    out
  ];

  ##################################
  # Phase-4  M0, a macro assembler #
  ##################################

  M0_hex2 = run "M0.hex2" catm [
    out
    "${src}/x86/ELF-i386.hex2"
    "${src}/x86/M0_x86.hex2"
  ];

  M0 = run "M0" hex2_0 [
    M0_hex2
    out
  ];

  #########################################################
  # Phase-5  cc_x86, the first thing here that compiles C #
  #########################################################

  cc_x86_0_hex2 = run "cc_x86-0.hex2" M0 [
    "${src}/x86/cc_x86.M1"
    out
  ];

  cc_x86_1_hex2 = run "cc_x86-1.hex2" catm [
    out
    "${src}/x86/ELF-i386.hex2"
    cc_x86_0_hex2
  ];

  cc_x86 = run "cc_x86" hex2_0 [
    cc_x86_1_hex2
    out
  ];

  ##############################################################
  # Phase-6  M2-Planet, a C compiler with more of the language #
  ##############################################################

  M2_0_c = run "M2-0.c" catm [
    out
    "${src}/M2libc/x86/linux/bootstrap.c"
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

  M2_0_M1 = run "M2-0.M1" cc_x86 [
    M2_0_c
    out
  ];

  M2_0_0_M1 = run "M2-0-0.M1" catm [
    out
    "${src}/x86/x86_defs.M1"
    "${src}/x86/libc-core.M1"
    M2_0_M1
  ];

  M2_0_hex2 = run "M2-0.hex2" M0 [
    M2_0_0_M1
    out
  ];

  M2_0_0_hex2 = run "M2-0-0.hex2" catm [
    out
    "${src}/x86/ELF-i386.hex2"
    M2_0_hex2
  ];

  M2 = run "M2" hex2_0 [
    M2_0_0_hex2
    out
  ];

  ####################################################################
  # Phase-7  blood-elf, which gives the binaries their symbol tables #
  ####################################################################

  blood_elf_0_M1 = run "blood-elf-0.M1" M2 [
    "--architecture"
    "x86"
    "-f"
    "${src}/M2libc/x86/linux/bootstrap.c"
    "-f"
    "${src}/M2libc/bootstrappable.c"
    "-f"
    "${src}/mescc-tools/stringify.c"
    "-f"
    "${src}/mescc-tools/blood-elf.c"
    "--bootstrap-mode"
    "-o"
    out
  ];

  blood_elf_0_0_M1 = run "blood-elf-0-0.M1" catm [
    out
    "${src}/M2libc/x86/x86_defs.M1"
    "${src}/M2libc/x86/libc-core.M1"
    blood_elf_0_M1
  ];

  blood_elf_0_hex2 = run "blood-elf-0.hex2" M0 [
    blood_elf_0_0_M1
    out
  ];

  blood_elf_0_0_hex2 = run "blood-elf-0-0.hex2" catm [
    out
    "${src}/M2libc/x86/ELF-x86.hex2"
    blood_elf_0_hex2
  ];

  blood_elf_0 = run "blood-elf-0" hex2_0 [
    blood_elf_0_0_hex2
    out
  ];

  #####################################
  # Phase-8  M1, the fuller assembler #
  #####################################

  M1_macro_0_M1 = run "M1-macro-0.M1" M2 [
    "--architecture"
    "x86"
    "-f"
    "${src}/M2libc/x86/linux/bootstrap.c"
    "-f"
    "${src}/M2libc/bootstrappable.c"
    "-f"
    "${src}/mescc-tools/stringify.c"
    "-f"
    "${src}/mescc-tools/M1-macro.c"
    "--bootstrap-mode"
    "--debug"
    "-o"
    out
  ];

  M1_macro_0_footer_M1 = run "M1-macro-0-footer.M1" blood_elf_0 [
    "-f"
    M1_macro_0_M1
    "--little-endian"
    "-o"
    out
  ];

  M1_macro_0_0_M1 = run "M1-macro-0-0.M1" catm [
    out
    "${src}/M2libc/x86/x86_defs.M1"
    "${src}/M2libc/x86/libc-core.M1"
    M1_macro_0_M1
    M1_macro_0_footer_M1
  ];

  M1_macro_0_hex2 = run "M1-macro-0.hex2" M0 [
    M1_macro_0_0_M1
    out
  ];

  M1_macro_0_0_hex2 = run "M1-macro-0-0.hex2" catm [
    out
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    M1_macro_0_hex2
  ];

  M1_0 = run "M1-0" hex2_0 [
    M1_macro_0_0_hex2
    out
  ];

  ##################################################################
  # Phase-9  hex2 from C, no longer limited to a fixed label table #
  ##################################################################

  hex2_linker_0_M1 = run "hex2_linker-0.M1" M2 [
    "--architecture"
    "x86"
    "-f"
    "${src}/M2libc/sys/types.h"
    "-f"
    "${src}/M2libc/stddef.h"
    "-f"
    "${src}/M2libc/sys/utsname.h"
    "-f"
    "${src}/M2libc/x86/linux/unistd.c"
    "-f"
    "${src}/M2libc/x86/linux/fcntl.c"
    "-f"
    "${src}/M2libc/fcntl.c"
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
    "${src}/M2libc/bootstrappable.c"
    "-f"
    "${src}/mescc-tools/hex2.h"
    "-f"
    "${src}/mescc-tools/hex2_linker.c"
    "-f"
    "${src}/mescc-tools/hex2_word.c"
    "-f"
    "${src}/mescc-tools/hex2.c"
    "--debug"
    "-o"
    out
  ];

  hex2_linker_0_footer_M1 = run "hex2_linker-0-footer.M1" blood_elf_0 [
    "-f"
    hex2_linker_0_M1
    "--little-endian"
    "-o"
    out
  ];

  hex2_linker_0_hex2 = run "hex2_linker-0.hex2" M1_0 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    hex2_linker_0_M1
    "-f"
    hex2_linker_0_footer_M1
    "-o"
    out
  ];

  hex2_linker_0_0_hex2 = run "hex2_linker-0-0.hex2" catm [
    out
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    hex2_linker_0_hex2
  ];

  hex2_1 = run "hex2-1" hex2_0 [
    hex2_linker_0_0_hex2
    out
  ];

  #####################################################################
  # Phase-10 M1 again, now built by the tools above rather than below #
  #####################################################################

  M1_macro_1_M1 = run "M1-macro-1.M1" M2 [
    "--architecture"
    "x86"
    "-f"
    "${src}/M2libc/sys/types.h"
    "-f"
    "${src}/M2libc/stddef.h"
    "-f"
    "${src}/M2libc/sys/utsname.h"
    "-f"
    "${src}/M2libc/x86/linux/fcntl.c"
    "-f"
    "${src}/M2libc/fcntl.c"
    "-f"
    "${src}/M2libc/x86/linux/unistd.c"
    "-f"
    "${src}/M2libc/stdarg.h"
    "-f"
    "${src}/M2libc/string.c"
    "-f"
    "${src}/M2libc/ctype.c"
    "-f"
    "${src}/M2libc/stdlib.c"
    "-f"
    "${src}/M2libc/stdio.h"
    "-f"
    "${src}/M2libc/stdio.c"
    "-f"
    "${src}/M2libc/bootstrappable.c"
    "-f"
    "${src}/mescc-tools/stringify.c"
    "-f"
    "${src}/mescc-tools/M1-macro.c"
    "--debug"
    "-o"
    out
  ];

  M1_macro_1_footer_M1 = run "M1-macro-1-footer.M1" blood_elf_0 [
    "-f"
    M1_macro_1_M1
    "--little-endian"
    "-o"
    out
  ];

  M1_macro_1_hex2 = run "M1-macro-1.hex2" M1_0 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    M1_macro_1_M1
    "-f"
    M1_macro_1_footer_M1
    "-o"
    out
  ];

  M1 = run "M1" hex2_1 [
    "--architecture"
    "x86"
    "--little-endian"
    "--base-address"
    "0x8048000"
    "-f"
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    "-f"
    M1_macro_1_hex2
    "-o"
    out
  ];

  #####################################
  # Phase-11 hex2 again, the same way #
  #####################################

  hex2_linker_2_M1 = run "hex2_linker-2.M1" M2 [
    "--architecture"
    "x86"
    "-f"
    "${src}/M2libc/sys/types.h"
    "-f"
    "${src}/M2libc/stddef.h"
    "-f"
    "${src}/M2libc/sys/utsname.h"
    "-f"
    "${src}/M2libc/x86/linux/unistd.c"
    "-f"
    "${src}/M2libc/x86/linux/fcntl.c"
    "-f"
    "${src}/M2libc/fcntl.c"
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
    "${src}/M2libc/bootstrappable.c"
    "-f"
    "${src}/mescc-tools/hex2.h"
    "-f"
    "${src}/mescc-tools/hex2_linker.c"
    "-f"
    "${src}/mescc-tools/hex2_word.c"
    "-f"
    "${src}/mescc-tools/hex2.c"
    "--debug"
    "-o"
    out
  ];

  hex2_linker_2_footer_M1 = run "hex2_linker-2-footer.M1" blood_elf_0 [
    "-f"
    hex2_linker_2_M1
    "--little-endian"
    "-o"
    out
  ];

  hex2_linker_2_hex2 = run "hex2_linker-2.hex2" M1 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    hex2_linker_2_M1
    "-f"
    hex2_linker_2_footer_M1
    "-o"
    out
  ];

  hex2 = run "hex2" hex2_1 [
    "--architecture"
    "x86"
    "--little-endian"
    "--base-address"
    "0x8048000"
    "-f"
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    "-f"
    hex2_linker_2_hex2
    "-o"
    out
  ];

  ###########################################################################
  # Phase-12 M2-Mesoplanet, a C driver: preprocess, compile, assemble, link #
  ###########################################################################

  M2_Mesoplanet_1_M1 = run "M2-Mesoplanet-1.M1" M2 [
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

  M2_Mesoplanet_1_footer_M1 = run "M2-Mesoplanet-1-footer.M1" blood_elf_0 [
    "--little-endian"
    "-f"
    M2_Mesoplanet_1_M1
    "-o"
    out
  ];

  M2_Mesoplanet_1_hex2 = run "M2-Mesoplanet-1.hex2" M1 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    M2_Mesoplanet_1_M1
    "-f"
    M2_Mesoplanet_1_footer_M1
    "-o"
    out
  ];

  M2_Mesoplanet = run "M2-Mesoplanet" hex2 [
    "--architecture"
    "x86"
    "--little-endian"
    "--base-address"
    "0x08048000"
    "-f"
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    "-f"
    M2_Mesoplanet_1_hex2
    "-o"
    out
  ];

  ##########################################################
  # Phase-13 blood-elf again, now built by the tools above #
  ##########################################################

  blood_elf_1_M1 = run "blood-elf-1.M1" M2 [
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

  blood_elf_1_footer_M1 = run "blood-elf-1-footer.M1" blood_elf_0 [
    "--little-endian"
    "-f"
    blood_elf_1_M1
    "-o"
    out
  ];

  blood_elf_1_hex2 = run "blood-elf-1.hex2" M1 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    blood_elf_1_M1
    "-f"
    blood_elf_1_footer_M1
    "-o"
    out
  ];

  blood_elf = run "blood-elf" hex2 [
    "--architecture"
    "x86"
    "--little-endian"
    "--base-address"
    "0x08048000"
    "-f"
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    "-f"
    blood_elf_1_hex2
    "-o"
    out
  ];

  #############################################################
  # Phase-14 get_machine, which reports what it is running on #
  #############################################################

  get_machine_M1 = run "get_machine.M1" M2 [
    "--architecture"
    "x86"
    "-f"
    "${src}/M2libc/sys/types.h"
    "-f"
    "${src}/M2libc/stddef.h"
    "-f"
    "${src}/M2libc/sys/utsname.h"
    "-f"
    "${src}/M2libc/x86/linux/unistd.c"
    "-f"
    "${src}/M2libc/x86/linux/fcntl.c"
    "-f"
    "${src}/M2libc/fcntl.c"
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
    "${src}/mescc-tools/get_machine.c"
    "--debug"
    "-o"
    out
  ];

  get_machine_footer_M1 = run "get_machine-footer.M1" blood_elf [
    "--little-endian"
    "-f"
    get_machine_M1
    "-o"
    out
  ];

  get_machine_hex2 = run "get_machine.hex2" M1 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    get_machine_M1
    "-f"
    get_machine_footer_M1
    "-o"
    out
  ];

  get_machine = run "get_machine" hex2 [
    "--architecture"
    "x86"
    "--little-endian"
    "--base-address"
    "0x08048000"
    "-f"
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    "-f"
    get_machine_hex2
    "-o"
    out
  ];

  ##########################################
  # Phase-15 M2-Planet again, the same way #
  ##########################################

  M2_1_M1 = run "M2-1.M1" M2 [
    "--architecture"
    "x86"
    "-f"
    "${src}/M2libc/sys/types.h"
    "-f"
    "${src}/M2libc/stddef.h"
    "-f"
    "${src}/M2libc/sys/utsname.h"
    "-f"
    "${src}/M2libc/x86/linux/unistd.c"
    "-f"
    "${src}/M2libc/x86/linux/fcntl.c"
    "-f"
    "${src}/M2libc/fcntl.c"
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
    "${src}/M2-Planet/cc.h"
    "-f"
    "${src}/M2-Planet/cc_globals.c"
    "-f"
    "${src}/M2-Planet/cc_reader.c"
    "-f"
    "${src}/M2-Planet/cc_strings.c"
    "-f"
    "${src}/M2-Planet/cc_types.c"
    "-f"
    "${src}/M2-Planet/cc_emit.c"
    "-f"
    "${src}/M2-Planet/cc_core.c"
    "-f"
    "${src}/M2-Planet/cc_macro.c"
    "-f"
    "${src}/M2-Planet/cc.c"
    "--debug"
    "-o"
    out
  ];

  M2_1_footer_M1 = run "M2-1-footer.M1" blood_elf [
    "--little-endian"
    "-f"
    M2_1_M1
    "-o"
    out
  ];

  M2_1_hex2 = run "M2-1.hex2" M1 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    M2_1_M1
    "-f"
    M2_1_footer_M1
    "-o"
    out
  ];

  M2_Planet = run "M2-Planet" hex2 [
    "--architecture"
    "x86"
    "--little-endian"
    "--base-address"
    "0x08048000"
    "-f"
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    "-f"
    M2_1_hex2
    "-o"
    out
  ];

  #####################################################################
  # Phase-16 kaem, the shell the rest of the bootstrap is written for #
  #####################################################################

  kaem_M1 = run "kaem.M1" M2 [
    "--architecture"
    "x86"
    "-f"
    "${src}/M2libc/sys/types.h"
    "-f"
    "${src}/M2libc/stddef.h"
    "-f"
    "${src}/M2libc/sys/utsname.h"
    "-f"
    "${src}/M2libc/x86/linux/unistd.c"
    "-f"
    "${src}/M2libc/x86/linux/fcntl.c"
    "-f"
    "${src}/M2libc/fcntl.c"
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
    "-f"
    "${src}/mescc-tools/Kaem/kaem.h"
    "-f"
    "${src}/mescc-tools/Kaem/variable.c"
    "-f"
    "${src}/mescc-tools/Kaem/kaem_globals.c"
    "-f"
    "${src}/mescc-tools/Kaem/kaem.c"
    "--debug"
    "-o"
    out
  ];

  kaem_footer_M1 = run "kaem-footer.M1" blood_elf_0 [
    "-f"
    kaem_M1
    "--little-endian"
    "-o"
    out
  ];

  kaem_hex2 = run "kaem.hex2" M1 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/x86_defs.M1"
    "-f"
    "${src}/M2libc/x86/libc-full.M1"
    "-f"
    kaem_M1
    "-f"
    kaem_footer_M1
    "-o"
    out
  ];

  kaem = run "kaem" hex2 [
    "--architecture"
    "x86"
    "--little-endian"
    "-f"
    "${src}/M2libc/x86/ELF-x86-debug.hex2"
    "-f"
    kaem_hex2
    "--base-address"
    "0x8048000"
    "-o"
    out
  ];

}
