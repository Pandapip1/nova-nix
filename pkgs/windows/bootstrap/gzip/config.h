/* The two target facts about this system that gzip cannot be told on a kaem
 * command line, because kaem has no quoting and both values are character
 * constants containing a backslash or a colon.
 *
 * gzip has no config.h of its own -- it is a 1993 program configured entirely
 * by -D -- so this file is force-included with tcc's -include.  That is the
 * only reason it is a header rather than two more entries in the -D wall in
 * build.kaem.
 *
 * basename() in util.c splits a path on PATH_SEP, then PATH_SEP2, then
 * PATH_SEP3.  Only PATH_SEP is defined by default, and it is '/'.  On this
 * side that is not enough, and the consequence is not cosmetic: gzip picks
 * its MODE out of argv[0] -- main() does progname = basename(argv[0]) and
 * then decompresses if that starts with "un" or "gun", and writes to stdout
 * if it ends in "cat".  The NT loader hands argv[0] over as a full path with
 * backslashes, so without these two a gunzip.exe invoked by absolute path
 * sees progname = "Z:\...\gunzip" and quietly runs as gzip.  Measured, not
 * assumed: the same tree built without this file answers `gunzip n.gz' with
 * "n.gz already has .gz suffix -- unchanged" and exit 2.
 *
 * PATH_SEP3 is ':' for the drive letter.  basename applies it last, to what
 * the backslash split already left, so it only ever trims a leading "Z:" off
 * a bare "Z:name".
 *
 * These are exactly the two lines this port wants out of tailor.h's `#ifdef
 * WIN32' block -- see the head of build.kaem for why the rest of that block
 * is left where it is.
 */

#ifndef GZIP_NOVA_NIX_CONFIG_H
#define GZIP_NOVA_NIX_CONFIG_H

#define PATH_SEP2 '\\'
#define PATH_SEP3 ':'

#endif
