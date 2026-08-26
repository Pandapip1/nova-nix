# The stdenv every ordinary package is built with: this chain's own final
# compiler, this chain's own userland, and mkStdenv's generic phase runner.
#
# There is exactly ONE setup.sh (mk/mkStdenv/setup.sh) and it serves both
# platforms.  Windows does need a good deal that Linux does not -- a native
# cc-wrapper, bare-name/.exe tool shims, a PATH two different parsers can
# both read -- but all of it lives in that one script behind a
# `$windowsStdenv' gate, and everything below is just the data that gate
# needs.  See setup.sh's own "Windows execution environment" section for why
# each item exists; every one of them was found by driving the real binaries.
{
  mkStdenv,
  platform,
  isWindows,
  buildTriple,
  hostTriple,
  targetTriple,
  stage0,
  stage1,
  stage2,
  stage3,
  gcc,
  updateAutotoolsGnuConfigScriptsHook,
}:
let
  executableSuffix = stage0.executableSuffix;

  # --- Windows only, from here to `windowsSetupEnv' -------------------------
  # Nothing in this block is forced on Linux: it is reached only through
  # `windowsSetupEnv', which is selected by `isWindows' below.

  # The same tcc every earlier package on this side of the tree was built
  # with -- st/stage3/.../gcc_4_6_4/windows/default.nix names the identical
  # `tinycc.boot.tcc'.  cc-wrapper.c drives it directly for the assemble and
  # link steps this chain's gcc.exe cannot do itself.
  tcc = stage1.tinycc-mes.boot.tcc;

  # ntlibc's own source tree, not just its install prefix: cc-wrapper links
  # against the installed lib/ but compiles against the source include/ and
  # arch/ directories, exactly as st/stage2/.../ntlibc's own build does.
  ntlibcSrc = (import ../stage2/by-name/nt/ntlibc/bootstrap-sources.nix { }).src;

  # gcc's own build.kaem installs cc1.exe/gcc.exe/as.exe under this
  # exec-prefix; libgcc.a (the DImode helper subset it builds and archives,
  # needed by any consumer whose codegen wants 64-bit arithmetic) lives
  # alongside them, and cc-wrapper puts it on every link line.
  gccLibDir = "${gcc}/lib/gcc/i686-pc-pe/4.6.4";

  windowsSetupEnv = {
    windowsStdenv = "1";
    # Excluded from the tool-shim sweep: "gcc"/"cc" get the cc-wrapper, not a
    # bare pass-through alias to the real driver.
    compilerBin = "${gcc}/bin";
    # stage0's own mescc-tools-extra unxz -- a single binary, not a bin dir.
    # It is the only xz decompressor anywhere in this chain's Windows
    # userland (gzip is a real from-source build; nothing built an xz), and
    # it carries a truncation bug setup.sh's unpack phase works around.
    unxzBin = "${stage0.mescc-tools-extra.unxz}";

    ccWrapperSrc = ./windows/cc-wrapper.c;
    NN_TCC = "${tcc}";
    NN_GCC = "${gcc}/bin";
    NN_GCC_LIBDIR = gccLibDir;
    NN_NTLIBC_LIB = "${stage3.libc}/lib";
    NN_NTLIBC_INCLUDE = "${stage3.libc}/include";
    NN_NTLIBC_SRC_INCLUDE = "${ntlibcSrc}/include";
    NN_NTLIBC_ARCH_I386 = "${ntlibcSrc}/arch/i386";
    NN_NTLIBC_ARCH_GENERIC = "${ntlibcSrc}/arch/generic";
  };
in
mkStdenv {
  inherit
    platform
    isWindows
    buildTriple
    hostTriple
    targetTriple
    ;
  inherit (stage0) system platforms;
  inherit (stage1) bash;
  libc = stage3.libc;
  compiler = gcc;
  ccCommand = "${gcc}/bin/gcc${executableSuffix}";
  arCommand = "${stage2.binutils}/bin/ar${executableSuffix}";

  # config.guess CANNOT work on this chain's Windows side, so there is
  # nothing for the hook to usefully refresh, and the hook's own builder
  # (`${bash}/bin/bash') is a name the Windows bash does not install.  Its
  # whole first act is
  #   UNAME_MACHINE=`(uname -m) 2>/dev/null` || UNAME_MACHINE=unknown
  #   ... UNAME_RELEASE / UNAME_SYSTEM / UNAME_VERSION, the same way
  # and this chain's coreutils 5.0 builds no `uname' AT ALL -- nor `date'.
  # Measured, not assumed: its bin/ has 62 entries and neither name is among
  # them, because live-bootstrap's own main.mk, which coreutils/windows's
  # build.kaem drives instead of a ./configure, does not build them.  All
  # four probes come back "unknown", no case matches, and config.guess falls
  # into a diagnostic dump that shells out to the HARDCODED HOST ABSOLUTE
  # PATHS /bin/uname -X and /usr/bin/arch -k -- which is exactly where the
  # build log's "/bin/uname: invalid option -- 'X'" came from.  --build (see
  # mkStdenv's own configurePlatforms) is the honest answer instead: this
  # stdenv builds for exactly one platform.
  updateAutotoolsGnuConfigScriptsHook =
    if isWindows then null else updateAutotoolsGnuConfigScriptsHook;

  setupEnv = if isWindows then windowsSetupEnv else { };

  tools = [
    stage1.bash
    gcc
    stage2.binutils
    stage2.coreutils
    stage2.diffutils
    stage2.findutils
    stage2.gawk5
    stage2.gnugrep
    stage2.gnumake
    stage2.gnupatch
    stage2.gnused
    stage3.gnutar
    stage2.gzip
  ];
}
