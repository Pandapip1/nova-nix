{
  callPackage,
  stage0,
  stage1,
}:
let
  target = stage0;
in
callPackage ./default.nix {
  inherit stage0;
  inherit (target) system platforms;
  tinycc = stage1.tinycc-mes;
}
