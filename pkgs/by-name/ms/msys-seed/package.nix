{ callPackage, isWindows }:
if isWindows then callPackage ./windows.nix { } else null
