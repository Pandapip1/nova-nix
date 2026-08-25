/* gas's own ./configure writes this file (and obj-format.h, targ-env.h
 * alongside it) as a one-line redirect to the real per-target header,
 * picked from gas/configure.tgt's cpu_type=i386 answer for i[3-7]86 --
 * see that file's own header for why this build runs no ./configure.
 * Content is a pure function of the target string, not of ntlibc, so
 * there is nothing here to audit the way generated/gas-config.h was.
 */
#include "tc-i386.h"
