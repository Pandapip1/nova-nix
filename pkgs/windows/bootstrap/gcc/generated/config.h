#ifndef GCC_CONFIG_H
#define GCC_CONFIG_H
#ifdef GENERATOR_FILE
#error config.h is for the host, not build, machine.
#endif
#include "auto-host.h"
#ifdef IN_GCC
# include "ansidecl.h"
/* nova-nix Windows bootstrap: the off-chain reference run this file was
   otherwise vendored from (896d3ea) used --host=--build=x86_64-linux
   (deliberately, to get real target-derived generated/ output -- see
   that commit), so its own config.h correctly has no host_xm_file
   inclusion for a native Linux host. This chain's REAL host is
   i686-pc-pe (gcc.exe/cc1.exe both run under wine, on the same PE
   target this whole bootstrap targets) -- config.gcc's own
   `i[34567]86-*-mingw*` stanza (config.gcc:1489, the exact stanza that
   already supplies generated/tm.h's own tm_file list, confirmed in
   9386c7c) would set host_xm_file the same way it sets the target's
   xm_file: i386/xm-mingw32.h -- pulling in HOST_EXECUTABLE_SUFFIX
   (".exe"), without which gcc.c's own find_a_file search for its
   sibling cc1 never tries "cc1.exe", only the un-suffixed "cc1", which
   execvp on this host cannot find (found directly: gcc.exe genuinely
   locates cc1's directory via -B/exec-prefix search, per gcc.c's own
   add_prefix calls, but still fails execvp with "No such file or
   directory" without this).

   The real xm-mingw32.h is NOT included wholesale here, though: it also
   sets PATH_SEPARATOR to ';' (this environment's real $PATH/
   $COMPILER_PATH/$LIBRARY_PATH values, produced by this project's own
   nix-style tooling, use ':' -- ntlibc is a POSIX layer, not a real
   Win32 environment with Win32-convention env vars) and
   HOST_LONG_LONG_FORMAT "I64" (an MSVC printf extension ntlibc's own
   real printf, checked directly, does not implement -- would corrupt
   every HOST_WIDE_INT diagnostic message gcc.c ever prints). Only the
   one macro this bootstrap actually needs is defined here, narrowly,
   rather than trusting the whole header's worth of real-Win32-hosted
   assumptions this chain does not share. */
# define HOST_EXECUTABLE_SUFFIX ".exe"
#endif
#endif /* GCC_CONFIG_H */
