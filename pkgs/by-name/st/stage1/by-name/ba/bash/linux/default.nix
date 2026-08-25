# GNU bash 2.05b, compiled by tcc.
#
# The first real shell here.  kaem can run a program and substitute a
# variable; everything above this point is built by ./configure scripts, which
# need a shell with variables, loops, conditionals and pipelines.
#
# sh is a copy rather than a symlink: a store path is read-only by the time
# anything would follow it, and copying costs nothing at this size.
{
  derivationWithMeta,
  system,
  platforms,
  stage0,
  tinycc,
  gnumake,
  gnupatch,
  mesInclude,
}:
let
  pname = "bash";
  version = "2.05b";

  fetchurl = import <nix/fetchurl.nix>;

  # live-bootstrap, at the revision nixpkgs' minimal bootstrap pins for bash.
  liveBootstrap = "https://raw.githubusercontent.com/fosslinux/live-bootstrap/c0494d9af84b9e8c3e76e34c6e898978013a3b39/steps/bash-2.05b";

  fetchLiveBootstrap =
    { file, sha256 }:
    fetchurl {
      url = "${liveBootstrap}/${file}";
      name = baseNameOf file;
      inherit sha256;
    };
in
derivationWithMeta {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/bash/bash-${version}.tar.gz";
    sha256 = "ba03d412998cc54bd0b0f2d6c32100967d3137098affdc2d32e6e7c11b163fe4";
  };

  mainmk = fetchLiveBootstrap {
    file = "mk/main.mk";
    sha256 = "448256e3a448718a3beddd24ed44dffe2cead2de77768dc205670c7c074e4242";
  };
  commonmk = fetchLiveBootstrap {
    file = "mk/common.mk";
    sha256 = "f41cd424fcfa571fabebd8b649096a4531fd8a180b694a752526069536d65aef";
  };
  builtinsmk = fetchLiveBootstrap {
    file = "mk/builtins.mk";
    sha256 = "92229aefd9ecb6a159cc4cac0bb3740994f9a81d861b297575b007bf8a6f6924";
  };

  # No locale support in this C library.
  patch1 = fetchLiveBootstrap {
    file = "patches/mes-libc.patch";
    sha256 = "5f043b3d5b685ecb8edb6d9ea51e84d01c1f86c1f49a8721b963ad6f9c6c7a7e";
  };
  # bash declares a struct field one way and this C library another, so the
  # declaration is made to match.
  patch2 = fetchLiveBootstrap {
    file = "patches/tinycc.patch";
    sha256 = "42b227f35ed4b8ab0656a7a4394aaec466677287775318e657742245f2144d10";
  };
  patch3 = fetchLiveBootstrap {
    file = "patches/missing-defines.patch";
    sha256 = "444e8b8f811e85616986bb5aee83876315554e29711e4f319e72e75ae40c13e0";
  };
  patch4 = fetchLiveBootstrap {
    file = "patches/locale.patch";
    sha256 = "a92f6bf73f7c350afb5a2cb6d31d7705fb6c60b2b781493a924f3b05a90e38dc";
  };
  # There is no /dev yet, so nothing can open /dev/tty.
  patch5 = fetchLiveBootstrap {
    file = "patches/dev-tty.patch";
    sha256 = "499632e597a3de7ef0359e04de0d68bc076795a792bceeb154f11f5736d5258c";
  };

  # One argument each: kaem substitutes a variable whole.  See the script for
  # why AR is named rather than looked up.
  ccflag = "CC=${tinycc.compiler}/bin/tcc -static -B ${tinycc.libs}/lib -I ${mesInclude}";
  arflag = "AR=${tinycc.compiler}/bin/tcc -ar";

  # See the script: this tcc's -ar takes no flag cluster.
  arPattern = "$(AR) cr $@ $^";
  arReplacement = "$(AR) $@ $^";

  bin_make = "${gnumake}/bin/make";
  bin_replace = stage0.mescc-tools-extra.replace;
  bin_patch = "${gnupatch}/bin/patch";
  bin_ungz = stage0.mescc-tools-extra.ungz;
  bin_untar = stage0.mescc-tools-extra.untar;
  bin_catm = stage0.mescc-tools-extra.catm;
  bin_cp = stage0.mescc-tools-extra.cp;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;
  bin_chmod = stage0.mescc-tools-extra.chmod;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "GNU Bourne-Again Shell, the de facto standard shell";
    homepage = "https://www.gnu.org/software/bash";
    license = "gpl3Plus";
    inherit platforms;
  };
}
