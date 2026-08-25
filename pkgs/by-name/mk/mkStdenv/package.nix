{ derivationWithMeta }:
{
  bash,
  compiler,
  libc,
  platform,
  isWindows,
  system,
  platforms,
  updateAutotoolsGnuConfigScriptsHook,
  buildTriple ? if isWindows then "i686-pc-pe" else "i686-pc-linux-gnu",
  hostTriple ? buildTriple,
  targetTriple ? hostTriple,
  tools ? [ ],
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
    CC = cc;
    AR = ar;
    LIBC = "${libc}";
    inherit buildTriple hostTriple targetTriple;
    propagatedNativeBuildInputs = [ updateAutotoolsGnuConfigScriptsHook ];
  };
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
      configurePlatforms = attrs.configurePlatforms or [ "build" "host" ];
      platformFlags =
        (if builtins.elem "build" configurePlatforms then [ "--build=${buildTriple}" ] else [ ])
        ++ (if builtins.elem "host" configurePlatforms then [ "--host=${hostTriple}" ] else [ ])
        ++ (if builtins.elem "target" configurePlatforms then [ "--target=${targetTriple}" ] else [ ]);
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
