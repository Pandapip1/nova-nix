# GNU coreutils 5.0, compiled by tcc.
#
# The programs every build script above assumes: cp, mv, rm, mkdir, cat, echo,
# sort, and the rest.  bash is the next step up and cannot be built without
# them.
#
# The makefile and the patches come from live-bootstrap, which did the work of
# finding out what this version needs to compile against a C library this
# small.  They are fetched and pinned rather than copied, so what is built is
# what that project publishes.
{
  stdenv,
  system,
  platforms,
  stage0,
  tinycc,
  gnumake,
  gnupatch,
  mesInclude,
}:
let
  pname = "bootstrap-coreutils";
  version = "5.0";

  fetchurl = import <nix/fetchurl.nix>;

  # live-bootstrap, at the revision nixpkgs' minimal bootstrap pins for this
  # same package.
  liveBootstrap = "https://raw.githubusercontent.com/fosslinux/live-bootstrap/a8752029f60217a5c41c548b16f5cdd2a1a0e0db/sysa/coreutils-5.0";

  fetchLiveBootstrap =
    { file, sha256 }:
    fetchurl {
      url = "${liveBootstrap}/${file}";
      name = baseNameOf file;
      inherit sha256;
    };
in
stdenv.mkDerivation {
  inherit pname version system;

  tarball = fetchurl {
    url = "https://ftp.gnu.org/gnu/coreutils/coreutils-${version}.tar.gz";
    sha256 = "c27ce75e3f62455f4facf4f3fd55bc9e3877d0ab1d5c0426c94da168cc349883";
  };

  makefile = fetchLiveBootstrap {
    file = "mk/main.mk";
    sha256 = "cdd19bf9679b3aa458e57d5b417aabce5268e0d1142d5a33d519bbce58274f5a";
  };

  # modechange.h uses what sys/stat.h declares, so it has to come after it.
  patch1 = fetchLiveBootstrap {
    file = "patches/modechange.patch";
    sha256 = "45d7715332f34e8ff160d0f37e7bb67d2bfcdb441062a3fbd0d26bc18b22aa13";
  };
  # mbstate_t is required and the Mes C library does not define it.
  patch2 = fetchLiveBootstrap {
    file = "patches/mbstate.patch";
    sha256 = "7e8fc2d85d0dce51adb95fa24305bdb2be13075a07e95e08d9b23fea3460e367";
  };
  # strcoll does not exist here; ls compares with strcmp instead.
  patch3 = fetchLiveBootstrap {
    file = "patches/ls-strcmp.patch";
    sha256 = "e696424da32d9002ae53bebfb41de57815eb2770d2e4b598dd6be0aec9cfa853";
  };
  # getdate.c is shipped pre-generated: there is no bison yet, and a modern
  # one does not produce something this compiles.
  patch4 = fetchLiveBootstrap {
    file = "patches/touch-getdate.patch";
    sha256 = "aa12123cff7d49657519a39d282f2ad7d3df595a10d8a237ca47ce4d4ff9a3f5";
  };
  patch5 = fetchLiveBootstrap {
    file = "patches/touch-dereference.patch";
    sha256 = "aa39da75c7646f44d293cc56bfea639a1df63be6cc9b679ce71d0930472e7e72";
  };
  patch6 = fetchLiveBootstrap {
    file = "patches/expr-strcmp.patch";
    sha256 = "49a5719c0cc5a072e34fff79972f18873c5ce949db3b71f7c73c86aa1d0dc3a5";
  };
  # strcoll again, and hard_LC_COLLATE is used without being declared when
  # HAVE_SETLOCALE is unset.
  patch7 = fetchLiveBootstrap {
    file = "patches/sort-locale.patch";
    sha256 = "cc44a1c0873074c6ba6ff8c7103275e9aa4b1607da61ff0cf5ddfb5b5180ac2d";
  };
  # uniq assumed fopen could not return stdin or stdout.
  patch8 = fetchLiveBootstrap {
    file = "patches/uniq-fopen.patch";
    sha256 = "d70db37f1f8cc36702e1bf43d12475f2919cfb7dbac8b2c9804426da3dd44663";
  };

  # One argument, because kaem substitutes a variable whole.
  #
  # Mes's headers come ahead of tcc's own: both define size_t and they
  # disagree -- unsigned long against unsigned int -- so whichever is found
  # second is a redefinition and the compile stops.  Mes's win, because this
  # is compiled against Mes's C library.
  ccflag = "CC=${tinycc.compiler}/bin/tcc -static -B ${tinycc.libs}/lib -I ${mesInclude}";

  # AR has to be given too, and for a sharper reason than tidiness: the
  # makefile defaults it to a bare `tcc -ar`, which finds whatever tcc is on
  # PATH.  On a machine that has one installed -- a 64-bit one, as most are --
  # the archive step reads this bootstrap's 32-bit objects with the host's
  # compiler and stops with "Unsupported Elf Class", naming a file that is
  # perfectly valid.  Naming the compiler leaves nothing to look up.
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
  bin_rm = stage0.mescc-tools-extra.rm;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "GNU core utilities";
    homepage = "https://www.gnu.org/software/coreutils";
    license = "gpl3Plus";
    inherit platforms;
  };
}
