/* config.h.  Generated from config.in by configure. -- for libdecnumber,
   a genuinely missed generated header: dconfig.h's own #include "config.h"
   (the non-IN_LIBGCC2 branch, the one every host-side .c file in this
   directory takes) needs its own, separate config.h, the same category
   as gmp/mpc/libcpp's own separate config.h files (92feaf0) -- just not
   caught until an actual build attempt tried to compile decNumber.c and
   hit "include file 'config.h' not found". Real, off-chain reference
   build/libdecnumber/config.h (897e2c8/537e2c8's same off-chain
   --target=i686-pc-mingw32 run), audited line-by-line against ntlibc's
   real headers the same way as every other config.h in this package. */
/* config.in.  Generated from configure.ac by autoheader.  */

/* Define if building universal (internal helper macro) */
/* #undef AC_APPLE_UNIVERSAL_BUILD */

/* Define to 1 if you have the <ctype.h> header file. */
#define HAVE_CTYPE_H 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the <memory.h> header file. */
/* ntlibc audit: undef -- no <memory.h> in ntlibc/include (glibc-specific;
   this directory's own C files never use it directly regardless -- same
   HAVE_MEMORY_H gap every other config.h in this package already found). */
/* #undef HAVE_MEMORY_H */

/* Define to 1 if you have the <stddef.h> header file. */
#define HAVE_STDDEF_H 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdio.h> header file. */
#define HAVE_STDIO_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "gcc-bugs@gcc.gnu.org"

/* Define to the full name of this package. */
#define PACKAGE_NAME "libdecnumber"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "libdecnumber  "

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "libdecnumber"

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION " "

/* The size of `char', as computed by sizeof. */
/* #undef SIZEOF_CHAR */

/* The size of `int', as computed by sizeof. */
#define SIZEOF_INT 4

/* The size of `long', as computed by sizeof. */
/* ntlibc audit: 4, not 8 -- this is a 32-bit target (i686-pc-pe), not the
   64-bit Linux host configure ran on. Same ILP32 correction every other
   config.h in this package already made (cb7942f, 92feaf0). */
#define SIZEOF_LONG 4

/* The size of `short', as computed by sizeof. */
/* #undef SIZEOF_SHORT */

/* The size of `void *', as computed by sizeof. */
/* #undef SIZEOF_VOID_P */

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Define WORDS_BIGENDIAN to 1 if your processor stores words with the most
   significant byte first (like Motorola and SPARC, unlike Intel). */
#if defined AC_APPLE_UNIVERSAL_BUILD
# if defined __BIG_ENDIAN__
#  define WORDS_BIGENDIAN 1
# endif
#else
# ifndef WORDS_BIGENDIAN
/* #  undef WORDS_BIGENDIAN */
# endif
#endif

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to `long int' if <sys/types.h> does not define. */
/* #undef off_t */
