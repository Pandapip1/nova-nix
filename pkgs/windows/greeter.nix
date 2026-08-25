# A buildable pointer at the by-name greeter package, for `nova-nix build
# pkgs\windows\greeter.nix`: build takes one derivation-valued expression,
# and by-name/gr/greeter/package.nix is a function (it takes
# { stdenv, libgreet }), so something has to call it.  pkgs/windows/
# default.nix already does, as `greeter` -- by-name is walked, not
# enumerated, so the attribute exists by virtue of the directory.
(import ./default.nix).greeter
