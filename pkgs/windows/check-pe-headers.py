# Refuse a PE image that Windows would refuse to load.
#
# Static header inspection, deliberately: every gate in this project runs
# under wine, and wine LOADS THE IMAGES WINDOWS REFUSES.  A launch test --
# even one that runs every binary we build -- is structurally incapable of
# catching this.  So this reads the header and decides, rather than asking
# a loader that has been measured to disagree with the one that matters.
#
# The constraint that matters, measured on Windows 11 Pro 22621 by building
# five header variants of the same program and launching each on the real
# loader (not inferred from the PE/COFF spec, which predicted neither result):
#
#   * SectionAlignment BELOW the page size -- 0x200 with FileAlignment
#     matching, which the spec EXPLICITLY PERMITS -- is rejected outright
#     with ERROR_BAD_EXE_FORMAT (193), whatever else the header says.
#     wine loads these without complaint.
#
#   * SectionAlignment = 0x1000 loads and runs EVEN WHEN SizeOfRawData is
#     not a multiple of FileAlignment, which the spec says it MUST be.
#     ReactOS disables exactly that check in ntoskrnl/mm/section.c: "Yes,
#     this should be a multiple of FileAlignment, but there's stuff out
#     there that isn't.  We can cope with that."
#
# So the spec's normative wording predicted the behaviour in NEITHER
# direction: the permitted thing is rejected and the required thing is not
# enforced.  This file encodes what was measured, and deliberately does NOT
# check SizeOfRawData alignment -- enforcing that would reject images the
# real loader accepts.
#
# Why this guard exists at all, given every binary currently passes: the
# bottom of this chain writes PE headers BY HAND.  stage0-pe32's hex2 has no
# section or bss concept -- the header is literal hex and everything past the
# file's real content is zero-filled address space divided up by hand.  There
# is no compiler backend upstream of it to apply a sane convention.  A
# one-character edit there yields a SEED that wine runs happily and Windows
# cannot launch, and because one convention propagates through the whole
# chain, every stage above would inherit the shape without a single test
# failing.  The uniformity of the current output is the reason to assert it,
# not a reason to skip it.

import struct
import sys
import os

PAGE = 0x1000

# i386 PE32.  This chain is 32-bit throughout; a 64-bit image here means
# something is targeting the wrong machine, not that the check needs relaxing.
WANT_MACHINE = 0x014C  # IMAGE_FILE_MACHINE_I386
WANT_MAGIC = 0x010B  # PE32 (0x020B would be PE32+)


def check(path):
    """Return a list of complaints; empty means the image is fine."""
    with open(path, "rb") as fh:
        data = fh.read()

    if len(data) < 0x40 or data[:2] != b"MZ":
        return ["not a PE image (no MZ signature)"]

    pe = struct.unpack_from("<I", data, 0x3C)[0]
    if pe + 24 > len(data) or data[pe : pe + 4] != b"PE\0\0":
        return ["not a PE image (no PE signature)"]

    machine = struct.unpack_from("<H", data, pe + 4)[0]
    magic = struct.unpack_from("<H", data, pe + 24)[0]

    bad = []
    if machine != WANT_MACHINE:
        bad.append("machine is %#06x, want %#06x (i386)" % (machine, WANT_MACHINE))
    if magic != WANT_MAGIC:
        bad.append("optional-header magic is %#06x, want %#06x (PE32)" % (magic, WANT_MAGIC))

    # SectionAlignment and FileAlignment sit at fixed offsets in the optional
    # header, before the part that differs between PE32 and PE32+.
    sect_align = struct.unpack_from("<I", data, pe + 24 + 32)[0]
    file_align = struct.unpack_from("<I", data, pe + 24 + 36)[0]

    if sect_align < PAGE:
        bad.append(
            "SectionAlignment is %#x, below the %#x page size -- the real loader "
            "rejects this with ERROR_BAD_EXE_FORMAT even though the PE spec "
            "permits it, and wine loads it anyway" % (sect_align, PAGE)
        )
    if sect_align < file_align:
        bad.append(
            "SectionAlignment %#x is below FileAlignment %#x" % (sect_align, file_align)
        )

    return bad


def main(argv):
    paths = []
    for arg in argv:
        if os.path.isdir(arg):
            for root, _dirs, names in os.walk(arg):
                for name in names:
                    p = os.path.join(root, name)
                    if os.path.isfile(p):
                        with open(p, "rb") as fh:
                            if fh.read(2) == b"MZ":
                                paths.append(p)
        else:
            paths.append(arg)

    if not paths:
        sys.stderr.write("check-pe-headers: no PE images found in %s\n" % " ".join(argv))
        return 1

    failed = 0
    for p in sorted(paths):
        bad = check(p)
        if bad:
            failed += 1
            sys.stderr.write("FAIL %s\n" % p)
            for b in bad:
                sys.stderr.write("       %s\n" % b)

    sys.stdout.write(
        "check-pe-headers: %d image(s) checked, %d rejected\n" % (len(paths), failed)
    )
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
