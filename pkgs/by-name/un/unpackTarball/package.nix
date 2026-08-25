{ callPackage, platform, stage0 }:
if platform == "linux" then
  callPackage ./linux { inherit (stage0) system platforms; }
else
  null
