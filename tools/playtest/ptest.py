"""ptest.py GAME MODE(pad|remote) MINUTES SLOT: plays GAME with only the keys the pad or the TV remote can send (the pad keys come from the defaults and the pad: entries of REMAP, the remote has the cursor keys and OK). The start keys of every game are in starts.json; the result is in ~/tmp/playtest/out15/<mode>/<GAME>/ (events.log, notes.json, shots)."""
import sys,os,json,time
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import pmdplay as p
name,mode,minutes,slot=sys.argv[1],sys.argv[2],float(sys.argv[3]),int(sys.argv[4])
START=json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'starts.json')))
PAD_DEF={'up':'e','down':'z','left':'Left','right':'Right','a':'Space','b':'Return','x':'h','y':'i','lb':'Left Shift','rb':'Keypad +','start':'Return'}
games=p.load_games()
g=games[name]
def padkeys():
    d=dict(PAD_DEF)
    for it in g['remap'].split(','):
        if it.startswith('pad:') and '=' in it:
            k,v=it[4:].split('=',1); d[k]=v
    dirs=[d['up'],d['down'],d['left'],d['right']]
    acts=[]
    for k in ('a','b','x','y','lb','rb','start'):
        if d[k] not in acts and d[k] not in p.NEVER and d[k] not in dirs: acts.append(d[k])
    return dirs,acts
if mode=='pad': DIRS,ACTS=padkeys()
else: DIRS,ACTS=['Left','Right','Up','Down'],['Return']
p.controls=lambda gg:(list(DIRS),list(ACTS))
st=START.get(name,{}).get(mode, ['Return'])
def start_game(self,acts):
    for k in st:
        if k.startswith('wait:'): time.sleep(float(k[5:])); continue
        self.press(k,300); time.sleep(1.5)
    self.notes['start_keys']=st
p.Session.start_game=start_game
out=os.path.expanduser('~/tmp/playtest/out15/%s'%mode)
os.makedirs(out,exist_ok=True)
s=p.Session(g,minutes,18400+slot,':%d'%(400+slot),out,False,slot+1)
n=s.run(verbose=False)
print('done %-10s %-6s keys=%d died=%s left=%s stuck=%s'%(name,mode,n['keys_sent'],n.get('died'),n.get('left_game'),n.get('stuck')),flush=True)
