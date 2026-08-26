# A buildable pointer at the gcc-cxx package, the same idiom
# ../gcc_4_6_4/build.nix uses: `nova-nix build` takes one
# derivation-valued expression.
(import ../../../../../../default.nix { platform = "i686-windows"; }).stage3.gcc-cxx_4_6_4
