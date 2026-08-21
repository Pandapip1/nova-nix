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
  mainlineSrc,
  mainlineVersion,
}:
let
  # The fork's source, which every round below mainline builds from.
  forkSrc = src;

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
  # Step two: link it against the Mes C library.  -L names the directory whose
  # <arch>-mes subdirectory holds crt1.o and libc+tcc.s; the second -L is the
  # Mes source tree, where the ELF header and footer MesCC links with live.
  boot-mes = mescc {
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
  };

  inherit (stage0.mescc-tools-extra) mkdir catm;

  # The C library, recompiled by the tcc of this round.  Every round links
  # against the library the round below it made, so every round makes one.
  recompileLibc =
    {
      name,
      tcc,
      libtccOptions,
      src ? forkSrc,
      runtimeSecond ? "va_list.c",
    }:
    derivationWithMeta {
      pname = "${name}-libs";
      inherit version system meta;

      bin_mkdir = mkdir;
      inherit tcc;

      # One variable per argument: kaem substitutes a variable as a single
      # argument, so anything that has to be several cannot be one string.
      incConfig = mes-libc.configInclude;
      incMes = "${mesSrc}/include";
      incMesArch = "${mesSrc}/include/linux/${arch}";
      inherit tccTarget;

      # The rounds differ only in how much of C the library may use, and
      # never in more than two flags.
      libtccOpt1 = if libtccOptions == [ ] then "-D BOOTSTRAP=1" else builtins.elemAt libtccOptions 0;
      libtccOpt2 =
        if builtins.length libtccOptions > 1 then builtins.elemAt libtccOptions 1 else "-D BOOTSTRAP=1";

      crt1_c = mes-libc.gnuSource.crt1;
      crti_c = mes-libc.gnuSource.crti;
      crtn_c = mes-libc.gnuSource.crtn;
      # tinycc's own runtime, from the source being built -- see libs.kaem.
      # The second file differs between the two trees: the fork carries
      # va_list.c, mainline an assembly alloca.  nixpkgs pairs them the same
      # way.
      libtcc1_c = "${src}/lib/libtcc1.c";
      valist_c = "${src}/lib/${runtimeSecond}";
      libc_c = mes-libc.gnuSource.libc;
      getopt_c = mes-libc.gnuSource.getopt;

      builder = stage0.kaem;
      args = [
        "--verbose"
        "--strict"
        "--file"
        ./libs.kaem
      ];
    };

  # kaem substitutes a variable as one argument, so an option list has to be
  # one variable per option.  There is no way to loop in the script either, so
  # the slots are fixed and a round fills what it needs.
  optionSlotCount = 8;

  optionSlots =
    options:
    builtins.listToAttrs (
      map (i: {
        name = "opt${toString (i + 1)}";
        value = if builtins.length options > i then builtins.elemAt options i else "-D BOOTSTRAP=1";
      }) (builtins.genList (i: i) optionSlotCount)
    );

  # One round: tcc compiled by the round below, then that round's library.
  #
  # `prev` is named by its binary and its library rather than by a package,
  # because the first round's tcc is a bare file -- MesCC links an executable,
  # not a directory -- while every round after it is $out/bin/tcc.
  round =
    {
      name,
      prev,
      buildOptions,
      libtccOptions,
      src ? forkSrc,
      runtimeSecond ? "va_list.c",
    }:
    rec {
      compiler = derivationWithMeta (
        {
          pname = name;
          inherit version system meta;

          bin_mkdir = mkdir;
          bin_catm = catm;
          prevTcc = prev.tcc;
          prevLibs = prev.libs;
          inherit src tccTarget;

          # Where tcc looks for headers at runtime: its own, then Mes's, then
          # the generated ones -- mes/config.h and arch/.
          # Plain quotes, not kaem's \" escape: a variable's VALUE is
          # substituted verbatim, escapes and all, so the quotes this C string
          # literal needs have to already be quotes.  The escape is only for
          # quotes written in the script text itself.
          sysIncludePaths = "\"${src}/include:${mesSrc}/include:${mes-libc.configInclude}\"";

          builder = stage0.kaem;
          args = [
            "--verbose"
            "--strict"
            "--file"
            ./boot-round.kaem
          ];
        }
        # One variable per option; see the script.  A slot a round does not
        # use repeats a harmless flag rather than being empty, which kaem
        # would pass as an empty argument.
        // optionSlots buildOptions
      );

      # What the next round builds with.
      tcc = "${compiler}/bin/tcc";

      libs = recompileLibc {
        inherit
          name
          libtccOptions
          tcc
          src
          runtimeSecond
          ;
      };
    };

  # The round below the first: the MesCC-compiled tcc, which is a bare binary,
  # plus the library that tcc can compile.
  bootMes = {
    tcc = boot-mes;
    compiler = boot-mes;
    libs = recompileLibc {
      name = "tinycc-boot-mes";
      tcc = boot-mes;
      libtccOptions = [ ];
    };
  };
  # Mainline tcc compiles its predefined macros in rather than reading them
  # at runtime, so they have to be turned into a C string first -- by
  # conftest.c, which upstream ships for the purpose, built by the round
  # below.
  tccdefs =
    { name, prev, src }:
    derivationWithMeta {
      pname = "${name}-tccdefs";
      inherit version system meta;

      bin_mkdir = mkdir;
      bin_catm = catm;
      bin_replace = stage0.mescc-tools-extra.replace;

      # The two lines removed from tccdefs.h, and what replaces them.  They
      # are variables because kaem would otherwise split them on spaces; the
      # replacement is a comment rather than nothing because neither an empty
      # argument nor one that is only a space survives kaem: replace is handed
      # no value at all and stops.  A comment is what the preprocessor would
      # have made of the line anyway.
      allocaBuiltin = "__BOTH(void*, alloca, (__SIZE_TYPE__))";
      allocaDecl = "void *alloca(__SIZE_TYPE__);";
      blank = "/*alloca-comes-from-the-C-library*/";
      prevTcc = prev.tcc;
      prevLibs = prev.libs;
      inherit src;

      # Appended to the generated macros: this tcc targets the Mes C library,
      # so its configuration has to be predefined too.
      configLine = builtins.toFile "tccdefs-config.h" ''
        "#include <mes/config.h>\n"
      '';

      builder = stage0.kaem;
      args = [
        "--verbose"
        "--strict"
        "--file"
        ./tccdefs.kaem
      ];
    };

  # Upstream's rounds, from the fork's boot.sh: each one hands tcc more of
  # the language than the last.
  boot0 = round {
    name = "tinycc-boot0";
    prev = bootMes;
    buildOptions = [ "-D HAVE_LONG_LONG=1" "-D HAVE_SETJMP=1" ];
    libtccOptions = [ "-D HAVE_LONG_LONG=1" ];
  };

  boot1 = round {
    name = "tinycc-boot1";
    prev = boot0;
    buildOptions = [ "-D HAVE_BITFIELD=1" "-D HAVE_LONG_LONG=1" "-D HAVE_SETJMP=1" ];
    libtccOptions = [ "-D HAVE_LONG_LONG=1" ];
  };

  boot2 = round {
    name = "tinycc-boot2";
    prev = boot1;
    buildOptions = [
      "-D HAVE_BITFIELD=1"
      "-D HAVE_FLOAT_STUB=1"
      "-D HAVE_LONG_LONG=1"
      "-D HAVE_SETJMP=1"
    ];
    libtccOptions = [ "-D HAVE_FLOAT_STUB=1" "-D HAVE_LONG_LONG=1" ];
  };

  boot3 = round {
    name = "tinycc-boot3";
    prev = boot2;
    buildOptions = [
      "-D HAVE_BITFIELD=1"
      "-D HAVE_FLOAT=1"
      "-D HAVE_LONG_LONG=1"
      "-D HAVE_SETJMP=1"
    ];
    libtccOptions = [ "-D HAVE_FLOAT=1" "-D HAVE_LONG_LONG=1" ];
  };

  # A fifth round, with the same options as the fourth.
  #
  # It is not redundant, and skipping it is what made every float wrong.
  # boot3 is the first round allowed real floating point, but it was COMPILED
  # by boot2, which had only stubs -- so the float code inside boot3 was
  # generated by a compiler that could not do floating point properly.
  # Compiling the same source again, with boot3, gives a compiler whose float
  # support was itself compiled by one that had it.  That is the fixed point,
  # and it takes one round past the flag to reach.
  bootstrappable = round {
    name = "tinycc-bootstrappable";
    prev = boot3;
    buildOptions = [
      "-D HAVE_BITFIELD=1"
      "-D HAVE_FLOAT=1"
      "-D HAVE_LONG_LONG=1"
      "-D HAVE_SETJMP=1"
    ];
    libtccOptions = [ "-D HAVE_FLOAT=1" "-D HAVE_LONG_LONG=1" ];
  };
  # Mainline tcc, built by the fork's last round.  From here up, the compiler
  # is upstream's own rather than one carrying changes made so that MesCC
  # could compile it.
  #
  # nixpkgs patches three things into this source; none is needed here.  Two
  # are x86_64-only, and the third forces static linking, which is a flag
  # (-static) rather than a change to libtcc.c -- so the tree is used as
  # fetched.
  mainlineDefs = tccdefs {
    name = "tinycc-mes";
    prev = bootstrappable;
    src = mainlineSrc;
  };

  mainline = round {
    name = "tinycc-mes";
    prev = bootstrappable;
    src = mainlineSrc;
    runtimeSecond = "alloca.S";
    buildOptions = [
      # This tcc is itself statically linked.  There is no dynamic loader in
      # the bootstrap to run anything else: CONFIG_TCC_ELFINTERP is the empty
      # string, and a binary that names no interpreter is refused by the
      # kernel with "Exec format error".
      #
      # It changes only how tcc is linked, not what tcc does by default when
      # it links something else -- nixpkgs gets that by patching libtcc.c to
      # set s->static_link, which needs a writable copy of the source.  Here
      # every caller passes -static instead, which says the same thing at the
      # point where it is true.
      "-static"
      "-D HAVE_BITFIELD=1"
      "-D HAVE_FLOAT=1"
      "-D HAVE_LONG_LONG=1"
      "-D HAVE_SETJMP=1"
      "-D CONFIG_TCC_PREDEFS=1"
      # Glued, with no space: an option slot is ONE argument, and tcc reads
      # "-I /path" as a single token asking for a directory whose name starts
      # with a space.  -D tolerates the same shape; -I does not.
      "-I${mainlineDefs}"
      "-D CONFIG_TCC_SEMLOCK=0"
    ];
    libtccOptions = [
      "-D HAVE_FLOAT=1"
      "-D HAVE_LONG_LONG=1"
    ];
  };
in
{
  inherit
    boot-mes
    bootMes
    boot0
    boot1
    boot2
    boot3
    bootstrappable
    mainline
    mainlineDefs
    ;

  # What anything above this asks for: mainline tcc, and its library.
  inherit (mainline) compiler libs tcc;
}
