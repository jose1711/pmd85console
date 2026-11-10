#!/usr/bin/env python3
"""PAVUCI (R&I, BASIC with machine code in hex strings): the sound of the end of a life lasts about 10 minutes.

The machine code at 687c-6888 plays the sound routine 6800 thirteen times with HL = 8001. The routine takes three bytes as the
counters of the nested delay loops; at 8001 there are the bytes 00 80 C3 (the start code of the program), so one call lasts about
48 s (256*128*195 loops) and the player waits about 10 minutes before the game restarts (JMP 6700). The patch points HL to the short
jingle at 6052 (01 03 08, the one of the call at 6897): LXI H,8001 -> LXI H,6052 in the hex string "2101803E0D". Same length; the
data checksum is updated.

  pavuci_deathsound.py <input tape> <output tape>
"""
import sys

def patch(d):
    d = bytearray(d)
    hdr = 0x30
    ln = d[hdr + 4] | (d[hdr + 5] << 8)
    start, end = hdr + 15, hdr + 15 + ln + 1
    assert sum(d[hdr:hdr + 14]) & 255 == d[hdr + 14], 'header checksum'
    assert sum(d[start:end]) & 255 == d[end], 'data checksum before the patch'
    old, new = b'2101803E0DCD0068', b'2152603E0DCD0068'
    assert bytes(d[start:end]).count(old) == 1, 'pattern not found once'
    i = bytes(d[start:end]).index(old) + start
    d[i:i + len(old)] = new
    d[end] = sum(d[start:end]) & 255
    return bytes(d)

if __name__ == '__main__':
    open(sys.argv[2], 'wb').write(patch(open(sys.argv[1], 'rb').read()))
