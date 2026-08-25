# The platform-selected source and target description for stage0.
#
# Bootstrap links consume this as `stage0-src`; they do not need to know
# whether the selected implementation is stage0-posix or stage0-pe32.  The
# source tree, target spelling, seed, and executable-format capabilities move
# together, so selecting this one value selects the backend without leaking a
# platform directory into every package recipe.
{ platform, isWindows }:
let
  backends = {
    linux =
      let
        sources = import ./linux/sources.nix { };
        target = import ./linux/platforms.nix { };
      in
      sources
      // target
      // {
        hex0Hash = "f74dcf9cef2aee9eb7723eca755849d474fccd89662947021d1aa08429d23c13";
        hex0NarHash = "sha256-DFmSpy4EYoKBSuPQRqtTsUfIUjlg794PnMrEg5stOFY=";
        seed = "${sources.src}/bootstrap-seeds/POSIX/x86/hex0-seed";
        executableSuffix = "";
        homepage = "https://github.com/oriansj/stage0-posix";
      };

    windows =
      let
        sources = import ./windows/sources.nix { };
        target = import ./windows/platforms.nix { };
      in
      sources
      // target
      // {
        hex0Hash = "b9db7be0fed7770be9fca46b7aa551b611fc60eaf1112a053531aae14aa46742";
        hex0NarHash = "sha256-EGgzYkH48EZquZrj9CBzIIbxB1MwND4vko6ua4IjS88=";
        seed = "${sources.src}/bootstrap-seeds/PE32/i386/hex0-seed.exe";
        executableSuffix = ".exe";
        homepage = "https://github.com/Pandapip1/stage0-pe32";
      };
  };
in
backends.${if isWindows then "windows" else "linux"} // { system = platform; }
