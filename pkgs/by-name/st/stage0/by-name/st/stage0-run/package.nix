# Construct one link in the stage0 chain.  Every link is built by the previous
# bootstrap derivation from files in the selected `stage0-src`; only PE32 needs
# executable outputs to carry a suffix.
{
  derivationWithMeta,
  stage0-src,
}:
{
  pname,
  builder,
  args,
  executable ? true,
}:
derivationWithMeta {
  inherit pname;
  inherit (stage0-src) version system;
  name =
    "${pname}-${stage0-src.version}"
    + (if executable then stage0-src.executableSuffix else "");
  builder = "${builder}";
  args = map (arg: "${arg}") args;

  meta = {
    description = "Collection of tools written for use in bootstrapping";
    inherit (stage0-src) homepage platforms;
    license = "gpl3Plus";
  };
}
