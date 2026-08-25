# A buildable pointer at the by-name sed package, for `nova-nix build
# pkgs\windows\sed.nix`: build takes one derivation-valued expression, and
# by-name/se/sed/package.nix is a function (it takes { stdenv, fetchurl }),
# so something has to call it. pkgs/windows/default.nix already does, as
# `sed`.
(import ../../../default.nix { platform = "i686-windows"; }).sed
