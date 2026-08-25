/* Functional test for the as+ld+dlltool produced by this package -- see
 * default.nix's "ld against ntlibc: entry point and import libraries".
 *
 * Deliberately freestanding: no ntlibc crt1.o/libc.a. ntlibc's own crt1.o
 * and libc.a turned out (found while building this package, not assumed)
 * to be genuine ELF relocatables -- tcc's internal object format is always
 * ELF regardless of the final output format, checked directly with `file`
 * against ${ntlibc}/lib/crt1.o -- while this package's own as emits real
 * i386 PE/COFF (it has no ELF backend compiled in at all, see default.nix).
 * A real GNU ld cannot mix the two the way tcc's own hybrid PE linker
 * does, so a test that links against ntlibc's *current* crt1.o/libc.a
 * would be testing that ELF/COFF mismatch, not this package's own
 * as/ld/dlltool -- see default.nix's "ntlibc's crt1.o/libc.a are ELF, not
 * COFF" for the full finding. What this test isolates instead is exactly
 * the interface this package exists to prove: as assembling real COFF,
 * and ld consuming a dlltool-synthesized import library the way gcc's own
 * final links eventually will.
 *
 * _start calls NtTerminateProcess(NtCurrentProcess(), 0) directly through
 * the import thunk dlltool built from ntlibc's lib/ntdll.def -- no libc
 * needed at all. NtTerminateProcess(-1, 0) exits the calling process with
 * that pseudo-handle. `dlltool -d lib/ntdll.def -l libntdll.a` (no
 * decoration in the .def -- checked directly) names the thunk
 * "_NtTerminateProcess" (a leading underscore, dlltool's own PE default
 * for an undecorated cdecl-looking name, checked directly with nm on the
 * built libntdll.a) -- not "_NtTerminateProcess@8", the stdcall-decorated
 * name ntlibc's own crt1.c references (a real, separate naming-convention
 * mismatch between what this chain's tcc fork expects and what stock
 * dlltool produces from an undecorated .def -- see default.nix). This
 * file calls the name dlltool actually built. Calling convention is still
 * correct regardless of the name: NtTerminateProcess is genuinely
 * __stdcall in ntdll itself (the callee cleans its own two-argument
 * stack), and dlltool's thunk is a plain `jmp *__imp__NtTerminateProcess`
 * that does not change that -- so no stack cleanup is needed here despite
 * the thunk's own undecorated, cdecl-looking name.
 */
	.text
	.globl _start
_start:
	pushl	$0		/* ExitStatus */
	pushl	$-1		/* ProcessHandle: NtCurrentProcess() pseudo-handle */
	call	_NtTerminateProcess
	/* Not reached -- NtTerminateProcess does not return on success. */
1:
	jmp	1b
