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
  tccTarget,
  mesArchInclude,
  extraTargetDefines,
  # Defines every round from boot0 up should carry, both when compiling
  # tcc.c into that round's own tcc and when that tcc compiles libtcc1.c
  # for its library. Unlike extraTargetDefines (which reaches only the
  # single MesCC-compiled bootstrap round) this can be, and usually is,
  # a strict superset of it: TCC_TARGET_PE=1 belongs here even though
  # MesCC cannot compile tccpe.c's own #pragma pack, because a real tcc
  # compiling tcc.c can.
  laterTargetDefines ? [ ],
  # A pre-built crt1 object -- unused by any call below now that bootMes's
  # own library compiles crt1Source instead (see there for why), but kept
  # as the signal round's own compiler build still reads to pick between
  # boot-round.kaem and boot-round-windows.kaem.
  crt1Object ? null,
  # A crt1.c for round's own library, from boot0 up: unlike bootMes, every
  # round after it has a real tcc doing the compiling, which can build a
  # real crt1 from C source the ordinary way -- see recompileLibc's own
  # crt1Source, and lib/windows/x86-mes-gcc/crt1.c for why one exists on
  # this side at all where lib/linux/${arch}-mes-gcc/crt1.c already did.
  windowsCrt1Src ? null,
  # What separates the entries of CONFIG_TCC_SYSINCLUDEPATHS, which tcc splits
  # on PATHSEP.  tcc.h defines that as ';' under TCC_TARGET_PE and ':'
  # everywhere else -- so once this chain's tcc is a PE one, a colon-joined
  # list is not several paths but a single nonexistent one, and the very first
  # #include of the round below fails with "include file 'stdlib.h' not
  # found".  Defaults to the ELF chain's colon.
  pathSep ? ":",
  # The ImageBase/e_entry base mescc's linker (hex2 --base-address) should
  # assume when it resolves an absolute address -- a string literal's, a
  # global's -- into the bytes it writes.  null keeps mescc's own default,
  # 0x1000000, which is also what lib/linux/x86-mes/elf32-header.hex2
  # hardcodes as its own base, so the two already agree there and Linux
  # never has to say so. lib/m2/x86/PE32-i386.hex2 hardcodes 0x400000
  # instead (see pkgs/windows/bootstrap/mes/mes-m2.nix's own identical
  # override, for the stage before this one that links against the same
  # header) -- so boot-mes's link has to be told, or every absolute address
  # it emits lands 0xC00000 too high: still a valid-looking pointer, just
  # one past the file's own content, in the zero-filled memory beyond
  # SizeOfRawData, so the string or global read back through it is all
  # zero bytes rather than what was meant.
  baseAddress ? null,
  # hex2, as MesCC's linker: the one that reads flags (--base-address,
  # --little-endian) rather than the hand-written one some chains bootstrap
  # with, which cannot.  Defaults to the ELF chain's own, which is already
  # that one; the PE32 chain has to say so, because its `stage0.hex2` is the
  # hand-written positional one and its flag-reading one is `hex2-new`.
  hex2 ? stage0.hex2,
  # blood-elf, for `--debug-info`: only ELF programs carry the symbol table
  # it adds, and the PE32 chain builds no such thing.  null omits BLOOD_ELF
  # from the environment rather than pointing it at nothing.
  bloodElf ? stage0.blood_elf_0,
  # How many cells Mes may have while compiling tcc.c -- see the identical
  # parameter on pkgs/bootstrap/mes/libc.nix, which explains why this cannot
  # just be the Linux number everywhere: a 32-bit Windows process only gets
  # so much contiguous address space, less again under wine.
  arenaSize ? "100000000",
}:
let
  # The fork's source, which every round below mainline builds from.
  forkSrc = src;
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

        MES_ARENA = arenaSize;
        MES_MAX_ARENA = arenaSize;
        MES_STACK = "6000000";
        MES_PREFIX = "${mesSrc}";
        GUILE_LOAD_PATH = "${mesSrc}/mes/module:${mesSrc}/module:${nyacc.guilePath}";
        M1 = stage0.M1;
        HEX2 = hex2;

        builder = mes-m2;
        args = [
          "-e"
          "main"
          "${mes-libc}/lib/mescc.scm"
          "--"
        ]
        ++ args;
      }
      // (if bloodElf == null then { } else { BLOOD_ELF = bloodElf; })
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
    ]
    ++ builtins.concatMap (d: [ "-D" d ]) extraTargetDefines
    ++ [
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
      "CONFIG_TCC_SYSINCLUDEPATHS=\"${src}/include${pathSep}${mesSrc}/include\""
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
    ]
    ++ (if baseAddress == null then [ ] else [ "--base-address" baseAddress ])
    ++ [
      "-o"
      out
      assembly
    ];
  };

  inherit (stage0.mescc-tools-extra) mkdir catm cp;

  # The C library, recompiled by the tcc of this round.  Every round links
  # against the library the round below it made, so every round makes one.
  recompileLibc =
    {
      name,
      tcc,
      libtccOptions,
      src ? forkSrc,
      runtimeSecond ? "va_list.c",
      # What this call's tcc already understands about its target, if
      # anything -- see round's own use of this below, and bootMes's
      # deliberate omission of it.
      targetDefines ? [ ],
      # A pre-built crt1, for a kernel whose crt1 isn't C -- see
      # libs-windows.kaem.  null recompiles crt1 (and crti/crtn, which
      # only exist as source for a kernel that has them at all) from
      # mes-libc.gnuSource the way libs.kaem always has.
      crt1Object ? null,
      # A crt1.c to recompile with this call's own tcc instead -- see
      # libs-windows-src.kaem.  Windows has no crti/crtn (PE has no
      # .init/.fini to bracket), so this and crt1Object are the only two
      # shapes a non-null crt1 comes in; a caller sets at most one.
      crt1Source ? null,
    }:
    derivationWithMeta (
    {
      pname = "${name}-libs";
      inherit version system meta;

      bin_mkdir = mkdir;
      inherit tcc;

      # One variable per argument: kaem substitutes a variable as a single
      # argument, so anything that has to be several cannot be one string.
      incConfig = mes-libc.configInclude;
      incMes = "${mesSrc}/include";
      incMesArch = "${mesSrc}/include/${mesArchInclude}";
      inherit tccTarget;

      # The rounds differ in how much of C the library may use, never in more
      # than two flags for that -- and separately, every round may need to be
      # told what it is targeting (targetDefines), a thing every *caller* of
      # this decides for itself: bootMes still uses the bootstrap round's own
      # (deliberately not-yet-target-aware) tcc to build its library, while
      # round's own call passes laterTargetDefines through.  Three slots, not
      # two, so the two kinds never have to share one.
      libtccOpt1 = if libtccOptions == [ ] then "-D BOOTSTRAP=1" else builtins.elemAt libtccOptions 0;
      libtccOpt2 =
        if builtins.length libtccOptions > 1 then builtins.elemAt libtccOptions 1 else "-D BOOTSTRAP=1";
      libtccOpt3 =
        if targetDefines == [ ] then "-D BOOTSTRAP=1" else "-D " + builtins.elemAt targetDefines 0;

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
        (
          if crt1Object != null then
            ./libs-windows.kaem
          else if crt1Source != null then
            ./libs-windows-src.kaem
          else
            ./libs.kaem
        )
      ];
    }
    // (
      if crt1Object != null then
        {
          bin_cp = cp;
          crt1_o = crt1Object;
        }
      else if crt1Source != null then
        { crt1_c = crt1Source; }
      else
        {
          crt1_c = mes-libc.gnuSource.crt1;
          crti_c = mes-libc.gnuSource.crti;
          crtn_c = mes-libc.gnuSource.crtn;
        }
    )
    );

  # kaem substitutes a variable as one argument, so an option list has to be
  # one variable per option.  There is no way to loop in the script either, so
  # the slots are fixed and a round fills what it needs.
  # Ten, not eight: mainline's own buildOptions came to exactly eight, so the
  # -D TCC_TARGET_PE=1 that round appends after them fell off the end and the
  # whole chain built a tcc that said "i386 Linux" and meant it. Unused slots
  # are harmless -- each holds a -D BOOTSTRAP=1 that is already true.
  optionSlotCount = 10;

  optionSlots =
    options:
    # Refuse rather than truncate. Dropping the tail of this list produces a
    # tcc built for the wrong target, or without a define it needed, with
    # nothing said at any point -- which is how the PE32 chain came to build
    # every round and end in a Linux-targeting compiler.
    assert builtins.length options <= optionSlotCount
      || throw "tinycc boot: ${toString (builtins.length options)} options for ${toString optionSlotCount} slots -- raise optionSlotCount and add the matching \${optN} to boot-round.kaem and boot-round-windows.kaem";
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
          sysIncludePaths = "\"${src}/include${pathSep}${mesSrc}/include${pathSep}${mes-libc.configInclude}\"";

          builder = stage0.kaem;
          args = [
            "--verbose"
            "--strict"
            "--file"
            (if crt1Object == null then ./boot-round.kaem else ./boot-round-windows.kaem)
          ];
        }
        # One variable per option; see the script.  A slot a round does not
        # use repeats a harmless flag rather than being empty, which kaem
        # would pass as an empty argument.  laterTargetDefines rides along
        # after buildOptions -- every round from boot0 up has to already
        # know what it is targeting, or a later round only regains that
        # knowledge by being told again.  Not extraTargetDefines: that one
        # reaches the single MesCC-compiled round, which may need to stay
        # ignorant of the target for reasons that have nothing to do with
        # what the *target* is -- MesCC not implementing some C construct
        # tcc.c only needs once a define is on, on this side's PE32 --
        # while the tcc-compiled rounds from boot0 on have no such gap.
        // optionSlots (buildOptions ++ map (d: "-D " + d) laterTargetDefines)
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
        targetDefines = laterTargetDefines;
        crt1Source = windowsCrt1Src;
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
      # Not crt1Object: nothing reads bootMes.libs's own crt1.o in the raw
      # hex2-source form -- boot-mes.exe's own link already happened,
      # straight from mes.libc.crt1, entirely separately from this
      # library. What DOES read this crt1.o is boot0's own compiler link,
      # via prevLibs, and that is a real tcc linker: it needs a real
      # object file, which boot-mes.exe can already compile from crt1.c
      # the same ordinary way it compiles libtcc1.c and libc.c for this
      # same library.
      crt1Source = windowsCrt1Src;
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
      #
      # Windows takes the same line by absolute path instead, through the
      # template below.  CONFIG_TCC_PREDEFS puts this into every translation
      # unit the compiler ever reads, including ones belonging to another C
      # library entirely: ntlibc compiles -nostdinc, so there is no include
      # path for <mes/config.h> to be found on, and none can be added --
      # ntlibc's build archives with CC followed by -ar, and tcc reads -ar
      # only as its own first argument, so CC has to stay the compiler and
      # nothing else.  An absolute path needs no search and costs the Mes
      # side nothing.
      #
      # Written by replace rather than by builtins.toFile, which refuses a
      # file that mentions a derivation: the template carries a placeholder
      # and tccdefs-windows.kaem substitutes the real path into it.
      configLine = builtins.toFile "tccdefs-config.h" ''
        "#include <mes/config.h>\n"
      '';
      configTemplate = builtins.toFile "tccdefs-config.h.in" ''
        "#include \"@MESCONFIG@/mes/config.h\"\n"
      '';
      mesConfigInclude = mes-libc.configInclude;

      builder = stage0.kaem;
      args = [
        "--verbose"
        "--strict"
        "--file"
        # The same signal round uses to pick its own kaem file: see there.
        (if crt1Object == null then ./tccdefs.kaem else ./tccdefs-windows.kaem)
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
