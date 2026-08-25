{
  platform,
  stage0,
  stage3,
}:
if platform == "linux" then
  stage3.callPackage ../../st/stage3/by-name/gc/gcc46/linux/latest.nix {
    inherit (stage0) system platforms;
    gcc = stage3.gcc15;
    musl = stage3.libc;
    gnutar = stage3.gnutar;
  }
else
  stage3.gcc15
