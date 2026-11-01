#!/usr/bin/env python3
"""A small two pass Intel 8080 assembler (python3 -I asm8080.py in.asm out.bin [out.lst]).

Syntax: `label:`, `NAME EQU expr`, ORG, DB (numbers, 'c', "text", expressions), DW, DS n[,fill], END; `;` comments.
Numbers: 123, 0x1F, 1FH, 0B1010? (no), $ is the current address; expressions are Python expressions with the labels,
`lo(x)` and `hi(x)`.  Registers and mnemonics are case insensitive, labels are case sensitive.
"""
import re, sys

REGS = {'B': 0, 'C': 1, 'D': 2, 'E': 3, 'H': 4, 'L': 5, 'M': 6, 'A': 7}
RP = {'B': 0, 'D': 1, 'H': 2, 'SP': 3}
RPP = {'B': 0, 'D': 1, 'H': 2, 'PSW': 3}
CC = {'NZ': 0, 'Z': 1, 'NC': 2, 'C': 3, 'PO': 4, 'PE': 5, 'P': 6, 'M': 7}
ALU = {'ADD': 0, 'ADC': 1, 'SUB': 2, 'SBB': 3, 'ANA': 4, 'XRA': 5, 'ORA': 6, 'CMP': 7}
ALUI = {'ADI': 0xC6, 'ACI': 0xCE, 'SUI': 0xD6, 'SBI': 0xDE, 'ANI': 0xE6, 'XRI': 0xEE, 'ORI': 0xF6, 'CPI': 0xFE}
SIMPLE = {'NOP': 0x00, 'RLC': 0x07, 'RRC': 0x0F, 'RAL': 0x17, 'RAR': 0x1F, 'DAA': 0x27, 'CMA': 0x2F, 'STC': 0x37,
          'CMC': 0x3F, 'HLT': 0x76, 'RET': 0xC9, 'PCHL': 0xE9, 'XCHG': 0xEB, 'XTHL': 0xE3, 'SPHL': 0xF9, 'DI': 0xF3, 'EI': 0xFB}
ADDR16 = {'LDA': 0x3A, 'STA': 0x32, 'LHLD': 0x2A, 'SHLD': 0x22, 'JMP': 0xC3, 'CALL': 0xCD}
IMM8 = {'MVI': None, 'IN': 0xDB, 'OUT': 0xD3}


class AsmError(Exception):
    pass


def strip_comment(line):
    out = ''
    q = None
    for ch in line:
        if q:
            out += ch
            if ch == q:
                q = None
        elif ch in '"\'':
            q = ch
            out += ch
        elif ch == ';':
            break
        else:
            out += ch
    return out.rstrip()


def split_args(s):
    args, cur, q = [], '', None
    for ch in s:
        if q:
            cur += ch
            if ch == q:
                q = None
        elif ch in '"\'':
            q = ch
            cur += ch
        elif ch == ',':
            args.append(cur.strip())
            cur = ''
        else:
            cur += ch
    if cur.strip() or args:
        args.append(cur.strip())
    return args


def evalx(expr, syms, pc):
    e = expr.strip()
    e = re.sub(r"'(.)'", lambda m: str(ord(m.group(1))), e)
    e = re.sub(r'\b([0-9][0-9A-Fa-f]*)[Hh]\b', lambda m: '0x' + m.group(1), e)
    e = e.replace('$', str(pc))
    env = {'lo': lambda x: x & 255, 'hi': lambda x: (x >> 8) & 255}
    env.update(syms)
    try:
        return int(eval(e, {'__builtins__': {}}, env))
    except NameError as ex:
        raise KeyError(str(ex))


def expand_macros(text):
    """`NAME MACRO` ... `ENDM` (no parameters, no labels inside); a line that is just NAME expands to the body."""
    out, macros, cur, name = [], {}, None, None
    for raw in text.split('\n'):
        line = strip_comment(raw).strip()
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s+MACRO\b', line, re.I)
        if m:
            name, cur = m.group(1), []
            continue
        if cur is not None:
            if line.upper() == 'ENDM':
                macros[name], cur = cur, None
            else:
                cur.append(raw)
            continue
        if line in macros:
            out.extend(macros[line])
        else:
            out.append(raw)
    return '\n'.join(out)


def assemble(text, listing=None):
    lines = expand_macros(text).split('\n')
    syms = {}
    for pass_no in (1, 2):
        pc = 0
        org = None
        out = bytearray()
        for n, raw in enumerate(lines, 1):
            line = strip_comment(raw)
            if not line.strip():
                continue
            label = None
            m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:(.*)$', line)
            if m:
                label, line = m.group(1), m.group(2)
            else:
                m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s+(?i:EQU)\s+(.*)$', line)
                if m:
                    syms[m.group(1)] = evalx(m.group(2), syms, pc) if pass_no == 2 or True else 0
                    continue
            if label:
                syms[label] = pc
            line = line.strip()
            if not line:
                continue
            m = re.match(r'^([A-Za-z]+)\s*(.*)$', line)
            op = m.group(1).upper()
            rest = m.group(2).strip()
            args = split_args(rest) if rest else []
            if op == 'EQU':
                continue
            try:
                data = encode(op, args, syms, pc, pass_no)
            except KeyError as ex:
                if pass_no == 2:
                    raise AsmError('line %d: undefined %s: %s' % (n, ex, raw.strip()))
                data = b'\0' * encode_len(op, args, pc)
            except (AsmError, ValueError, IndexError) as ex:
                raise AsmError('line %d: %s: %s' % (n, ex, raw.strip()))
            if op == 'ORG':
                pc = data
                if org is None:
                    org = pc
                continue
            if org is None:
                org = pc
            if pass_no == 2 and listing is not None:
                listing.append('%04X  %-12s %s' % (pc, data.hex(), raw.rstrip()))
            out += data
            pc += len(data)
    return org or 0, bytes(out), syms


def encode_len(op, args, pc):
    try:
        return len(encode(op, args, {}, pc, 1, sizeonly=True))
    except KeyError:
        return 3


def val(a, syms, pc, pass_no, sizeonly=False):
    if sizeonly:
        return 0
    try:
        return evalx(a, syms, pc)
    except KeyError:
        if pass_no == 1:
            return 0
        raise


def encode(op, args, syms, pc, pass_no, sizeonly=False):
    V = lambda a: val(a, syms, pc, pass_no, sizeonly)
    if op == 'ORG':
        return evalx(args[0], syms, pc)
    if op == 'END':
        return b''
    if op == 'DB':
        b = bytearray()
        for a in args:
            if len(a) >= 2 and a[0] == '"' and a[-1] == '"':
                b += a[1:-1].encode('latin-1')
            else:
                b.append(V(a) & 255)
        return bytes(b)
    if op == 'DW':
        b = bytearray()
        for a in args:
            v = V(a)
            b += bytes([v & 255, (v >> 8) & 255])
        return bytes(b)
    if op == 'DS':
        n = evalx(args[0], syms, pc)
        fill = V(args[1]) if len(args) > 1 else 0
        return bytes([fill & 255]) * n
    if op in SIMPLE:
        return bytes([SIMPLE[op]])
    if op == 'MOV':
        return bytes([0x40 | REGS[args[0].upper()] << 3 | REGS[args[1].upper()]])
    if op == 'MVI':
        return bytes([0x06 | REGS[args[0].upper()] << 3, V(args[1]) & 255])
    if op == 'LXI':
        v = V(args[1])
        return bytes([0x01 | RP[args[0].upper()] << 4, v & 255, (v >> 8) & 255])
    if op in ADDR16:
        v = V(args[0])
        return bytes([ADDR16[op], v & 255, (v >> 8) & 255])
    if op in ('LDAX', 'STAX'):
        return bytes([(0x0A if op == 'LDAX' else 0x02) | RP[args[0].upper()] << 4])
    if op in ('PUSH', 'POP'):
        return bytes([(0xC5 if op == 'PUSH' else 0xC1) | RPP[args[0].upper()] << 4])
    if op == 'INR':
        return bytes([0x04 | REGS[args[0].upper()] << 3])
    if op == 'DCR':
        return bytes([0x05 | REGS[args[0].upper()] << 3])
    if op == 'INX':
        return bytes([0x03 | RP[args[0].upper()] << 4])
    if op == 'DCX':
        return bytes([0x0B | RP[args[0].upper()] << 4])
    if op == 'DAD':
        return bytes([0x09 | RP[args[0].upper()] << 4])
    if op in ALU:
        return bytes([0x80 | ALU[op] << 3 | REGS[args[0].upper()]])
    if op in ALUI:
        return bytes([ALUI[op], V(args[0]) & 255])
    if op in ('IN', 'OUT'):
        return bytes([IMM8[op], V(args[0]) & 255])
    if op == 'RST':
        return bytes([0xC7 | (V(args[0]) & 7) << 3])
    if op[0] == 'J' and op[1:] in CC:
        v = V(args[0])
        return bytes([0xC2 | CC[op[1:]] << 3, v & 255, (v >> 8) & 255])
    if op[0] == 'C' and op[1:] in CC and op != 'CMC':
        v = V(args[0])
        return bytes([0xC4 | CC[op[1:]] << 3, v & 255, (v >> 8) & 255])
    if op[0] == 'R' and op[1:] in CC:
        return bytes([0xC0 | CC[op[1:]] << 3])
    raise AsmError('unknown mnemonic %s' % op)


def main():
    src = open(sys.argv[1], encoding='utf-8').read()
    lst = []
    org, data, syms = assemble(src, lst)
    open(sys.argv[2], 'wb').write(data)
    if len(sys.argv) > 3:
        open(sys.argv[3], 'w').write('\n'.join(lst) + '\n\n' + '\n'.join('%-20s %04X' % (k, v) for k, v in sorted(syms.items(), key=lambda kv: kv[1])) + '\n')
    print('org %04X, %d bytes, end %04X' % (org, len(data), org + len(data)))


if __name__ == '__main__':
    main()
