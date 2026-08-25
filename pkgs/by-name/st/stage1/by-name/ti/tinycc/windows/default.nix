{
  derivationWithMeta,
  system,
  platforms,
  stage0,
  tinycc,
  targetTriple,
}:
if targetTriple == "i686-pc-pe" then
  tinycc.boot.compiler // {
    libs = tinycc.boot.libs;
    inherit targetTriple;
  }
else if targetTriple == "x86_64-pc-pe" then
  derivationWithMeta {
    pname = "tinycc";
    inherit (tinycc) version;
    inherit system;

    src = tinycc.mainlineSrc;
    prevTcc = tinycc.boot.tcc;
    prevLibs = tinycc.boot.libs;
    tccdefs = tinycc.boot.mainlineDefs;

    bin_mkdir = stage0.mescc-tools-extra.mkdir;
    bin_catm = stage0.mescc-tools-extra.catm;
    bin_cp = stage0.mescc-tools-extra.cp;

    builder = stage0.kaem;
    args = [
      "--verbose"
      "--strict"
      "--file"
      ./build.kaem
    ];

    passthru = { inherit targetTriple; };
    meta = {
      description = "TinyCC cross compiler targeting x86_64 PE32+";
      homepage = "https://repo.or.cz/w/tinycc.git";
      license = "lgpl21Only";
      inherit platforms;
    };
  }
else
  throw "tinycc: unsupported Windows target triple ${targetTriple}"
