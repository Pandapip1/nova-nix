# kaem: the shell the rest of the bootstrap is written for.
#
# Not part of the chain.  stage0-pe32 has cmd.exe to sequence its own build and
# needs no shell of its own, which is why upstream's README says there may
# never be a kaem here.  nova-nix has no cmd.exe: a derivation is one program
# with one argument list, and anything whose output is a directory rather than
# a file -- a library, a compiler's bin/ -- needs something that can run mkdir
# and then thirteen cp's.  On Linux that is kaem, and the scripts it runs are
# shared with this side, so it had better be kaem here too.
#
# kaem cannot fork on Windows.  It does not have to: it carries exactly one
# #ifdef for a system that cannot -- written for UEFI, which cannot either --
# and that branch calls spawn(), which starts a program and waits for it in
# one step.  M2libc's Windows target offers spawn() under that name, and kaem's
# #ifdef names __windows__ beside __uefi__.  Both changes are two lines and
# both are in the forks stage0-pe32 pins.
#
# Why not fork: Windows has RtlCloneUserProcess, and the child it makes never
# reaches its first instruction -- it deadlocks on an SRW lock the parent held
# across the clone.  M2libc's fork() returns -1 rather than handing back a
# child handle for something that will never run.  stage0-pe32's README has
# the measurements.
{
  callPackage,
  src,
  m2-program,
}:
m2-program.program "kaem" (
  m2-program.libcSources
  ++ [
    "-f"
    "${src}/mescc-tools/Kaem/kaem.h"
    "-f"
    "${src}/mescc-tools/Kaem/variable.c"
    "-f"
    "${src}/mescc-tools/Kaem/kaem_globals.c"
    "-f"
    "${src}/mescc-tools/Kaem/kaem.c"
  ]
)
