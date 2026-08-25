{
  platform,
  stage0-src,
  stage0-run,
  catm,
}:
name: hex2src:
if platform == "linux" then
  hex2src
else
  let
    inherit (stage0-src) src pe32Arch;
    out = builtins.placeholder "out";
  in
  stage0-run {
    pname = "${name}-0.hex2";
    builder = catm;
    args = [
      out
      "${src}/x86/PE32-${pe32Arch}.hex2"
      "${src}/x86/ntdll-${pe32Arch}.hex2"
      hex2src
    ];
    executable = false;
  }
