{
  derivationWithMeta,
  fetchurl,
  stage0,
  stage1,
}:
let
  rev = "28ea239c53a2d5d8800c472bc2452eaa16e37af2";
  configGuess = fetchurl {
    name = "config.guess-${builtins.substring 0 7 rev}";
    url = "https://git.savannah.gnu.org/cgit/config.git/plain/config.guess?id=${rev}";
    sha256 = "7CV3YUJSMm+InfHel7mkV8A6mpSBEEhWPCEaRElti6M=";
  };
  configSub = fetchurl {
    name = "config.sub-${builtins.substring 0 7 rev}";
    url = "https://git.savannah.gnu.org/cgit/config.git/plain/config.sub?id=${rev}";
    sha256 = "Rlxf5nx9NrcugIgScWRF1NONS5RzTKjTaoY50SMjh4s=";
  };
in
derivationWithMeta {
  name = "update-autotools-gnu-config-scripts-hook";
  inherit (stage0) system;
  builder = "${stage1.bash}/bin/bash";
  args = [ ./build.sh ];
  inherit configGuess configSub;
  setupHook = ./setup-hook.sh;
  mkdir = stage0.mescc-tools-extra.mkdir;
  cp = stage0.mescc-tools-extra.cp;
  rm = stage0.mescc-tools-extra.rm;
  replace = stage0.mescc-tools-extra.replace;
}
