#!/usr/bin/env python3
"""Zostavi mpy.asm a vyrobi pasku pre PMD 85 (autorun 0x3f, adresa 0100): make_tape.py [vystup]"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import asm8080

def tape(code, addr, name):
    n = len(code) - 1
    h = bytes([0, 0x3F, addr & 255, addr >> 8, n & 255, n >> 8]) + name.encode('latin-1').ljust(8)[:8]
    h += bytes([sum(h) & 255])
    return b'\xff' * 16 + b'\x00' * 16 + b'\x55' * 16 + h + code + bytes([sum(code) & 255])

if __name__ == '__main__':
    org, code, syms = asm8080.assemble(open(os.path.join(HERE, 'mpy.asm')).read())
    assert org == 0x100 and org + len(code) < 0x1C00, 'kod zasahuje do tabulky symbolov'
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', 'simpmd', 'data', 'tapes', 'games-pmd1', 'MPY85')
    open(out, 'wb').write(tape(bytes(code), org, 'MPY85'))
    print('%s: %d bajtov kodu, koniec 0x%04X' % (out, len(code), org + len(code)))
