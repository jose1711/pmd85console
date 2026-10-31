"""Split a borik.net .ptp package into blocks and remove the 2 byte frames (see pmd85console notes)."""
import re, sys
def blocks(d):
    leads=[(m.start(),len(m.group())) for m in re.finditer(rb'U{8,}',d)]
    out=[]
    for i,(p,l) in enumerate(leads):
        end=leads[i+1][0] if i+1<len(leads) else len(d)
        out.append((p,l,end))
    return out
def convert(d,p,l,end):
    hdr=d[p+l:p+l+15]
    typ=hdr[1]; ln=hdr[4]|(hdr[5]<<8)
    body=d[p+l+15:end]
    data=body[2:2+ln+1+1]       # frame(2) + data(ln+1) + checksum(1)
    rest=body[2+ln+1+1:]
    if typ==0x3f: rest=rest[2:] # AutoRun body has its own frame
    return d[p:p+l]+hdr+data+rest, hdr[6:14].decode('latin-1'), typ, ln, len(rest)
if __name__=='__main__':
    d=open(sys.argv[1],'rb').read()
    for k,(p,l,e) in enumerate(blocks(d)):
        c,name,typ,ln,rl=convert(d,p,l,e)
        print(k,repr(name),hex(typ),'len',ln,'rest',rl,'out',len(c))
