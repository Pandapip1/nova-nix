{
  callPackage,
  stage0,
  tinycc-bootstrap,
}:
let
  target = import ../../st/stage0-src/windows/platforms.nix { };
in
callPackage ./default.nix {
  inherit stage0;
  inherit (target) system platforms;
  tinycc = tinycc-bootstrap;
}
