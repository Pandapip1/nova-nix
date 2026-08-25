# A buildable pointer at the by-name libgreet package, for `nova-nix build
# pkgs\windows\libgreet.nix`: build takes one derivation-valued expression,
# and by-name/li/libgreet/package.nix is a function (it takes { stdenv }),
# so something has to call it. pkgs/windows/default.nix already does, as
# `libgreet`.
(import ../../../default.nix { platform = "i686-windows"; }).libgreet
