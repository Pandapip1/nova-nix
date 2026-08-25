{
  platform,
  stage0-src,
  stage0-run,
  hex2,
}:
name: hex2src: linkedHex2:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = name;
  builder = hex2;
  args =
    [ "--architecture" stage0Arch "--little-endian" ]
    ++ (if platform == "linux" then [
      "-f" "${src}/M2libc/${stage0Arch}/ELF-${stage0Arch}-debug.hex2"
      "-f" hex2src
      "--base-address" "0x08048000"
    ] else [
      "--base-address" "0x400000"
      "-f" linkedHex2
    ])
    ++ [ "-o" out ];
}
