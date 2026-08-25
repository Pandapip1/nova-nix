# One Mes fork and revision feeds both platform implementations.  The fork's
# Windows support is additive, so Linux does not need to stay on a separate
# parent revision and silently drift behind it.
{ }:
rec {
  version = "0.27.1-unstable-2026-08-23";

  rev = "e27137feafc8389b2e2e63d2bd54a8d5c074cf82";
  ref = "windows-pe32-ntcall";

  src = builtins.fetchGit {
    url = "https://github.com/Pandapip1/mes.git";
    inherit rev ref;
  };
}
