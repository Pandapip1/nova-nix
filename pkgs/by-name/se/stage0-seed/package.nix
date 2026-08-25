{ callPackage, platform }:
if platform == "windows" then callPackage ./windows.nix { } else null
