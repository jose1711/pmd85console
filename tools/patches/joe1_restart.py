#!/usr/bin/env python3
"""JOE1 (R&I 1992, BASIC): after a collision with a gardener the game restarts by itself.

The original lines 82 and 88 jump with `IF X=Q AND Y=W THEN 962` to a line that does not exist in the program (the numbers on the
tape are 960 and 964). BASIC-G then stops silently (no error message, no OK) and the player is left at a prompt. The introduction of
the game says that a gardener ends the game, so the intended jump was to the end of the game (the lines 950 to 970).

The patch keeps the length of every line (no pointers change):
  - `THEN 962` -> `THEN 970` in the lines 82 and 88,
  - the token END of the line 970 -> the token RUN (the game starts again from the beginning; the answer "no" of the line 964, which
    ended the program with END, restarts it as well).
The data checksum (the sum of the data bytes modulo 256, the byte after the data) is updated.

  joe1_restart.py <input tape> <output tape> [--test]
  --test  makes the condition of the line 82 always true (X=X AND Y=Y), to see the restart without meeting a gardener.
"""
import re, sys

def patch(d, test=False):
    d = bytearray(d)
    hdr = 0x30                                   # the leader of 48 bytes, then the 15 bytes of the header
    ln = d[hdr + 4] | (d[hdr + 5] << 8)          # length of the data - 1
    start, end = hdr + 15, hdr + 15 + ln + 1
    assert sum(d[hdr:hdr + 14]) & 255 == d[hdr + 14], 'header checksum'
    assert sum(d[start:end]) & 255 == d[end], 'data checksum before the patch'
    hits = [m.start() for m in re.finditer(b'962', bytes(d[start:end]))]
    assert len(hits) == 2, 'expected the number 962 twice, found %d' % len(hits)
    for h in hits:
        d[start + h:start + h + 3] = b'970'
    # The line 970 (END): walk the chain of the lines from the start (each line is ptr(2), number(2), tokens, 0; ptr is the address of the
    # next line, the program starts at the address in the header), as BASIC does. The tape has several records numbered 970 behind
    # each other (the program was edited); BASIC executes the first one of the chain, not the last one in the file.
    base = d[hdr + 2] | (d[hdr + 3] << 8)
    off = start
    found = None
    while off + 4 < end:
        ptr = d[off] | (d[off + 1] << 8)
        num = d[off + 2] | (d[off + 3] << 8)
        if ptr == 0:
            break
        if num == 970 and found is None:
            found = off
        nxt = start + (ptr - base)
        assert nxt > off, 'the chain of the lines is broken'
        off = nxt
    assert found is not None and d[found + 4] == 0x80 and d[found + 5] == 0, 'the line 970 END was not found in the chain'
    d[found + 4] = 0x89                          # END -> RUN
    if test:
        a = bytes(d[start:end]).rindex(b'\x00', 0, hits[0])
        rec = start + a + 1
        for k in range(rec, start + hits[0]):
            if d[k] == 0x51: d[k] = 0x58         # Q -> X
            elif d[k] == 0x57: d[k] = 0x59       # W -> Y
    d[end] = sum(d[start:end]) & 255
    return bytes(d)

if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    out = patch(open(args[0], 'rb').read(), '--test' in sys.argv)
    open(args[1], 'wb').write(out)
    print('written', args[1])
