/* Stub: gcc/config/i386/mingw32.h unconditionally does `#include <windows.h>`
   whenever IN_LIBGCC2 is defined, at file scope, regardless of which L_*
   function libgcc2.c is being compiled for -- see MINGW_ENABLE_EXECUTE_STACK
   right above that include in mingw32.h. Its only use is inside the body of
   the ENABLE_EXECUTE_STACK macro (MEMORY_BASIC_INFORMATION, VirtualQuery,
   VirtualProtect, PAGE_EXECUTE_READWRITE), which is only *expanded* by
   libgcc2.c's own L_enable_execute_stack/L_trampoline sections -- neither of
   which this bootstrap's libgcc needs (no nested functions, no trampolines,
   in a C-only, --disable-libgomp/--disable-lto library). So an empty stub is
   enough for every L_* object this package actually compiles: the macro body
   referencing these names is never instantiated, only defined and discarded.
   ntlibc deliberately has no windows.h of its own (see binutils'
   windows.patch header) -- this is this package's own stub, not ntlibc's. */
#ifndef _WINDOWS_H_GCC_STUB
#define _WINDOWS_H_GCC_STUB
#endif
