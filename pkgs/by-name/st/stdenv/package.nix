{
  mkStdenv,
  platform,
  isWindows,
  buildTriple,
  hostTriple,
  targetTriple,
  stage0,
  stage1,
  stage2,
  stage3,
  gcc,
  updateAutotoolsGnuConfigScriptsHook,
}:
let
  executableSuffix = stage0.executableSuffix;
in
mkStdenv {
  inherit
    platform
    isWindows
    buildTriple
    hostTriple
    targetTriple
    updateAutotoolsGnuConfigScriptsHook
    ;
  inherit (stage0) system platforms;
  inherit (stage1) bash;
  libc = stage3.libc;
  compiler = gcc;
  ccCommand = "${gcc}/bin/gcc${executableSuffix}";
  arCommand = "${stage2.binutils}/bin/ar${executableSuffix}";
  tools = [
    stage1.bash
    gcc
    stage2.binutils
    stage2.coreutils
    stage2.diffutils
    stage2.findutils
    stage2.gawk5
    stage2.gnugrep
    stage2.gnumake
    stage2.gnupatch
    stage2.gnused
    stage3.gnutar
    stage2.gzip
  ];
}
