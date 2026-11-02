"""A small Intel 8080 simulator for testing programs (python3 -I)."""

PARITY = [bin(i).count('1') % 2 == 0 for i in range(256)]


def _cyc():
    t = [4] * 256
    for op in range(256):
        hi, lo = op >> 6, op & 7
        if hi == 0:
            if lo == 1: t[op] = 10 if not op & 8 else 10      # LXI / DAD
            elif lo == 2: t[op] = 7 if op < 0x20 else (16 if op in (0x22, 0x2A) else 13)
            elif lo == 3: t[op] = 5
            elif lo in (4, 5): t[op] = 10 if (op >> 3) == 6 else 5
            elif lo == 6: t[op] = 10 if (op >> 3) == 6 else 7
        elif hi == 1:
            t[op] = 7 if (op & 7 == 6 or (op >> 3) & 7 == 6) else 5
        elif hi == 2:
            t[op] = 7 if lo == 6 else 4
        else:
            if lo == 0: t[op] = 11
            elif lo == 1: t[op] = 10
            elif lo == 2: t[op] = 10
            elif lo == 3: t[op] = {0xC3: 10, 0xE3: 18, 0xF3: 4, 0xFB: 4, 0xD3: 10, 0xDB: 10}.get(op, 10) if op in (0xC3, 0xE3, 0xF3, 0xFB) else 10
            elif lo == 4: t[op] = 17
            elif lo == 5: t[op] = 17 if op & 8 == 0 and op in (0xCD,) or op & 1 == 0 and op & 8 else 11
            elif lo == 6: t[op] = 7
            elif lo == 7: t[op] = 11
    for op in (0xC5, 0xD5, 0xE5, 0xF5): t[op] = 11
    for op in (0xC1, 0xD1, 0xE1, 0xF1, 0xC9): t[op] = 10
    t[0xCD] = 17; t[0xE9] = 5; t[0xF9] = 5; t[0xEB] = 4; t[0xE3] = 18
    t[0x76] = 7
    return t
CYC = _cyc()


class Sim:
    def __init__(self):
        self.m = bytearray(65536)
        self.a = self.b = self.c = self.d = self.e = self.h = self.l = 0
        self.sp = 0
        self.pc = 0
        self.s = self.z = self.ac = self.p = self.cy = False
        self.hooks = {}
        self.halted = False
        self.cycles = 0
        self.tcycles = 0
        self.inport = {}
        self.ports = {}
        self.outhook = None
        self.stop = set()

    # helpers
    def reg(self, n):
        if n == 6:
            return self.m[(self.h << 8) | self.l]
        return [self.b, self.c, self.d, self.e, self.h, self.l, 0, self.a][n]

    def setreg(self, n, v):
        v &= 255
        if n == 6:
            self.m[(self.h << 8) | self.l] = v
        elif n == 0: self.b = v
        elif n == 1: self.c = v
        elif n == 2: self.d = v
        elif n == 3: self.e = v
        elif n == 4: self.h = v
        elif n == 5: self.l = v
        else: self.a = v

    def rp(self, n):
        return [(self.b << 8) | self.c, (self.d << 8) | self.e, (self.h << 8) | self.l, self.sp][n]

    def setrp(self, n, v):
        v &= 0xFFFF
        if n == 0: self.b, self.c = v >> 8, v & 255
        elif n == 1: self.d, self.e = v >> 8, v & 255
        elif n == 2: self.h, self.l = v >> 8, v & 255
        else: self.sp = v

    def fetch(self):
        v = self.m[self.pc]
        self.pc = (self.pc + 1) & 0xFFFF
        return v

    def fetch16(self):
        lo = self.fetch()
        return lo | (self.fetch() << 8)

    def push(self, v):
        self.sp = (self.sp - 1) & 0xFFFF
        self.m[self.sp] = (v >> 8) & 255
        self.sp = (self.sp - 1) & 0xFFFF
        self.m[self.sp] = v & 255

    def pop(self):
        v = self.m[self.sp] | (self.m[(self.sp + 1) & 0xFFFF] << 8)
        self.sp = (self.sp + 2) & 0xFFFF
        return v

    def flags_byte(self):
        return (0x80 if self.s else 0) | (0x40 if self.z else 0) | (0x10 if self.ac else 0) | (0x04 if self.p else 0) | 0x02 | (1 if self.cy else 0)

    def set_flags_byte(self, f):
        self.s, self.z, self.ac, self.p, self.cy = bool(f & 0x80), bool(f & 0x40), bool(f & 0x10), bool(f & 0x04), bool(f & 1)

    def szp(self, v):
        v &= 255
        self.s = bool(v & 0x80)
        self.z = v == 0
        self.p = PARITY[v]
        return v

    def cond(self, n):
        return [not self.z, self.z, not self.cy, self.cy, not self.p, self.p, not self.s, self.s][n]

    def alu(self, op, v):
        a = self.a
        if op in (0, 1):                      # ADD ADC
            c = 1 if (op == 1 and self.cy) else 0
            r = a + v + c
            self.ac = ((a & 15) + (v & 15) + c) > 15
            self.cy = r > 255
            self.a = self.szp(r)
        elif op in (2, 3, 7):                 # SUB SBB CMP
            c = 1 if (op == 3 and self.cy) else 0
            r = a - v - c
            self.ac = ((a & 15) - (v & 15) - c) >= 0
            self.cy = r < 0
            r = self.szp(r)
            if op != 7:
                self.a = r
        elif op == 4:
            self.ac = bool((a | v) & 8)
            self.a = self.szp(a & v)
            self.cy = False
        elif op == 5:
            self.a = self.szp(a ^ v)
            self.cy = self.ac = False
        else:
            self.a = self.szp(a | v)
            self.cy = self.ac = False

    def step(self):
        pc0 = self.pc
        if pc0 in self.hooks:
            self.hooks[pc0](self)
            if self.pc == pc0:                # the hook did not move the pc: return from the call
                self.pc = self.pop()
            return
        op = self.fetch()
        self.cycles += 1
        self.tcycles += CYC[op]
        if op == 0x76:
            self.halted = True
        elif 0x40 <= op < 0x80:
            self.setreg((op >> 3) & 7, self.reg(op & 7))
        elif 0x80 <= op < 0xC0:
            self.alu((op >> 3) & 7, self.reg(op & 7))
        elif op & 0xC7 == 0x06:
            self.setreg((op >> 3) & 7, self.fetch())
        elif op & 0xCF == 0x01:
            self.setrp((op >> 4) & 3, self.fetch16())
        elif op & 0xC7 == 0x04:
            n = (op >> 3) & 7; v = self.reg(n); self.ac = (v & 15) == 15; self.setreg(n, self.szp(v + 1))
        elif op & 0xC7 == 0x05:
            n = (op >> 3) & 7; v = self.reg(n); self.ac = (v & 15) != 0; self.setreg(n, self.szp(v - 1))
        elif op & 0xCF == 0x03:
            n = (op >> 4) & 3; self.setrp(n, self.rp(n) + 1)
        elif op & 0xCF == 0x0B:
            n = (op >> 4) & 3; self.setrp(n, self.rp(n) - 1)
        elif op & 0xCF == 0x09:
            r = self.rp(2) + self.rp((op >> 4) & 3); self.cy = r > 0xFFFF; self.setrp(2, r)
        elif op in (0x0A, 0x1A):
            self.a = self.m[self.rp((op >> 4) & 3)]
        elif op in (0x02, 0x12):
            self.m[self.rp((op >> 4) & 3)] = self.a
        elif op == 0x3A: self.a = self.m[self.fetch16()]
        elif op == 0x32: self.m[self.fetch16()] = self.a
        elif op == 0x2A:
            a = self.fetch16(); self.l = self.m[a]; self.h = self.m[(a + 1) & 0xFFFF]
        elif op == 0x22:
            a = self.fetch16(); self.m[a] = self.l; self.m[(a + 1) & 0xFFFF] = self.h
        elif op == 0xEB:
            self.d, self.h = self.h, self.d; self.e, self.l = self.l, self.e
        elif op == 0xE3:
            lo, hi = self.m[self.sp], self.m[(self.sp + 1) & 0xFFFF]
            self.m[self.sp] = self.l; self.m[(self.sp + 1) & 0xFFFF] = self.h; self.l, self.h = lo, hi
        elif op == 0xF9: self.sp = (self.h << 8) | self.l
        elif op == 0xE9: self.pc = (self.h << 8) | self.l
        elif op & 0xCF == 0xC5:
            n = (op >> 4) & 3
            self.push(((self.a << 8) | self.flags_byte()) if n == 3 else self.rp(n))
        elif op & 0xCF == 0xC1:
            n = (op >> 4) & 3; v = self.pop()
            if n == 3: self.a = v >> 8; self.set_flags_byte(v & 255)
            else: self.setrp(n, v)
        elif op & 0xC7 == 0xC6:
            self.alu((op >> 3) & 7, self.fetch())
        elif op == 0xC3: self.pc = self.fetch16()
        elif op & 0xC7 == 0xC2:
            a = self.fetch16()
            if self.cond((op >> 3) & 7): self.pc = a
        elif op == 0xCD:
            a = self.fetch16(); self.push(self.pc); self.pc = a
        elif op & 0xC7 == 0xC4:
            a = self.fetch16()
            if self.cond((op >> 3) & 7): self.push(self.pc); self.pc = a
        elif op == 0xC9: self.pc = self.pop()
        elif op & 0xC7 == 0xC0:
            if self.cond((op >> 3) & 7): self.pc = self.pop()
        elif op & 0xC7 == 0xC7:
            self.push(self.pc); self.pc = op & 0x38
        elif op == 0x07:
            self.cy = bool(self.a & 0x80); self.a = ((self.a << 1) | (1 if self.cy else 0)) & 255
        elif op == 0x0F:
            self.cy = bool(self.a & 1); self.a = (self.a >> 1) | (0x80 if self.cy else 0)
        elif op == 0x17:
            c = 1 if self.cy else 0; self.cy = bool(self.a & 0x80); self.a = ((self.a << 1) | c) & 255
        elif op == 0x1F:
            c = 0x80 if self.cy else 0; self.cy = bool(self.a & 1); self.a = (self.a >> 1) | c
        elif op == 0x2F: self.a ^= 255
        elif op == 0x37: self.cy = True
        elif op == 0x3F: self.cy = not self.cy
        elif op in (0xF3, 0xFB, 0x00): pass
        elif op == 0xD3:
            port = self.fetch()
            self.ports[port] = self.a
            if self.outhook: self.outhook(port, self.a, self.tcycles)
        elif op == 0xDB:
            port = self.fetch()
            f = self.inport.get(port)
            self.a = f(self) & 255 if f else 0xFF
        else:
            raise RuntimeError('unknown opcode %02X at %04X' % (op, pc0))

    def run(self, max_steps=50_000_000):
        n = 0
        while not self.halted and self.pc not in self.stop and n < max_steps:
            self.step()
            n += 1
        return n
