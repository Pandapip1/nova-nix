# A buildable pointer at the gcc package, for `nova-nix build
# pkgs/windows/gcc.nix`: build takes one derivation-valued expression, and
# ./default.nix's own `gcc` attribute is what callPackage produced from
# bootstrap/gcc/default.nix -- see pkgs/windows/hello.nix for the same
# idiom.
(import ../../../../../../default.nix { platform = "i686-windows"; }).gcc
