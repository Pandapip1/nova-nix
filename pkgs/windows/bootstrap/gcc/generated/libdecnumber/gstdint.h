/* generated for  gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0 */
/* Vendored unchanged from the off-chain reference build's real
   build/libdecnumber/gstdint.h -- libdecnumber/configure.ac's
   GCC_HEADER_STDINT(gstdint.h) macro produces this file, and its own
   content turns out to be host-generic, not host-answer-sensitive: it
   is just `#include <stdint.h>` (which ntlibc/include/stdint.h really
   provides) guarded by glibc-specific __int8_t_defined/__uint32_t_defined
   checks that simply never trigger under ntlibc, falling through to the
   file's own #ifndef fallback branches, which are themselves no-ops
   (defining guard macros nothing else in this file re-checks). No
   host-path leakage, nothing here needs an ntlibc-specific answer -- same
   category as this package's shim/windows.h stub. */

#ifndef GCC_GENERATED_STDINT_H
#define GCC_GENERATED_STDINT_H 1

#include <sys/types.h>
#include <stdint.h>
/* glibc uses these symbols as guards to prevent redefinitions.  */
#ifdef __int8_t_defined
#define _INT8_T
#define _INT16_T
#define _INT32_T
#endif
#ifdef __uint32_t_defined
#define _UINT32_T
#endif


/* Some systems have guard macros to prevent redefinitions, define them.  */
#ifndef _INT8_T
#define _INT8_T
#endif
#ifndef _INT16_T
#define _INT16_T
#endif
#ifndef _INT32_T
#define _INT32_T
#endif
#ifndef _UINT8_T
#define _UINT8_T
#endif
#ifndef _UINT16_T
#define _UINT16_T
#endif
#ifndef _UINT32_T
#define _UINT32_T
#endif

/* system headers have good uint64_t and int64_t */
#ifndef _INT64_T
#define _INT64_T
#endif
#ifndef _UINT64_T
#define _UINT64_T
#endif

#endif /* GCC_GENERATED_STDINT_H */
