/* ntlibc's dynamic loader (include/ntlibc/rpath.h) resolves a relative DLL
 * dependency against the directories an executable names in its own
 * __rpath array -- the executable defines the symbol, ntlibc's loader code
 * only references it. gcc/plugin.c calls dlopen() (for real GCC plugin
 * support -- this bootstrap never loads one, but plugin.c is a real,
 * unconditional member of cc1's own libbackend.a, see generated/
 * cc1-link.txt), so cc1.exe needs to provide the symbol like any other
 * ntlibc program that touches dlopen -- byte-for-byte the same fix and the
 * same reasoning as ../binutils/nt-rpath.c (its own bfd/plugin.c has the
 * identical unconditional-dlopen shape), just this package's own copy, per
 * this project's "package-owned even when byte-identical" idiom (see that
 * package's own shim/fnmatch.h). Empty: this build never loads a plugin,
 * so there is nothing to search for relative to the executable.
 */
const char *const __rpath[] = { 0 };
