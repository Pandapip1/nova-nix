{
  platformFamily,
  derivationWithMeta,
  stage0-src,
  kaem,
  sha256sum,
  match,
  mkdir,
  untar,
  ungz,
  unbz2,
  unxz,
  catm-mescc-tools,
  cp,
  chmod,
  rm,
  replace,
  wrap,
}:
let
  inherit (stage0-src) version system platforms;
in
derivationWithMeta {
  pname = "mescc-tools-extra";
  inherit version system;
  builder = kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    (./. + "/${platformFamily}.kaem")
  ];

  bin_sha256sum = sha256sum;
  bin_match = match;
  bin_mkdir = mkdir;
  bin_untar = untar;
  bin_ungz = ungz;
  bin_unbz2 = unbz2;
  bin_unxz = unxz;
  bin_catm = catm-mescc-tools;
  bin_cp = cp;
  bin_chmod = chmod;
  bin_rm = rm;
  bin_replace = replace;
  bin_wrap = wrap;

  meta = {
    description = "Collection of tools written for use in bootstrapping";
    homepage = "https://github.com/oriansj/mescc-tools-extra";
    license = "gpl3Plus";
    inherit platforms;
  };
}
