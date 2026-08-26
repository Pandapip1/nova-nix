{ derivationWithMeta }:
{
  bash,
  compiler,
  libc,
  platform,
  isWindows,
  system,
  platforms,
  # null on a platform that has no use for it: the hook's own builder is
  # `${bash}/bin/bash', a name this chain's Windows bash does not install
  # (bash.exe and sh.exe only), and refreshing config.guess is pointless
  # where config.guess cannot run at all -- see setupEnv below.
  updateAutotoolsGnuConfigScriptsHook ? null,
  # Extra environment every generic-phase derivation gets.  This is how a
  # platform hands setup.sh the things only it needs -- the Windows stdenv
  # passes the cc-wrapper source and the NN_* toolchain paths through here --
  # without setup.sh growing a second copy for that platform.
  setupEnv ? { },
  buildTriple ? if isWindows then "i686-pc-pe" else "i686-pc-linux-gnu",
  hostTriple ? buildTriple,
  targetTriple ? hostTriple,
  tools ? [ ],
  # configure's platform flags.  Windows gets --build ONLY, never --host:
  # configure:6910 does `ac_cv_host=$ac_cv_build' when host_alias is empty,
  # so build == host and cross_compiling stays "no" -- runtime probes still
  # really run, through wine, which is what this chain wants.
  configurePlatforms ? (if isWindows then [ "build" ] else [ "build" "host" ]),
  ccCommand ? "${compiler}/bin/tcc",
  arCommand ? "${compiler}/bin/tcc -ar",
}:
let
  shell = "${bash}/bin/bash${if isWindows then ".exe" else ""}";
  # TinyCC is installed as `bin/tcc` on both sides of the bootstrap, even
  # though the Windows binary is PE32.
  libcIncludeFlags = builtins.concatStringsSep " " (
    map (path: "-I ${path}") (libc.includePaths or [ "${libc}/include" ])
  );
  cc = "${ccCommand} -B ${libc}/lib ${libcIncludeFlags}";
  ar = arCommand;
  initialPath = builtins.concatStringsSep ":" (map (tool: "${tool}/bin") tools);
  asList = value: if builtins.isList value then value else [ value ];

  # Bootstrap recipes with an explicit builder predate the generic phase
  # runner.  Keeping their complete environment intact is also what makes the
  # constructor usable at a stage boundary: early stage2 recipes help produce
  # stage1's final tools and therefore must not force those tools as defaults.
  genericDefaults = {
    builder = shell;
    args = [ ./setup.sh ];
    SHELL = shell;
    PATH = initialPath;
    # The same list again, under a name wine does not rename on import -- see
    # setup.sh's own comment at $stdenvToolPath.  PATH above stays for a
    # native Linux build and for anything reading the derivation.
    stdenvToolPath = initialPath;
    CC = cc;
    AR = ar;
    LIBC = "${libc}";
    inherit buildTriple hostTriple targetTriple;
    propagatedNativeBuildInputs =
      if updateAutotoolsGnuConfigScriptsHook == null then
        [ ]
      else
        [ updateAutotoolsGnuConfigScriptsHook ];
  }
  // setupEnv;
in
{
  inherit
    ar
    buildTriple
    cc
    hostTriple
    initialPath
    libc
    shell
    system
    targetTriple
    ;

  mkDerivation =
    attrs:
    let
      defaults = if attrs ? builder then { } else genericDefaults;
      effectivePlatforms = attrs.configurePlatforms or configurePlatforms;
      platformFlags =
        (if builtins.elem "build" effectivePlatforms then [ "--build=${buildTriple}" ] else [ ])
        ++ (if builtins.elem "host" effectivePlatforms then [ "--host=${hostTriple}" ] else [ ])
        ++ (if builtins.elem "target" effectivePlatforms then [ "--target=${targetTriple}" ] else [ ]);
      configureFlags = builtins.concatStringsSep " " (
        asList (attrs.configureFlags or [ ]) ++ platformFlags
      );
      scriptDefaults = if attrs ? buildScript then { phases = "buildPhase"; } else { };
    in
    derivationWithMeta (
      defaults
      // scriptDefaults
      // attrs
      // {
        inherit configureFlags system;
        meta = { inherit platforms; } // (attrs.meta or { });
      }
    );
}
