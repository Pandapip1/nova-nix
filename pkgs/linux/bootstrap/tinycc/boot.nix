# TinyCC, compiled by MesCC: the first real C compiler in the bootstrap.
#
# Everything below this point is either assembled from hex or compiled by
# something written to be small enough to audit -- cc_x86, M2-Planet, MesCC.
# tcc is the first that implements enough of C to build the programs a system
# is made of, and the first that can compile itself.
#
# Two steps.  MesCC compiles tcc.c to M1 assembly, in one translation unit --
# ONE_SOURCE=1 makes tcc.c include the rest of the compiler, because MesCC has
# no separate compilation.  Then MesCC links that against the Mes C library,
# which is what -L and -l name.
#
# The defines are upstream's, by way of live-bootstrap and nixpkgs: they tell
# tcc what it is targeting and where to look at runtime, and they turn off the
# parts of tcc that need more of C than MesCC provides.
{
  derivationWithMeta,
  src,
  version,
  system,
  platforms,
  mes-m2,
  mes-libc,
  nyacc,
  stage0,
  mesSrc,
}:
let
  arch = "x86";
  tccTarget = "I386";
  out = builtins.placeholder "out";

  meta = {
    description = "Tiny C Compiler's bootstrappable fork";
    homepage = "https://gitlab.com/janneke/tinycc";
    license = "lgpl21Only";
    inherit platforms;
  };

  # MesCC, as a derivation.  The interpreter is the builder; M1 and hex2 are
  # named in the environment rather than found on PATH.
  mescc =
    { pname, name ? null, args }:
    derivationWithMeta (
      {
        inherit pname version system meta;

        MES_ARENA = "100000000";
        MES_MAX_ARENA = "100000000";
        MES_STACK = "6000000";
        MES_PREFIX = "${mesSrc}";
        GUILE_LOAD_PATH = "${mesSrc}/mes/module:${mesSrc}/module:${nyacc.guilePath}";
        M1 = stage0.M1;
        HEX2 = stage0.hex2;
        BLOOD_ELF = stage0.blood_elf_0;

        builder = mes-m2;
        args = [
          "-e"
          "main"
          "${mes-libc}/lib/mescc.scm"
          "--"
        ]
        ++ args;
      }
      // (if name == null then { } else { inherit name; })
    );

  # config.h is empty: tcc reads one, and everything it would say is given as
  # a -D below instead.
  configH = builtins.toFile "config.h" "";

  configInclude = derivationWithMeta {
    pname = "tinycc-config-include";
    inherit version system meta;
    bin_mkdir = stage0.mescc-tools-extra.mkdir;
    bin_cp = stage0.mescc-tools-extra.cp;
    inherit configH;
    builder = stage0.kaem;
    args = [
      "--verbose"
      "--strict"
      "--file"
      ./config-include.kaem
    ];
  };

  # Step one: tcc.c to M1 assembly.  The .s suffix is load-bearing -- MesCC
  # dispatches on it, and takes anything that is not .c or .E for an object.
  assembly = mescc {
    pname = "tinycc-boot-mes.s";
    name = "tinycc-boot-mes-${version}.s";
    args = [
      "-S"
      "-o"
      out
      "-I"
      "${configInclude}"
      "-D"
      "BOOTSTRAP=1"
      "-I"
      "${src}"
      "-D"
      "TCC_TARGET_${tccTarget}=1"
      "-D"
      "inline="
      "-D"
      "CONFIG_TCCDIR=\"\""
      "-D"
      "CONFIG_SYSROOT=\"\""
      "-D"
      "CONFIG_TCC_CRTPREFIX=\"{B}\""
      "-D"
      "CONFIG_TCC_ELFINTERP=\"/mes/loader\""
      "-D"
      "CONFIG_TCC_LIBPATHS=\"{B}\""
      "-D"
      "CONFIG_TCC_SYSINCLUDEPATHS=\"${src}/include:${mesSrc}/include\""
      "-D"
      "TCC_LIBGCC=\"libc.a\""
      "-D"
      "TCC_LIBTCC1=\"libtcc1.a\""
      "-D"
      "CONFIG_TCC_LIBTCC1_MES=0"
      "-D"
      "CONFIG_TCCBOOT=1"
      "-D"
      "CONFIG_TCC_STATIC=1"
      "-D"
      "CONFIG_USE_LIBGCC=1"
      "-D"
      "TCC_MES_LIBC=1"
      "-D"
      "TCC_VERSION=\"0.9.28-${version}\""
      "-D"
      "ONE_SOURCE=1"
      "${src}/tcc.c"
    ];
  };
in
# Step two: link it against the Mes C library.  -L names the directory whose
# <arch>-mes subdirectory holds crt1.o and libc+tcc.a; the second -L is the
# Mes source tree, where the ELF header and footer MesCC links with live.
mescc {
  pname = "tinycc-boot-mes";
  args = [
    "-L"
    "${mes-libc}/lib"
    "-L"
    "${mesSrc}/lib"
    "-l"
    "c+tcc"
    "-o"
    out
    assembly
  ];
}
