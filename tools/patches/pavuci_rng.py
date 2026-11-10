#!/usr/bin/env python3
"""PAVUCI (R&I, BASIC with machine code in hex strings): the spiders all walk to the right and stay there.

The "random" routine at 6369 returns the next byte of the memory window 8000-BFFF (the pointer starts at B94B and goes on by one),
so the game takes the uninitialised RAM of a real PMD 85 as the noise. In the emulator that RAM is mostly zero (12.5k of 16k
bytes), the two bytes XORed by the movement code are almost always equal and every spider picks the same direction (right).

The patch replaces the routine (15 bytes, the same length) with an 8-bit LFSR kept in a free byte at 6A80 (stored complemented,
so the zero of the empty RAM is a valid start):
  6369  LDA 6A80 / CMA / ADD A / JNC 6373 / XRI 1D / 6373 CMA / STA 6A80 / RET
In the tape the hex string is split between two lines: 214BB9237CE63F | F68067226A637EC9. The data checksum is updated.

  pavuci_rng.py <input tape> <output tape>
"""
import sys

def patch(d):
    d = bytearray(d)
    hdr = 0x30
    ln = d[hdr + 4] | (d[hdr + 5] << 8)
    start, end = hdr + 15, hdr + 15 + ln + 1
    assert sum(d[hdr:hdr + 14]) & 255 == d[hdr + 14], 'header checksum'
    assert sum(d[start:end]) & 255 == d[end], 'data checksum before the patch'
    for old, new in ((b'214BB9237CE63F', b'3A806A2F87D273'), (b'F68067226A637EC9', b'63EE1D2F32806AC9')):
        assert len(old) == len(new) and bytes(d[start:end]).count(old) == 1, 'pattern %r not found once' % old
        i = bytes(d[start:end]).index(old) + start
        d[i:i + len(old)] = new
    d[end] = sum(d[start:end]) & 255
    return bytes(d)

if __name__ == '__main__':
    open(sys.argv[2], 'wb').write(patch(open(sys.argv[1], 'rb').read()))
