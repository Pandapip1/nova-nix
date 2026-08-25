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
  updateAutotoolsGnuConfigScriptsHook,
}:
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
  inherit (stage1) bash libc;
  compiler = stage1.tinycc;
  tools = [
    stage1.bash
    stage1.tinycc
    stage2.binutils
    stage2.coreutils
    stage2.diffutils
    stage2.findutils
    stage2.gawk5
    stage2.gnugrep
    stage2.gnumake
    stage2.gnupatch
    stage2.gnused
    stage2.gnutar
    stage2.gzip
  ];
}
