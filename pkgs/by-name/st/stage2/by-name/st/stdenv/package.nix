{
  mkStdenv,
  platform,
  isWindows,
  buildTriple,
  hostTriple,
  targetTriple,
  stage0,
  stage1,
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
  ];
}
