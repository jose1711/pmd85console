import sys, io, contextlib, re
sys.path.insert(0,'.')
import t_mpy

# kazdy test: zoznam vstupnych riadkov; referencia = CPython exec rovnakeho kodu (REPL echo emulovane len pre print)
tests = {
 'arit': ["print(1+2*3, (1+2)*3, 7//2, -7//2, 7//-2, -7//-2, 7%3, -7%3, 7%-3, -7%-3)",
          "print(100*300, 0x1f, 10-20, 5%1, 2*-3, -(-4))"],
 'cmp': ["print(1<2, 2<1, 1==1, 1!=1, 2>=2, 3<=2, 'a'=='a', 'a'!='b', 'ab'<'b')",
         "print(not 0, not 5, 1 and 2, 0 and 2, 0 or 3, 4 or 5)"],
 'var': ["x=5", "y=x*2", "x+=3", "y-=1", "y*=2", "y//=3", "y%=4", "print(x,y)"],
 'if': ["x=5", "if x>3:", "    print('big')", "elif x>1:", "    print('mid')", "else:", "    print('small')", "",
        "x=2", "if x>3:", "    print('big')", "elif x>1:", "    print('mid')", "else:", "    print('small')", "",
        "x=0", "if x>3:", "    print('big')", "elif x>1:", "    print('mid')", "else:", "    print('small')", ""],
 'while': ["i=0", "s=0", "while i<10:", "    s+=i", "    i+=1", "", "print(s,i)",
           "i=0", "while True:", "    i+=1", "    if i==5:", "        break", "", "print(i)"],
 'for': ["s=0", "for i in range(5):", "    s+=i", "", "print(s)",
         "for i in range(2,10,3):", "    print(i)", "", "for i in range(5,0,-2):", "    print(i)", "",
         "for i in range(10):", "    if i%2==0:", "        continue", "    if i>7:", "        break", "    print(i)", ""],
 'def': ["def f(a,b):", "    return a*b+1", "", "print(f(3,4), f(f(1,2),3))",
         "def fact(n):", "    if n<=1:", "        return 1", "    return n*fact(n-1)", "", "print(fact(7))",
         "def fib(n):", "    if n<2:", "        return n", "    return fib(n-1)+fib(n-2)", "", "print(fib(12))",
         "def g():", "    pass", "", "print(g())"],
 'str': ["s='ab'+\"cd\"", "print(s, len(s), ord('A'), chr(66), str(42)+'!', int('123')+1, 'x\\ny')",
         "t=s+s", "print(t)", "print(str(-5), str(True), str(None))"],
 'oneline': ["for i in range(3): print(i)", "def sq(x): return x*x", "print(sq(9))", "if 1: print('ok')"],
 'scope': ["x=10", "def f():", "    x=1", "    return x", "", "print(f(), x)",
           "def h(n):", "    y=n+x", "    return y", "", "print(h(5))"],
 'shortc': ["def f(n):", "    return n>0 and f(n-1)+1 or 0", "", "print(f(5))", "print(0 and 1/0)"],
 'poke': ["poke(20000, 77)", "print(peek(20000), abs(-5), abs(3))"],
 'mulbig': ["print(12*45, 100*100, -300*20, 181*181)"],
}

def ref(lines):
    # emuluj semantiku: print-y; priradenia; bez echo
    src = "\n".join(lines) + "\n"
    out = io.StringIO()
    g = {'peek': lambda a: 77 if a==20000 else 0, 'poke': lambda a,v: None, 'int': int}
    # '/' nie je podporovane v mpy (1/0 v neevaluovanej vetve) -> nahradime
    src = src.replace('1/0', '1//0')
    with contextlib.redirect_stdout(out):
        exec(compile(src, 'x', 'exec'), g)
    return out.getvalue()

bad = 0
for name, lines in tests.items():
    o, s, _ = t_mpy.run(lines + [""])
    # vyfiltruj prompty a echo: ponechaj len vystup, ktory nasleduje po riadku s promptom
    res = []
    for ln in o.split('\n')[1:]:
        if ln.startswith('>>> ') or ln.startswith('... '):
            ln = ln[4:]
            if ln: continue   # echo vstupu
            continue
        res.append(ln)
    got = "\n".join(res).strip('\n')
    exp = ref(lines).strip('\n').upper()
    ok = (got == exp)
    print(('OK  ' if ok else 'FAIL'), name)
    if not ok:
        bad += 1
        print('  got:', repr(got)); print('  exp:', repr(exp))
print('bad', bad)
