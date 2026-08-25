{
  platform,
  stage0,
  stage2,
  gcc46,
}:
if platform == "linux" then
  stage2.callPackage ../../../../stage2/by-name/mu/musl-libc/gcc.nix {
    gcc = gcc46;
    inherit (stage0) system platforms;
  }
else
  stage2.libc
