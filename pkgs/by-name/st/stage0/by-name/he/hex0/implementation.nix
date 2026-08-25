# Rebuild hex0 from its annotated source using the selected bootstrap seed.
# `stage0-src` supplies both without exposing a platform implementation name.
{
  derivationWithMeta,
  stage0-src,
  hex0-bootstrap,
}:
derivationWithMeta {
  pname = "hex0";
  inherit (stage0-src) version system;
  name = "hex0-${stage0-src.version}${stage0-src.executableSuffix}";

  builder = hex0-bootstrap;
  args = [
    "${stage0-src.src}/x86/hex0_${stage0-src.stage0Arch}.hex0"
    (builtins.placeholder "out")
  ];

  outputHashMode = "flat";
  outputHashAlgo = "sha256";
  outputHash = stage0-src.hex0Hash;

  passthru = { hex0-seed = hex0-bootstrap; };

  meta = {
    description = "Minimal assembler for bootstrapping";
    inherit (stage0-src) homepage platforms;
    license = "gpl3Plus";
  };
}
