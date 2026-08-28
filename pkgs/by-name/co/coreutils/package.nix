# Complete GNU coreutils, built by the GCC-backed bootstrap stdenv.  Stage2's
# live-bootstrap makefile intentionally emits only the utilities needed to
# reach this point; this package uses the release's own configure and makefiles
# and becomes the coreutils input of the exported final stdenv.
{
  stdenv-bootstrap,
  fetchurl,
}:
stdenv-bootstrap.mkDerivation {
  pname = "coreutils";
  version = "5.0";

  # These are consumed by Wine before it starts the PE builder.  Keeping its
  # high-volume diagnostics off reduces descriptor pressure during the many
  # tiny Autoconf probes and prevents a failed probe from opening a debugger.
  WINEDEBUG = "-all";
  WINEDLLOVERRIDES = "winedbg.exe=d";

  CONFIG_SITE = ./config.site;
  # GCC 4.6 emits STABS for -g on this PE target, while the bootstrap TCC
  # assembler intentionally supports only the directives needed for normal
  # code generation.  Keep the release build optimized and debug-info free.
  # GCC 4.6's optimized assembly and this bootstrap TCC assembler disagree on
  # the external main symbol: the function body is emitted, but crt1's main
  # relocation is left as `call 0'.  The unoptimized printf and shred objects
  # provide the direct control case and produce valid PE entry paths.
  CFLAGS = "-O0";

  src = fetchurl {
    url = "https://mirrors.kernel.org/gnu/coreutils/coreutils-5.0.tar.gz";
    sha256 = "c27ce75e3f62455f4facf4f3fd55bc9e3877d0ab1d5c0426c94da168cc349883";
  };

  patches = [
    ./no-mount-list.patch
    ./configure-exec-status.patch
    ./portable-localcharset.patch
    ./portable-getopt-mempcpy.patch
    ./portable-regex-mempcpy.patch
    ./portable-opaque-file.patch
    ./portable-printf-char.patch
    ./portable-test-eaccess.patch
    ./portable-stty-winsize.patch
    ./portable-su-password.patch
    ./portable-physmem.patch
    ./portable-md5-rotate.patch
    ./portable-statvfs.patch
    ./gcc46-optimize.patch
  ];

  # Keep the complete program build, but omit tests, generated manuals,
  # translations, and maintainer inputs from cross-bootstrap recursion.
  # The man directory requires help2man and a host /bin/sh; neither is a
  # runtime part of the final stdenv.
  postPatch = ''
    sed -i 's/^SUBDIRS = lib src doc man m4 po tests$/SUBDIRS = lib src/' \
      Makefile.in
  '';

  CONFIG_FILES = "Makefile lib/Makefile src/Makefile";

  # This is the largest GCC-driven build in the bootstrap and can lose one
  # compiler child intermittently.  setup.sh keeps successful objects from
  # two keep-going passes, then requires a clean ordinary make.
  buildRetries = 3;

  # Automake otherwise installs programs through the release's install-sh.
  # The native PE shell can interpret that script, but the script eventually
  # tries to execute /bin/sh directly.  Resolve the just-built native
  # coreutils install to an absolute path before recursive make changes its
  # working directory, and bootstrap its own execute mode before it becomes
  # the program responsible for installing every other executable.
  preInstall = ''
    installProgram="$PWD/src/ginstall.exe"
    chmod +x "$installProgram"
    installFlags="INSTALL_PROGRAM=$installProgram INSTALL_SCRIPT=$installProgram"
  '';

  # Autoconf gives native PE programs their conventional .exe suffix, while
  # the POSIX shell used by stdenv performs exact-name PATH lookup.  setup.sh
  # normally creates both spellings in its private shim directory, but its
  # first mkdir necessarily runs before that directory exists.  Make the final
  # coreutils output directly usable at that bootstrap boundary; keep the .exe
  # originals for ntlibc's Windows-style exec search.
  postInstall = ''
    for program in "$out"/bin/*.exe; do
      cp "$program" "''${program%.exe}"
    done
  '';

  configureFlags = [
    "--disable-nls"
    "--disable-dependency-tracking"
    # GCC accepts prototypes, but this old Automake aggregate probe is another
    # victim of the Windows executor's unreliable tiny compile subprocesses.
    # A real accepted mode keeps U empty, so replacement objects retain their
    # source names (fnmatch.o rather than the nonexistent fnmatch_.o).
    "am_cv_prog_cc_stdc=-std=gnu89"
    # Old Autoconf's aggregate prerequisite-header probe fails on ntlibc and
    # consequently emits replacement macros for types the libc does define.
    # Those macros rewrite ntlibc's own typedef declarations when compiling
    # the real sources.  Record every libc-provided type for which this
    # configure has such a fallback; its generated major_t/minor_t aliases
    # are coreutils-internal and remain untouched.
    "ac_cv_type_uid_t=yes"
    "ac_cv_type_gid_t=yes"
    "ac_cv_type_mode_t=yes"
    "ac_cv_type_off_t=yes"
    "ac_cv_type_pid_t=yes"
    "ac_cv_type_size_t=yes"
    "ac_cv_type_uintmax_t=yes"
    "ac_cv_type_mbstate_t=yes"
    "ac_cv_type_intmax_t=yes"
    "ac_cv_type_ino_t=yes"
    "ac_cv_type_ssize_t=yes"

    # ntlibc's sys/time.h is usable alongside time.h, but the old
    # Autoconf probe can reject the pair after one of its aggregate
    # header checks fails.  Without this, getdate includes sys/time.h
    # alone and sees only an incomplete struct tm.
    "ac_cv_header_time=yes"
    "ac_cv_struct_tm=time.h"

  ];
}
