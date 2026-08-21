# hex0, assembled from its own annotated source by the bootstrap seed.
#
# hex0 reads a file of hexadecimal digit pairs and writes the bytes they
# denote.  The seed is the one binary in the chain that was not produced from
# source by the chain itself, and hex0_x86.hex0 is its annotated source, so
# this derivation is also the seed's proof: assembling that source with the
# seed must reproduce the seed exactly.  Upstream says so in
# x86/mescc-tools-seed-kaem.kaem -- "hex0 should have the exact same checksum
# as hex0-seed" -- and declaring the result fixed-output makes that a
# build-time assertion rather than a comment.  A seed that does not reproduce
# itself fails here, instead of silently poisoning everything above it.
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
  inherit version system;

  builder = hex0-seed;
  args = [
    "${src}/x86/hex0_${stage0Arch}.hex0"
    (builtins.placeholder "out")
  ];

  # The output is a single file, so the hash covers the bytes rather than a
  # NAR serialisation of a tree.  This is the seed's own sha256.
  outputHashMode = "flat";
  outputHashAlgo = "sha256";
  outputHash = "f74dcf9cef2aee9eb7723eca755849d474fccd89662947021d1aa08429d23c13";

  passthru = { inherit hex0-seed; };

  meta = {
    description = "Minimal ELF assembler for bootstrapping";
    homepage = "https://github.com/oriansj/stage0-posix";
    license = "gpl3Plus";
    inherit platforms;
  };
}
