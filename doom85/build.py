#!/usr/bin/env python3
"""build.py [vystup]: zostavi doom.asm + tables.inc a vyrobi pasku DOOM85"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'mpy85'))
sys.path.insert(0, HERE)
import asm8080, gen

def tape(code, addr, name):
    n = len(code) - 1
    h = bytes([0, 0x3F, addr & 255, addr >> 8, n & 255, n >> 8]) + name.encode('latin-1').ljust(8)[:8]
    h += bytes([sum(h) & 255])
    return b'\xff' * 16 + b'\x00' * 16 + b'\x55' * 16 + h + code + bytes([sum(code) & 255])

def source():
    return open(os.path.join(HERE, 'doom.asm')).read() + gen.emit() + '        END start\n'

if __name__ == '__main__':
    org, code, syms = asm8080.assemble(source())
    assert org == 0x100 and org + len(code) < 0x2F00
    if len(sys.argv) > 1:
        open(sys.argv[1], 'wb').write(tape(bytes(code), org, 'DOOM85'))
    print('%d bajtov, koniec 0x%04X' % (len(code), org + len(code)))
