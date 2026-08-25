# GNU binutils 2.46.0 for Windows: ar, ranlib, nm, objcopy, compiled by the
# tcc this chain built, against ntlibc.
#
# Same tarball, same version, same sha256 as ../../../linux/bootstrap/binutils
# -- this project mirrors the Linux bootstrap's stages, and the target-triple
# question that comment left open (see pkgs/windows/default.nix, the note
# ahead of this package) is settled here: i686-pc-pe, not i686-pc-mingw32.
# config.bfd, ld/configure.tgt and gas/configure.tgt all treat "pe" and
# "mingw32" as identical synonyms at every selection point, so nothing is
# lost and nothing is claimed about a mingw runtime this chain does not have.
#
# as, ld and dlltool: ld/deffilep.c, checked directly against a pristine
# extraction of the release tarball (see the "as/ld generated files" section
# below), turned out to already be shipped pre-built -- bison was never
# actually needed for it, unlike this package's original comment here
# assumed before that was checked. What genuinely is not shipped, and does
# need a real run of genscripts.sh (a shell script, not a bison grammar) on
# an ordinary Linux host, is ld/emultempl/pe.em's per-emulation glue
# (ei386pe.c) and ld/ldscripts/i386pe.x* for the i386pe emulation -- see
# "What generated/ actually is" below for how those two were produced and
# audited, same as bfd's own generated headers were. as needs no generation
# step at all for i386-pe: gas/configure.tgt's `i[3-7]86-*-pe)` stanza picks
# fmt=coff, em=pe, cpu_type=i386, none of which touch a bison/flex grammar
# (config/tc-i386.c is hand-written; the only generated headers tc-i386.c
# needs, opcodes/i386-init.h, opcodes/i386-tbl.h and opcodes/i386-mnem.h,
# are shipped pre-built in the release tarball, checked directly). dlltool
# is included here too -- not because it shares object-format glue with as
# or ld, but because it is what ../../default.nix's "Import libraries" note
# says has to happen "somewhere in the binutils (or ntlibc-consuming)
# package": ld itself cannot resolve `-lntdll` the way this chain's tcc
# fork can (tccpe.c's pe_load_def is a tcc extension; GNU ld's own .def
# support only ever builds an import library for a DLL being created, never
# resolves imports from one), so a real `dlltool -d lib/ntdll.def -l
# libntdll.a` run has to exist before ld is useful for anything that calls
# into ntdll -- and dlltool.c needs nothing beyond binutils/bucomm.c,
# version.c and filemode.c (already built below for ar/ranlib/nm/objcopy)
# plus its own pre-generated defparse.c/deflex.c (also shipped, also
# checked directly), so it is nearly free to add once bfd and libiberty are
# already being built for the other four.
#
# ---------------------------------------------------------------------------
# Why this is a hand-written build.kaem, and not ./configure
#
# bash, sed, grep, gawk, gnumake, coreutils are all built on this chain by
# now (pkgs/windows/default.nix says outright that bash exists so
# "./configure above here" can run), so a configure-driven build is not
# impossible the way it was when gnumake/gawk/gnugrep were built.  It was
# tried in spirit anyway: findutils, the package directly below this one,
# chose not to run its own ./configure for a documented reason -- doing so
# "would have dragged bash, sed, grep, awk, coreutils and make into
# findutils' closure and put some thousands of child processes through an
# exec path that this very package found a bug in" (see
# ../findutils/default.nix).  binutils' real ./configure is that same risk
# multiplied by roughly two orders of magnitude: hundreds of feature-test
# compiles per subdirectory (bfd, libiberty, binutils), each one a child
# process.  Given a package this size already needed hand-auditing every
# HAVE_ answer against ntlibc's real headers (below), running configure
# would not have saved that work -- config.h's answers still had to be
# checked one by one against ntlibc, since a stock Linux configure run
# answers questions this platform answers differently (see generated/, and
# the sizeof/HAVE_MMAP/HAVE_SBRK corrections there) -- while adding the
# exec-storm risk on top.  So: configure was run, but on a real Linux host,
# purely to get its generated OUTPUT (config.h, bfd-in3.h, targmatch.h,
# elf32-target.h, bfdver.h, peigen.c -- none of which the release tarball
# ships pre-built, and none of which need a shell to use once they exist),
# and every answer in the generated/*-config.h files was then re-checked by
# hand against ntlibc's actual headers before being trusted, the same way
# generated/bfd-config.h had HAVE_MMAP, HAVE_MADVISE, HAVE_MPROTECT and the
# SIZEOF_* macros corrected for a target with no <sys/mman.h> and a 32-bit
# `long`.  See "What generated/ actually is" below.
#
# ---------------------------------------------------------------------------
# What generated/ actually is
#
# bfd.h, bfdver.h, elf32-target.h, elf64-target.h, targmatch.h and peigen.c:
# built once by running the real bfd/configure and `make headers` (bfd.h,
# config.h) and a real `make` far enough to generate peigen.c (a sed
# substitution of peXXigen.c, not source) and targmatch.h (built from
# config.bfd's own data by targmatch.sh) on an ordinary Linux host with
# --target=i686-pc-pe.  None of these six files differ by *host* -- they are
# a function of the binutils version and the --target string, not of the
# C library being built against -- so generating them once, off the actual
# binutils build system, and vendoring the result is the same move this
# chain already makes for mes's crt1.M1 (hand-assembled once, copied rather
# than regenerated every build) and for mes's own generated arch headers.
# Regenerating them would need bison (targmatch.h's underlying data needs
# none, but deffilep.c later will) and a full autoconf/automake toolchain
# this chain does not have and a hand-written build.kaem has no way to
# invoke anyway.
#
# The four *-config.h files (bfd, libiberty, binutils, libsframe) are
# different: these DO encode host answers, so the ones from that same
# Linux-host configure run were re-audited by hand against ntlibc's real
# headers before being used, exactly the way build.kaem asserts config.h
# answers for every other package on this side of the chain (see gnumake's
# default.nix/build.kaem for the precedent). What changed from the
# Linux-host answers, and why:
#
#   HAVE_MMAP / USE_MMAP / HAVE_MADVISE / HAVE_MPROTECT   undef'd: no
#     <sys/mman.h> in ntlibc.  bfd's non-mmap path (plain read()) is real
#     and already there.
#   SIZEOF_LONG / SIZEOF_VOID_P   4, not 8: this is a 32-bit target
#     (i386), not the 64-bit Linux host configure ran on.  SIZEOF_OFF_T
#     stays 8 -- ntlibc's off_t is _Int64 unconditionally, not size-of-long.
#   HAVE_FOPEN64 / HAVE_FSEEKO64 / HAVE_FTELLO64 (and their HAVE_DECL_
#     counterparts)   undef'd: these are only real, distinct symbols on a
#     libc with a 32-bit off_t and a large-file-support opt-in.  ntlibc's
#     off_t is always 64-bit, so fopen64 et al are bare #defines behind
#     _LARGEFILE64_SOURCE (include/stdio.h) that this build never sets --
#     asking HAVE_FOPEN64=1 without it makes bfdio.c call a macro that
#     never expands, i.e. an undeclared function.  HAVE_FSEEKO/HAVE_FTELLO
#     (the real, non-64 names) stay 1: ntlibc has both, for real.
#   HAVE_MALLOC_H / HAVE_STDIO_EXT_H / HAVE_X86_SHA1_HW_SUPPORT
#     (libiberty)   undef'd: no <malloc.h> or <stdio_ext.h> in ntlibc
#     (glibc-specific, and nothing here needs either), and the Linux host's
#     probe for hardware SHA1 instructions is a host CPU feature question,
#     not a target one.
#   HAVE_SBRK / HAVE_DECL_SBRK (libiberty)   undef'd: no brk()/sbrk() on
#     NT.  xmalloc.c's own comment already says as much ("Not used for
#     win32 ports other than cygwin32"); libiberty/config.h just had not
#     been told that for real.
#   HAVE_SPAWN_H / HAVE_POSIX_SPAWN / HAVE_POSIX_SPAWNP (libiberty)
#     undef'd: no <spawn.h> in ntlibc.  This is what sends pex-unix.c down
#     its fork()+exec() path instead -- see "pex-win32 vs pex-unix" below.
#   HAVE_BYTESWAP_H and its HAVE_DECL_BSWAP_* (libsframe, via
#     libctf/swap.h)   undef'd: no <byteswap.h>; swap.h's own portable
#     bswap_16/32/64 fallbacks (shift-and-mask, no library call) are what
#     actually get used, on every platform that lacks glibc's header.
#
# ---------------------------------------------------------------------------
# as/ld generated files -- what was actually missing, and what was not
#
# A pristine extraction of the release tarball (not this chain's own
# doubled-then-unxz'd copy -- a plain `tar xf` on a real Linux host, diffed
# byte-for-byte against what is vendored below) shows ld/deffilep.c,
# ld/deffilep.h, ld/ldgram.c/.h and ld/ldlex.c all present and pre-built,
# same as bfd's own bfd-in3.h-derived bfd.h always was implicitly assumed to
# need regenerating -- they do not.  GENERATED_CFILES/GENERATED_HFILES in
# ld/Makefile.in name exactly those files, and a release tarball ships its
# GENERATED_* outputs precisely so a user without bison/flex can still build
# from it. bison was therefore never run for this package; the "as and ld
# are not built here" note this comment used to carry over-stated what
# was missing, and nothing above this point in the file needed correcting
# for it.
#
# What genuinely does not ship pre-built is ld/emultempl/pe.em's
# per-emulation glue and ld/ldscripts/i386pe.x* -- both are produced by
# genscripts.sh, a shell script (no bison involved) that ld/Makefile.am's
# own GENSCRIPTS rule runs against emulparams/i386pe.sh at build time, for
# every emulation the build was configured for. These were generated once,
# off-chain, the same way bfd's headers were: `configure --target=i686-pc-pe
# --disable-libctf` (libctf is skipped outright -- see "Why --disable-libctf"
# below) on an ordinary Linux host, then `make ei386pe.c ei386pe_posix.c` in
# ld/ to force genscripts.sh to run for the one emulation this target
# actually selects (ld/Makefile's own EMULATION_OFILES names only ei386pe.o
# -- ei386pe_posix.c exists in the source tree but nothing here links it,
# checked directly against that Makefile). Neither ei386pe.c nor
# ldscripts/i386pe.x* contains a build-host path (checked by grepping both
# for the build directory and for /nix/store) -- like targmatch.h and
# peigen.c above, these are a function of the binutils version and the
# --target string, not of the host that ran genscripts.sh, with one
# exception: ldscripts/i386pe.x's SEARCH_DIR("/usr/local/i686-pc-pe/lib")
# line is genscripts.sh's default library search path, inherited from the
# generic (unconfigured-prefix) run that produced it. It is inert for this
# chain -- every link this package or its callers perform names -L
# explicitly, and NT has no /usr/local to begin with -- so it is left as
# genscripts.sh actually wrote it rather than hand-edited, the same
# "vendor exactly what the real build produced" rule peigen.c's sed
# substitution already followed.
#
# ld/config.h and gas/config.h (generated/ld-config.h, generated/gas-config.h)
# are the same category as the four *-config.h files above: real host
# answers from that same off-chain configure run, re-audited against
# ntlibc's actual headers before being trusted. gas/config.h needed no
# correction at all -- ntlibc has every header and function gas's own
# configure.ac probes for (strsignal, the st_mtim fields, dlfcn.h; no
# windows.h, no zstd, both correctly answered already). ld/config.h needed
# the same three corrections bfd-config.h did, for the same reason (no
# <sys/mman.h> on ntlibc, so no HAVE_MMAP, and libiberty/xmalloc.c's
# reasoning about sbrk applies equally to ld's own mallinfo/mallinfo2 stats
# hook in ldmain.c -- neither symbol exists in ntlibc, checked directly):
# HAVE_MMAP, HAVE_SYS_MMAN_H, HAVE_MALLINFO and HAVE_MALLINFO2 all undef'd.
# HAVE_MMAP's other use, bfd/plugin.c's <sys/mman.h> include guard, is dead
# code here regardless (see "pex-win32.c vs pex-unix.c" below for the same
# argument about unused dlopen-based plugin support). Every other HAVE_*
# ld's configure answered true -- HAVE_GETRUSAGE, HAVE_WAITPID,
# HAVE_MKSTEMP, HAVE_REALPATH, HAVE_GLOB, HAVE_GETPAGESIZE, HAVE_DECL_ENVIRON,
# HAVE_DECL_STPCPY, HAVE_DECL_STRTOULL -- was checked against ntlibc's real
# headers (sys/wait.h, stdlib.h, glob.h, unistd.h, string.h) and left as-is.
#
# gas needs three more one-line stub headers that a real ./configure would
# also have written with no host-specific content at all -- gas-shim/
# targ-cpu.h, obj-format.h and targ-env.h simply #include tc-i386.h,
# obj-coff.h and te-pe.h respectively, exactly what gas/configure.tgt's
# `i[3-7]86-*-pe)` stanza (fmt=coff, em=pe, cpu_type=i386) answers. These
# are not vendored under generated/ the way ld-config.h is, because unlike
# a *-config.h file there is no host answer in them to audit -- they are a
# pure, deterministic function of the target string, the same reasoning
# shim/fnmatch.h's neighbour nt-rpath.c already applies to package-owned
# (rather than generated-and-audited) files.
#
# Why --disable-libctf: ld/Makefile.am links libctf.la into ld-new
# unconditionally when configured with it (the default), and libctf is a
# whole extra subdirectory (with its own configure, its own generated
# headers) this bootstrap has no need to stand up -- nothing in
# bfd/elf-sframe.c or any file this package actually compiles references
# ENABLE_LIBCTF (checked: grepping every *.c this build.kaem compiles for
# the macro finds nothing), and the existing generated/bfd-config.h and
# generated/binutils-config.h (the latter unusually built *with*
# ENABLE_LIBCTF, from before this package existed to need ld) both confirm
# libctf support was never exercised by ar/ranlib/nm/objcopy either. Passing
# --disable-libctf at generation time is therefore just removing a
# dependency this target was never going to use, not a real difference in
# what gets built -- confirmed by generating both ways and diffing every
# other *-config.h answer, which came back identical except for
# ENABLE_LIBCTF itself.
#
# ---------------------------------------------------------------------------
# pex-win32.c vs pex-unix.c
#
# libiberty ships both: pex-win32.c against real Win32 CreateProcess-family
# APIs (via <windows.h>), pex-win32.c's job pex-unix.c does with
# fork()/vfork()/execvp().  ntlibc is not a port of the Win32 process APIs --
# it is a POSIX layer over NT, with a real fork() (see
# [[fork-cloexec-handle-bug]] for a bug already found and worked around
# elsewhere in this chain) -- so pex-unix.c is the one that actually matches
# what ntlibc offers, and it compiles clean against ntlibc's real fcntl.h/
# unistd.h once HAVE_SPAWN_H is off (above).  pex-win32.c would need
# <windows.h>, which windows.patch already establishes this chain does not
# have and does not want (see its header).  Nothing here calls libiberty's
# pexecute machinery at all -- ar/ranlib/nm/objcopy spawn no children -- so
# this is dead code either way, and pex-unix.c is simply the honest choice
# of dead code to carry.
#
# ---------------------------------------------------------------------------
# The FNM_CASEFOLD shim
#
# libiberty/fnmatch.c (glibc's own GNU fnmatch, built unconditionally by
# libiberty's own Makefile whether or not the host has a working fnmatch)
# uses FNM_CASEFOLD, a GNU extension no POSIX fnmatch.h -- ntlibc's
# included -- declares.  shim/fnmatch.h is byte-for-byte
# ../findutils/shim/fnmatch.h: the same problem, the same fix, already
# reviewed once for that package.  See that file's own header for why the
# bit values are safe to reuse (they agree with ntlibc's for the three
# POSIX flags, checked) and why compiling libiberty/fnmatch.c rather than
# patching ntlibc is the right call (a named object beats an archive
# member; ntlibc's own fnmatch.o, in libc.a, is never pulled into the
# link).  ar/ranlib/nm/objcopy do not call fnmatch themselves -- it is only
# here because libiberty's Makefile builds it unconditionally as part of
# REQUIRED_OFILES, and that file has to compile to be archived.
#
# ---------------------------------------------------------------------------
# ld against ntlibc: entry point and import libraries, now that ld exists
#
# ../../default.nix's own comment (search it for "Entry point" and "Import
# libraries") already worked out both answers before either package could
# actually be built; this package is where they get exercised for real.
#
#   Entry point.  ld's PE emulation (ld/emultempl/pe.em, set_entry_point)
#   defaults to "mainCRTStartup", not the "_start" ntlibc's crt1.c and this
#   chain's tcc fork both use.  build.kaem's own as.exe/ld.exe/dlltool.exe
#   links below still go through tcc, exactly like ar.exe/ranlib.exe/
#   nm.exe/objcopy.exe above -- tcc's own PE linker already names "_start"
#   as its default with no -e needed, so nothing changes for how *this*
#   package links its own four programs. What changes is that ld, once
#   built, is a linker other packages (gcc, eventually) will invoke
#   directly -- and every one of those invocations needs an explicit
#   `-e _start` (or `--entry _start`), unconditionally, because ld's own
#   default does not match ntlibc. Proven below by the functional test,
#   with one correction from what was assumed here before the test was
#   actually run: ntlibc's own crt1.o/libc.a turned out (see "ntlibc's
#   crt1.o/libc.a are ELF, not COFF" below) not to be linkable by a real
#   ld at all, for a reason that has nothing to do with the entry symbol,
#   so the functional test proves `-e _start` against a freestanding
#   object of this package's own instead -- still real ld, still real
#   PE32, still run and observed to exit correctly (via the Wine fork this
#   whole chain already verifies PE32 binaries against, same bar
#   ar.exe/ranlib.exe/nm.exe/objcopy.exe were held to above; see
#   [[win11-vm-testing]] for why that fork and not stock wine).
#
#   Import libraries.  dlltool is built here (see the top-of-file comment)
#   specifically to answer this: `dlltool -d ${ntlibc}/lib/ntdll.def -l
#   libntdll.a` synthesizes a real archive import library from ntlibc's own
#   .def, needing no live ntdll.dll, and the functional test below links
#   against exactly that libntdll.a with the real ld -- not tcc's
#   pe_load_def extension -- proving ld can actually resolve `-lntdll` the
#   way gcc's own final links will need it to. A real naming mismatch
#   turned up doing this, worth recording: ntlibc's own crt1.c (and this
#   chain's tcc) reference ntdll imports by their stdcall-decorated name
#   ("_NtTerminateProcess@8"), but `dlltool -d lib/ntdll.def` -- the .def
#   carries no decoration, checked directly -- names the thunk it builds
#   "_NtTerminateProcess" (dlltool's own default leading-underscore
#   convention for an undecorated entry, checked directly with nm on the
#   built libntdll.a), with no "@8". A real link against a dlltool-built
#   libntdll.a therefore has to call the undecorated name, not the
#   decorated one tcc-compiled code expects; hello.s below does. This is
#   purely a naming question, not a calling-convention one -- the actual
#   ntdll function is genuinely __stdcall regardless of what its thunk is
#   named, so no stack cleanup is needed either way -- but it does mean a
#   real `.o` compiled against ntlibc's own headers (which declare these
#   decorated names) will not link against a plain `dlltool -d
#   lib/ntdll.def` import library as-is; the .def would need per-symbol
#   `NAME@N = REALNAME` decoration added for anything gcc eventually
#   compiles against ntlibc's own headers to resolve correctly through it.
#   Left for whoever adds gcc to this chain, since it is a property of the
#   .def and of ntlibc's own header declarations, not of ld or dlltool.
#
#   dlltool needs no --delay/-y flag for this (see point 3 in
#   ../../default.nix's own comment): an ordinary dlltool-built import
#   library leaves the delay-import
#   directory empty, which is exactly ntlibc's own convention already.
#
# ---------------------------------------------------------------------------
# Does ld itself need patching for ntlibc's delay-load or $ORIGIN rpath?
#
# Asked directly while this package was being built, since both are things
# this chain's tcc fork does that a real ld might not know how to. Checked
# against the actual sources rather than assumed either way:
#
#   Delay-load.  ntlibc's include/ntlibc/rpath.h says outright that
#   -Wl,--delay-all is "the documented interface" now, and
#   include/ntlibc/delayload.h's own header says its hand-authored
#   NTLIBC_DELAY_DLL/_STUB macros are "kept for a tcc without that flag...
#   new code should not reach for them" -- both read at face value, before
#   checking, as ntlibc assuming a real --delay-all landed in this chain's
#   tcc. It did: pkgs/by-name/ti/tinycc-bootstrap/shared/mainline-sources.nix pins
#   github.com/Pandapip1/tinycc.git at 69eed4d3, and that revision's
#   tccpe.c genuinely builds real PE delay-import descriptors (directory
#   entry 13) for -Wl,--delay-all -- pe_build_delay_imports(), checked
#   directly, not the older/unrelated tinycc checkout this investigation
#   first (wrongly) consulted before finding the actual pinned one. Real
#   GNU ld does not need to grow an equivalent of tcc's --delay-all,
#   though, because --delay-all is tcc doing in one linker flag what the
#   standard GNU/mingw toolchain splits into two ordinary steps: dlltool
#   building a delay-import stub library ahead of time
#   (-y/--output-delaylib, binutils/dlltool.c, checked directly -- already
#   built by this package), then ld linking against that stub library the
#   same as any other import library, no different handling required. Both
#   dlltool's delay-import thunks and ntlibc's own delayload2.c call a
#   __delayLoadHelper2 with the same name and calling shape (dlltool.c's
#   own generated asm literally calls "___delayLoadHelper2@8"/
#   "__delayLoadHelper2", checked directly; delayload.h's header says its
#   helper is deliberately named and shaped "matching the role and calling
#   shape of MSVC's __delayLoadHelper2") -- the same industry-standard
#   convention both sides already target, not something this port
#   invented. Whether this actually works end to end (dlltool -y against
#   ntlibc's .def, linked with this package's own ld, run against
#   ntlibc's real delayLoadHelper2) is not tested here -- nothing in this
#   bootstrap chain passes -Wl,--delay-all anywhere yet (checked directly,
#   every build.kaem on this side of the chain), so there is no existing
#   user of delay-load to preserve and nothing currently depends on ld
#   handling it. Left for whoever is first to actually need delay-load
#   through the real ld, not assumed working here.
#
#   $ORIGIN rpath.  include/ntlibc/rpath.h is explicit that this needs no
#   linker cooperation at all: "__rpath... no linker section, no custom PE
#   directory, and nothing for a bare `tcc prog.c -lc` invocation to know
#   about beyond 'define this array if you use this API'" -- it is a plain
#   extern data symbol, resolved by the ordinary linker the same way any
#   other global is, which is exactly what this package's own nt-rpath.c
#   already relies on for every one of its four (now seven) programs (see
#   nt-rpath.c's own header). ld needs no patch for this because there is
#   nothing PE-format-specific about it to patch for -- rpath.h's own
#   header is the source for this, not an inference from how ELF or a.out
#   platforms usually do it.
#
# ---------------------------------------------------------------------------
# ntlibc's crt1.o/libc.a are ELF, not COFF -- found while writing the
# functional test below, not assumed
#
# The first draft of hello.s's functional test linked against
# ${ntlibc}/lib/crt1.o and -lc the way ar/ranlib/nm/objcopy's own build
# already does with tcc. It failed under the real ld with a long list of
# "undefined reference" errors for symbols nm confirms libc.a genuinely
# defines (malloc, write, exit, ...) -- checked with nm --print-armap
# directly, not assumed to be a real gap. `file` on ${ntlibc}/lib/crt1.o
# settled it: "ELF 32-bit LSB relocatable", not COFF. This is tcc's own
# architecture, not a bug -- tinycc's -c output is always its internal ELF
# relocatable format regardless of the final link target; only tcc's own
# PE linker (tccpe.c) reads these ELF relocatables and writes real PE at
# final-link time, a hybrid this project's own tcc fork relies on for
# every -nostdlib link this whole chain has done so far (ar.exe,
# ranlib.exe, nm.exe, objcopy.exe, and this package's own as.exe/ld.exe/
# dlltool.exe, all still linked by tcc, all consuming ntlibc's crt1.o
# without issue for exactly this reason). A real ld's pei-i386/coff-i386
# backend has no equivalent reader for tcc's internal ELF relocatables --
# it links real COFF objects, which is what this package's own as.exe
# produces (obj-coff.c, no ELF backend built into gas at all here) but is
# not what ntlibc's crt1.o/libc.a currently are.
#
# This is not a bug in as, ld or dlltool -- all three work correctly
# against real COFF objects and a real dlltool-built import library, which
# is exactly what the functional test below actually exercises. It is a
# real, separate interface gap between "a real GNU toolchain" and
# "ntlibc's runtime objects as tcc currently builds them", worth recording
# for whoever adds gcc to this chain: gcc's own -c output would be real
# COFF (assembled by this package's own as, the same as hello.s below), so
# gcc-compiled translation units would link against each other and against
# a dlltool-built libntdll.a just fine through this package's ld -- but
# linking a gcc-compiled program against ntlibc's *own* crt1.o/libc.a
# through a real ld will hit this exact mismatch again, unless ntlibc's
# runtime objects are rebuilt through a COFF-emitting compiler (this
# package's own as, once something emits assembly for it to consume) or
# tcc grows a real, non-hybrid COFF object-file writer for -c output. Not
# something to patch around in ld -- ld is behaving correctly; the two
# object formats are genuinely different and BFD is not expected to unify
# them.  Not ntlibc's to fix here either (a read-only, peer-owned package
# from this package's point of view) -- report, don't patch, same rule
# [[ntlibc-coordination]] already states for smaller issues.
{
  derivationWithMeta,
  stage0,
  tinycc,
  ntlibc,
  gnupatch,
  gnutar,
  callPackage,
}:
let
  pname = "binutils";
  version = "2.46.0";
  inherit (stage0) system platforms;
  ntlibcSources = callPackage ../../../nt/ntlibc/bootstrap-sources.nix { };
in
derivationWithMeta {
  inherit pname version system;

  tarball = (import <nix/fetchurl.nix>) {
    url = "https://ftp.gnu.org/gnu/binutils/binutils-${version}.tar.xz";
    sha256 = "d75a94f4d73e7a4086f7513e67e439e8fcdcbb726ffe63f4661744e6256b2cf2";
  };

  tcc = tinycc.boot.tcc;
  patch = "${gnupatch}/bin/patch.exe";
  tar = "${gnutar}/bin/tar.exe";

  # Both halves of ntlibc: the built libraries, and the source tree its
  # headers live in -- only bits/alltypes.h is generated, and that one is
  # in the output beside the libraries. See the ntlibc package.
  inherit ntlibc;
  ntlibcSrc = ntlibcSources.src;

  windowsPatch = ./windows.patch;
  shimFnmatch = ./shim/fnmatch.h;
  ntRpathC = ./nt-rpath.c;

  # See "What generated/ actually is" above.
  genBfdH = ./generated/bfd.h;
  genBfdverH = ./generated/bfdver.h;
  genElf32TargetH = ./generated/elf32-target.h;
  genElf64TargetH = ./generated/elf64-target.h;
  genTargmatchH = ./generated/targmatch.h;
  genPeigenC = ./generated/peigen.c;
  genBfdConfigH = ./generated/bfd-config.h;
  genLibibertyConfigH = ./generated/libiberty-config.h;
  genBinutilsConfigH = ./generated/binutils-config.h;
  genLibsframeConfigH = ./generated/libsframe-config.h;

  # See "as/ld generated files" above.
  genEi386peC = ./generated/ei386pe.c;
  genLdemulListH = ./generated/ldemul-list.h;
  genLdConfigH = ./generated/ld-config.h;
  genGasConfigH = ./generated/gas-config.h;
  genLdscriptsX = ./generated/ldscripts/i386pe.x;
  genLdscriptsXa = ./generated/ldscripts/i386pe.xa;
  genLdscriptsXbn = ./generated/ldscripts/i386pe.xbn;
  genLdscriptsXe = ./generated/ldscripts/i386pe.xe;
  genLdscriptsXer = ./generated/ldscripts/i386pe.xer;
  genLdscriptsXn = ./generated/ldscripts/i386pe.xn;
  genLdscriptsXr = ./generated/ldscripts/i386pe.xr;
  genLdscriptsXu = ./generated/ldscripts/i386pe.xu;

  # See "gas needs three more one-line stub headers" above.
  gasShimTargCpuH = ./gas-shim/targ-cpu.h;
  gasShimObjFormatH = ./gas-shim/obj-format.h;
  gasShimTargEnvH = ./gas-shim/targ-env.h;

  # See "ld against ntlibc: entry point and import libraries" above.
  helloS = ./hello.s;

  # unxz's own doubling bug (see build.kaem) needs catm; the doubled output
  # is then unpacked by real tar, not mescc-tools-extra's untar -- binutils'
  # tarball has several symlinks whose target does not fit in untar's own
  # header field, the same reason the Linux recipe uses GNU tar here too.
  bin_catm = stage0.mescc-tools-extra.catm;
  bin_unxz = stage0.mescc-tools-extra.unxz;
  bin_cp = stage0.mescc-tools-extra.cp;
  bin_mkdir = stage0.mescc-tools-extra.mkdir;

  builder = stage0.kaem;
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];

  meta = {
    description = "Tools for manipulating binaries (ar, ranlib, nm, objcopy, as, ld, dlltool)";
    homepage = "https://www.gnu.org/software/binutils";
    license = "gpl3Plus";
    inherit platforms;
  };
}
