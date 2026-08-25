{
  platform,
  derivationWithMeta,
  stage0-src,
  kaem,
  sha256sum-bootstrap,
  match-bootstrap,
  mkdir-bootstrap,
  untar-bootstrap,
  ungz-bootstrap,
  unbz2-bootstrap,
  unxz-bootstrap,
  catm-bootstrap,
  cp-bootstrap,
  chmod-bootstrap,
  rm-bootstrap,
  replace-bootstrap,
  wrap-bootstrap,
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
    (./. + "/${platform}.kaem")
  ];

  bin_sha256sum = sha256sum-bootstrap;
  bin_match = match-bootstrap;
  bin_mkdir = mkdir-bootstrap;
  bin_untar = untar-bootstrap;
  bin_ungz = ungz-bootstrap;
  bin_unbz2 = unbz2-bootstrap;
  bin_unxz = unxz-bootstrap;
  bin_catm = catm-bootstrap;
  bin_cp = cp-bootstrap;
  bin_chmod = chmod-bootstrap;
  bin_rm = rm-bootstrap;
  bin_replace = replace-bootstrap;
  bin_wrap = wrap-bootstrap;

  meta = {
    description = "Collection of tools written for use in bootstrapping";
    homepage = "https://github.com/oriansj/mescc-tools-extra";
    license = "gpl3Plus";
    inherit platforms;
  };
}
