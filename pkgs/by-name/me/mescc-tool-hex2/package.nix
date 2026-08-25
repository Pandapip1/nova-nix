{
  platform,
  stage0-src,
  stage0-run,
  M1,
}:
name: M1src: linkedM1:
let
  inherit (stage0-src) src stage0Arch;
  out = builtins.placeholder "out";
in
stage0-run {
  pname = "${name}.hex2";
  builder = M1;
  args =
    [ "--architecture" stage0Arch "--little-endian" "-f" ]
    ++ (if platform == "windows" then [ linkedM1 ] else [
      "${src}/M2libc/${stage0Arch}/${stage0Arch}_defs.M1"
      "-f" "${src}/M2libc/${stage0Arch}/libc-full.M1"
      "-f" M1src
      "-f" linkedM1
    ])
    ++ [ "-o" out ];
  executable = false;
}
