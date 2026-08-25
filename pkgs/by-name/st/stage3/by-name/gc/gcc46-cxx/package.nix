{
  platform,
  stage0,
  stage2,
  gcc46,
  libc,
}:
if platform == "linux" then
  stage2.callPackage ../gcc46/linux/cxx.nix {
    inherit (stage0) system platforms;
    gcc = gcc46;
    musl = libc;
  }
else
  gcc46
