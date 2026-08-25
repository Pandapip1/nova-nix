{
  platform,
  stage0,
  stage2,
  gcc46-cxx,
  libc,
}:
if platform == "linux" then
  stage2.callPackage ../gcc46/linux/10.nix {
    inherit (stage0) system platforms;
    gcc = gcc46-cxx;
    musl = libc;
  }
else
  gcc46-cxx
