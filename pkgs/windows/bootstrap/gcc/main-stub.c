/* __main: real GCC automatically inserts a call to this function at the
   very start of every compiled `main()` (gcc/libgcc2.c's own L__main
   compile unit, gated `#ifdef L__main`, SYMBOL__MAIN -- checked
   directly), to run static C++/constructor-attribute initializers
   before user code executes.

   The real libgcc2.c implementation needs infrastructure this bootstrap
   does not have: __do_global_ctors walks __CTOR_LIST__/__DTOR_LIST__,
   arrays a real crtbegin.o/crtend.o (or a linker .init/.ctors section)
   populate -- neither exists anywhere in this chain (no crtstuff.o is
   built, no init/ctors section is emitted by any link this bootstrap
   performs). This bootstrap's own scope has always been C-only with no
   language-level static-initializer consumer (no C++, matching
   896d3ea's/9386c7c's own EH-support and libgcc scoping decisions) --
   so unlike the real L__main, this stand-in never has anything to walk.

   A no-op is the honest, narrow answer, not a workaround: every target
   program this bootstrap's own cc1.exe compiles gets a call to __main
   inserted whether or not it uses global constructors (real GCC's own
   unconditional behavior, not something -f flags gate), so __main has
   to exist as a real, linkable symbol regardless -- and for a program
   with no global constructors (this package's own hello.c included),
   doing nothing is exactly correct, not a lossy approximation. A
   program that DOES rely on constructor-attribute functions running
   before main() will silently not get that -- a real, documented gap
   for whoever next wants crtbegin/crtend infrastructure on this chain,
   not something this stub pretends to solve. */

void
__main (void)
{
}
