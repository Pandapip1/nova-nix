# hex0, assembled from its own annotated source by the bootstrap seed.
#
# hex0 reads a file of hexadecimal digit pairs and writes the bytes they
# denote.  The seed is the one binary in the chain that was not produced from
# source by the chain itself, and hex0_x86.hex0 is its annotated source, so
# this derivation is also the seed's proof: assembling that source with the
# seed must reproduce the seed exactly.  Declaring the result fixed-output
# makes the round trip a build-time assertion rather than a claim in a comment
# -- a seed that does not reproduce itself fails here, instead of silently
# poisoning everything built above it.
#
# The assembler takes its destination as argv[2] rather than reading $out from
# the environment, so the output path is passed as builtins.placeholder "out"
# and the builder substitutes the real path before spawning.  A derivation
# cannot otherwise name its own output: that path is a hash of the derivation,
# arguments included.
#
# Everything above this link uses hex0, not the seed.
{
  derivationWithMeta,
  hex0-seed,
  src,
  version,
  system,
  platforms,
  stage0Arch,
}:
derivationWithMeta {
  pname = "hex0";
  name = "hex0-${version}.exe";
  inherit version system;

  builder = hex0-seed;
  args = [
    "${src}/x86/hex0_${stage0Arch}.hex0"
    (builtins.placeholder "out")
  ];

  # The output is a single file, so the hash covers the bytes rather than a
  # NAR serialisation of a tree.
  outputHashMode = "flat";
  outputHashAlgo = "sha256";
  outputHash = "b9db7be0fed7770be9fca46b7aa551b611fc60eaf1112a053531aae14aa46742";

  passthru = { inherit hex0-seed; };

  meta = {
    description = "Minimal PE32 assembler for bootstrapping";
    homepage = "https://github.com/Pandapip1/stage0-pe32";
    license = "gpl3Plus";
    inherit platforms;
  };
}
