import sys; sys.path.insert(0,'.')
import asm8080, sim8080

class Done(Exception): pass

def run(lines, maxsteps=30_000_000, src='mpy.asm'):
    org, code, syms = asm8080.assemble(open(src).read())
    s = sim8080.Sim()
    s.m[org:org+len(code)] = code
    s.m[0xC03E] = 0; s.m[0xC03F] = 0xC0
    out = []
    keys = []
    for l in lines:
        keys += [ord(c) for c in l] + [0x0D]
    def putc(sim):
        c = sim.a
        if c == 0x0D: out.append('\n')
        elif c == 0x1C: pass
        else: out.append(chr(c))
    def getk(sim):
        if not keys: raise Done
        sim.a = keys.pop(0)
    s.hooks[0x8500] = putc
    s.hooks[0x84A1] = getk
    # RAM kde bude zasobnik: PUTC/GETK hooky vracaju cez pop
    s.pc = org
    try:
        s.run(maxsteps)
    except Done:
        pass
    return ''.join(out), s, syms

if __name__ == '__main__':
    o, s, _ = run(sys.argv[1:])
    print(o)
