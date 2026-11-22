#!/usr/bin/env python3
"""HORAC (Horac a pavouci, PMD 85-1, machine code): the spiders walk the same way most of the time (the same bug as PAVUCI).

The "random" routine at 7898 returns the next byte of the memory window 8000-BFFF (the pointer is the operand of its LXI H,
starts at 8123 and goes on by one), so the game takes the uninitialised RAM of a real PMD 85 as the noise. The callers at 78A8
XOR two successive bytes and compare the result with 8 and 0B. In the emulator the window is zero except 8000-8FFF (game data),
so 3/4 of the time the XOR is 0 and the spider takes the first branch.

The patch replaces the routine (15 bytes, the same length) with an 8-bit LFSR kept in a free byte at B000 (zero in the window,
stored complemented, so the zero of the empty RAM is a valid start):
  7898  LDA B000 / CMA / ADD A / JNC 78A2 / XRI 1D / 78A2 CMA / STA B000 / RET
The data checksum of the tape is updated.

  horac_rng.py <input tape> <output tape>
"""
import sys

def patch(d):
    d = bytearray(d)
    hdr = 0x30
    ln = d[hdr + 4] | (d[hdr + 5] << 8)
    load = d[hdr + 2] | (d[hdr + 3] << 8)
    start, end = hdr + 15, hdr + 15 + ln + 1
    assert sum(d[hdr:hdr + 14]) & 255 == d[hdr + 14], 'header checksum'
    assert sum(d[start:end]) & 255 == d[end], 'data checksum before the patch'
    old = bytes.fromhex('21 54 80 23 7C E6 3F F6 80 67 22 99 78 7E C9'.replace('54 80', '23 81'))
    new = bytes.fromhex('3A 00 B0 2F 87 D2 A2 78 EE 1D 2F 32 00 B0 C9')
    i = start + 0x7898 - load
    assert bytes(d[i:i + 15]) == old, 'routine not at 7898'
    d[i:i + 15] = new
    d[end] = sum(d[start:end]) & 255
    return bytes(d)

if __name__ == '__main__':
    open(sys.argv[2], 'wb').write(patch(open(sys.argv[1], 'rb').read()))
