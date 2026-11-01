"""Autorun .ptp with a custom loader: [lead][hdr 15][F0][data ln+1][chk] then ([F][block of F bytes])*; drop all the frames."""
def convert(d):
    # d: the whole .ptp, starts with 3F 00 and the lead
    d=d[2:]
    j=d.find(b'U'*16)+16
    while d[j]==0x55: j+=1
    hdr=d[j:j+15]; ln=hdr[4]|(hdr[5]<<8)
    out=bytearray(d[:j+15])
    p=j+15
    f0=d[p]|(d[p+1]<<8); p+=2
    assert f0==ln+2,(f0,ln)
    out+=d[p:p+ln+2]; p+=ln+2
    frames=[f0]
    while p<len(d):
        f=d[p]|(d[p+1]<<8); p+=2
        out+=d[p:p+f]; p+=f; frames.append(f)
    return bytes(out), frames, p==len(d)
if __name__=='__main__':
    import sys
    d=open(sys.argv[1],'rb').read()
    out,frames,ok=convert(d)
    print(sys.argv[1],'frames',frames,'consumed all' if ok else 'LEFTOVER',len(out))
    if len(sys.argv)>2: open(sys.argv[2],'wb').write(out)
