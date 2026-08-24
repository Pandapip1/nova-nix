/* cc1-checksum.c -- package-owned stand-in for gcc's own genchecksum.c
   output.

   Real GCC computes this array by running a real, HOST-executed build
   tool (build/genchecksum, gcc/genchecksum.c) over cc1's own C_OBJS after
   they are compiled, an MD5 digest of cc1's own object code, and links
   the result into cc1 itself as `executable_checksum`. The only consumer
   of that symbol anywhere in this closed source set (grepped gcc/*.c and
   gcc/*.h directly, see this package's own build.kaem generation notes)
   is gcc/c-family/c-pch.c's precompiled-header validation path -- it
   compares a running cc1's own executable_checksum against the one
   stored inside a .gch file to reject a stale PCH. This bootstrap's
   build.kaem never invokes -x c-header/--output-pch (same "dead hook,
   not a real dependency" reasoning already used for gcc/host-default.c's
   PCH address hooks, see 537e2c8), so the actual byte values here are
   never compared against anything -- a fixed, honestly-fake checksum is
   exactly as correct as a freshly computed one for this build, and
   avoids standing up genchecksum as a running (wine-executed) build-time
   tool just to produce a value nothing reads.

   Real genchecksum output is a 16-byte MD5-shaped array; this one is
   deliberately not a real MD5 of anything, to avoid the false impression
   that it is. */

const unsigned char executable_checksum[16] = {
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};
