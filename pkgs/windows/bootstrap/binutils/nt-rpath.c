/* ntlibc's dynamic loader (include/ntlibc/rpath.h) resolves a relative DLL
 * dependency against the directories an executable names in its own
 * __rpath array -- the executable defines the symbol, ntlibc's loader code
 * only references it.  bfd/plugin.c calls dlopen() (for -plugin support,
 * unused here but pulled in unconditionally by elflink.c), so every
 * program built by this package needs to provide the symbol like any other
 * ntlibc program that touches dlopen.  Empty: this build never loads a
 * plugin, so there is nothing to search for relative to the executable.
 */
const char *const __rpath[] = { 0 };
