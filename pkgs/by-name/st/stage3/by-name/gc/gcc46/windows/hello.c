/* This package's own functional test: a real, ordinary C program (no
   inline asm, no ntdll calls of its own -- unlike ../binutils/hello.s,
   which is freestanding by necessity since it exists to prove as.exe/
   ld.exe against a synthesized import library), compiled by this
   package's own from-scratch cc1.exe, then assembled and linked by this
   chain's own tcc (see build.kaem's own functional-test comment for why
   tcc, not binutils' real as.exe/ld.exe, does that half).

   write()+return, not printf(): keeps the test to one real libc call
   (ntlibc's own write(), a thin wrapper over NtWriteFile) plus normal C
   control flow and a string literal, without also pulling stdio
   buffering/flushing semantics into what this is trying to prove. */

#include <unistd.h>

int
main (void)
{
  const char msg[] = "hello from this chain's own cc1.exe\n";
  write (1, msg, sizeof (msg) - 1);
  return 0;
}
