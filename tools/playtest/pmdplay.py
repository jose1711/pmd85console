#!/usr/bin/env python3
"""Real-time playtest harness for the PMD 85 console.

Reads the controls of a game from simpmd/data/games.lst, starts the emulator (PMD_GAME + web remote),
and plays it in real time through the web API (/key?k=..&d=1|0 for key down/up, /screen for the video
memory) for N minutes. Writes notes.json, events.log and screenshots to <out>/<GAME>/.

  pmdplay.py --games AUTO,ZED --minutes 10            play the listed games
  pmdplay.py --all --jobs 6 --minutes 10              all games, 6 emulators in parallel
  pmdplay.py --games AUTO --minutes 3 --watch         emulator window on your screen, live events on stdout

Live view: every emulator listens on http://localhost:<port>/ (the web remote page shows the screen).
"""
import argparse, concurrent.futures as cf, http.client, json, os, random, re, shutil, subprocess, sys, tempfile, threading, time
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
GAMES_LST = os.path.join(REPO, 'simpmd', 'data', 'games.lst')
BIN = os.path.expanduser('~/tmp/playtest/bin/simpmd')
OUT = os.path.expanduser('~/tmp/playtest/out')

NO_BLINK = bytes(b & 0x7F for b in range(256))
NAME_RE = re.compile(r'(JM[EÉ]NO|\bMENO\b|YOUR NAME|ENTER NAME|NAME ?[:?]|INITIALS|VASE JM|ZADEJ.{0,12}(JM[EÉ]NO|INICI))', re.I)
TABLE_RE = re.compile(r'(HI.?SCORE|HIGH|REKORD|BEST|NEJLEP|TOP ?\d|TABULKA|SCORE)', re.I)
KEY_WORDS = {'space': 'Space', 'enter': 'Return', 'return': 'Return', 'end': 'End', 'pgdn': 'PageDown', 'pageup': 'PageUp',
             'home': 'Home', 'shift': 'Left Shift'}
DIRS = {'Left', 'Right', 'Up', 'Down', 'e', 'z'}
NEVER = {'Escape', 'Left Ctrl', 'Right Ctrl'}     # Esc held leaves the game, Ctrl is STOP


# ---------------------------------------------------------------- games.lst

def load_games(path=GAMES_LST):
    games = {}
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line or line.startswith('#'):
            continue
        if line.count(';') < 2:
            continue                       # the emulator skips these lines too (not in the menu)
        f = (line.split(';') + [''] * 8)[:8]
        pad = []
        for item in f[4].split(','):
            if ':' in item:
                label, keys = item.rsplit(':', 1)
                pad.append((label.strip(), keys.strip()))
        games[f[0]] = dict(name=f[0], model=f[1], note=f[2], remap=f[3], pad=pad, hint=f[5], input=f[6], category=f[7])
    return games


def controls(game):
    """Key sets the autoplayer uses, derived from PAD and the KEYS hint."""
    dirs, acts = [], []
    for label, keys in game['pad']:
        if any(k in NEVER for k in keys.split('&')):
            continue
        (dirs if keys in DIRS else acts).append(keys)
    # keys are named outside the parentheses (those list pad and TV buttons); "neprepinat J" is a key to leave alone
    hint = re.sub(r'neprepinat\s+\w+', '', re.sub(r'\([^)]*\)', ' ', game['hint']), flags=re.I)
    for m in re.finditer(r'(?<![\w+])([A-Za-z0-9])(?![\w+])', hint):
        k = m.group(1).lower()
        if k not in acts and k not in dirs:
            acts.append(k)
    for w, k in KEY_WORDS.items():
        if re.search(r'\b' + w + r'\b', hint, re.I) and k not in acts:
            acts.append(k)
    for m in re.finditer(r'\bF(\d{1,2})\b', hint):
        k = 'F' + m.group(1)
        if k not in acts:
            acts.append(k)
    # directions named in the hint (many games have no PAD): cursor keys
    h = game['hint'].lower()
    for words, ks in ((('sipk', 'kurzor', 'cursor'), ('Left', 'Right', 'Up', 'Down')), (('vlevo',), ('Left',)), (('vpravo',), ('Right',)),
                      (('nahoru',), ('Up',)), (('dolu',), ('Down',))):
        if any(w in h for w in words):
            for k in ks:
                if k not in dirs:
                    dirs.append(k)
    if ('ROM ' in game['note'] or 'TYPE' in game['note']) and 'Return' not in acts:
        acts.append('Return')
    if not dirs and not acts:
        # No PAD and no key in the hint (text input, initials): arrows, start keys, digits and a few letters
        dirs = ['Left', 'Right', 'Up', 'Down']
        acts = ['Space', 'Return', '1', '2', '3', '4', 'a', 'b', 'c', 'x']
    return dirs, acts


# ---------------------------------------------------------------- emulator

class Emu:
    def __init__(self, game, port, display, watch=False):
        self.game, self.port, self.display, self.watch = game, port, display, watch
        self.xvfb = self.proc = None

    def start(self, logfile):
        env = dict(os.environ, SDL_AUDIODRIVER='dummy', PMD_GAME=self.game, PMD_WEB=str(self.port))
        if not self.watch:
            self.xvfb = subprocess.Popen(['Xvfb', self.display, '-screen', '0', '800x600x24'],
                                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(1)
            env.update(DISPLAY=self.display, SDL_VIDEODRIVER='x11')
            env.pop('WAYLAND_DISPLAY', None)
        else:
            env.update(SDL_VIDEODRIVER='x11')       # XWayland window, windowed
            env.pop('PMD_AUTOSTART', None)
        self.proc = subprocess.Popen([BIN], cwd=os.path.dirname(BIN), env=env, stdout=open(logfile, 'w'), stderr=subprocess.STDOUT)
        for _ in range(100):
            time.sleep(0.2)
            if self.proc.poll() is not None:
                raise RuntimeError('emulator exited, see ' + logfile)
            try:
                self.get('/state')
                return
            except OSError:
                pass
        raise RuntimeError('emulator web remote did not start')

    def get(self, path):
        c = http.client.HTTPConnection('127.0.0.1', self.port, timeout=3)
        try:
            c.request('GET', path)
            return c.getresponse().read()
        finally:
            c.close()

    def alive(self):
        return self.proc is not None and self.proc.poll() is None

    def state(self):
        try:
            return json.loads(self.get('/state'))
        except Exception:
            return {}

    def mode(self):
        return self.state().get('mode', '?')

    def wait_loaded(self, limit=180):
        """Wait until the autoload of the game (typed monitor commands, tape) is done."""
        t = time.monotonic()
        while time.monotonic() - t < limit and self.state().get('typing', True):
            time.sleep(0.5)
        return time.monotonic() - t

    def screen(self):
        return self.get('/screen')

    def key(self, name, down):
        for k in name.split('&'):
            self.get('/key?k=%s&d=%d' % (k.replace(' ', '%20').replace('+', '%2B'), 1 if down else 0))

    def stop(self):
        for p in (self.proc, self.xvfb):
            if p and p.poll() is None:
                p.terminate()
                try:
                    p.wait(3)
                except subprocess.TimeoutExpired:
                    p.kill()


def to_image(scr, scale=3, invert=False):
    img = Image.new('L', (288, 256))
    px = img.load()
    for y in range(256):
        for x in range(48):
            d = scr[y * 48 + x]
            col = 146 if d & 64 else 255
            for k in range(6):
                v = col if (d >> k) & 1 else 0
                px[x * 6 + k, y] = 255 - v if invert else v
    return img.resize((288 * scale, 256 * scale), Image.NEAREST)


def changed(a, b):
    """Number of differing pixels between two screens (the blink bit is ignored)."""
    x = int.from_bytes(a.translate(NO_BLINK), 'big') ^ int.from_bytes(b.translate(NO_BLINK), 'big')
    return (x & ((1 << (48 * 256 * 8)) - 1)).bit_count() if x else 0


# ---------------------------------------------------------------- the play session

class Session:
    def __init__(self, game, minutes, port, display, out, watch, seed):
        self.g, self.minutes, self.out, self.watch = game, minutes, os.path.join(out, game['name']), watch
        shutil.rmtree(self.out, ignore_errors=True)
        os.makedirs(os.path.join(self.out, 'shots'))
        self.emu = Emu(game['name'], port, display, watch)
        self.port = port
        self.rnd = random.Random(seed)
        self.t0 = time.monotonic()
        self.events, self.shots, self.ocr_lines = [], [], {}
        self.keys_sent = 0
        self.nudge = 0
        self.log = open(os.path.join(self.out, 'events.log'), 'w', buffering=1)
        self.notes = dict(game=game['name'], model=game['model'], category=game['category'], hint=game['hint'], pad=game['pad'],
                          remap=game['remap'], input=game['input'], name_prompt=False, hiscore_table=False,
                          probe={}, stuck=0, died=False, left_game=False)

    def t(self):
        return time.monotonic() - self.t0

    def ev(self, kind, detail=''):
        line = '%6.1f [%s] %-10s %s' % (self.t(), self.g['name'], kind, detail)
        self.events.append((round(self.t(), 1), kind, detail))
        self.log.write(line + '\n')
        if self.watch or self.verbose:
            print(line, flush=True)

    def shot(self, scr, reason):
        name = 't%04d_%s.png' % (self.t(), reason)
        to_image(scr).save(os.path.join(self.out, 'shots', name))
        self.shots.append(name)
        self.ev('shot', name)

    def press(self, key, ms):
        self.emu.key(key, True)
        time.sleep(ms / 1000)
        self.emu.key(key, False)
        self.keys_sent += 1

    # -- OCR runs in a thread, the control loop never waits for it
    def ocr_async(self, scr):
        def work():
            with tempfile.NamedTemporaryFile(suffix='.png') as f:
                to_image(scr, 4, invert=True).save(f.name)
                r = subprocess.run(['tesseract', f.name, 'stdout', '--psm', '6'], capture_output=True, text=True, timeout=20)
            return r.stdout
        return self.pool.submit(work)

    def handle_ocr(self, text, scr):
        for line in (l.strip() for l in text.splitlines()):
            if len(line) > 2 and line not in self.ocr_lines:
                self.ocr_lines[line] = round(self.t(), 1)
        if NAME_RE.search(text) and self.t() - self.last_name > 90:
            self.last_name = self.t()
            self.notes['name_prompt'] = True
            self.ev('NAME', 'name prompt: ' + ' | '.join(l for l in text.splitlines() if NAME_RE.search(l))[:100])
            self.shot(scr, 'name_prompt')
            for ch in 'aaa':
                self.press(ch, 150)
                time.sleep(0.25)
            self.press('Return', 150)
            self.ev('typed', 'AAA + Enter')
            time.sleep(1)
            self.shot(self.emu.screen(), 'after_name')
        elif TABLE_RE.search(text) and not self.notes['hiscore_table']:
            self.notes['hiscore_table'] = True
            self.ev('TABLE', 'hiscore/score text: ' + ' | '.join(l for l in text.splitlines() if TABLE_RE.search(l))[:100])

    # -- phases
    def probe(self, keys):
        """Hold each key 0.4 s and compare the screen change with the change of an idle 0.4 s."""
        for k in keys:
            a = self.emu.screen(); time.sleep(0.4); idle = changed(a, self.emu.screen())
            a = self.emu.screen(); self.emu.key(k, True); time.sleep(0.4); b = self.emu.screen(); self.emu.key(k, False)
            with_key = changed(a, b)
            self.notes['probe'][k] = dict(idle=idle, with_key=with_key, reacts=with_key > 2 * idle + 20)
            time.sleep(0.3)
        self.ev('probe', ', '.join('%s%s' % (k, '*' if v['reacts'] else '') for k, v in self.notes['probe'].items()))

    def start_game(self, acts):
        """Tap the usual start keys one by one until the screen starts to move."""
        cands = ['Return', 'Space'] + [k for k in acts if k not in ('Return', 'Space')]
        for k in cands[:12]:
            a = self.emu.screen()
            self.press(k, 200)
            time.sleep(1.2)
            if changed(a, self.emu.screen()) > 300:
                self.ev('start', 'screen reacted to ' + k)
                self.notes.setdefault('start_keys', []).append(k)

    def run(self, verbose=False):
        self.verbose = verbose
        self.pool = cf.ThreadPoolExecutor(1)
        self.last_name = -999
        dirs, acts = controls(self.g)
        self.notes.update(dir_keys=dirs, action_keys=acts)
        self.ev('controls', 'dirs=%s actions=%s hint=%s' % (dirs, acts, self.g['hint'][:80]))
        self.ev('web', 'http://localhost:%d/' % self.port)
        try:
            self.emu.start(os.path.join(self.out, 'emulator.log'))
            self.ev('loading', 'autoload finished after %.0f s' % self.emu.wait_loaded())
            time.sleep(2)
            self.shot(self.emu.screen(), 'title')
            self.start_game(acts)
            self.probe((dirs + acts)[:10])
            self.play(dirs, acts)
        except Exception as e:
            self.ev('ERROR', repr(e))
            self.notes['error'] = repr(e)
        finally:
            try:
                self.shot(self.emu.screen(), 'end')
            except Exception:
                pass
            self.emu.stop()
            self.pool.shutdown(wait=False)
            self.notes.update(duration=round(self.t()), keys_sent=self.keys_sent, shots=self.shots,
                              ocr_lines=self.ocr_lines, events=self.events)
            json.dump(self.notes, open(os.path.join(self.out, 'notes.json'), 'w'), indent=1, ensure_ascii=False)
        return self.notes

    def play(self, dirs, acts):
        end = self.t0 + self.minutes * 60
        prev = self.emu.screen()
        last_change = last_shot = last_ocr = self.t()
        ocr_job = None
        nxt = 0
        held = None
        activity = 0
        while time.monotonic() < end:
            if not self.emu.alive():
                self.notes['died'] = True
                self.ev('DIED', 'emulator process ended')
                return
            if self.emu.mode() != 'game':
                self.notes['left_game'] = True
                self.ev('MENU', 'the emulator is back in the menu')
                return
            scr = self.emu.screen()
            d = changed(prev, scr)
            activity += d
            if d > 0:
                last_change = self.t()
            if d > 6000 and self.t() - last_shot > 15:
                last_shot = self.t(); self.shot(scr, 'change')
            elif self.t() - last_shot > 60:
                last_shot = self.t(); self.shot(scr, 'periodic')
            prev = scr
            # stuck: nothing changes for 8 s -> try the start keys, each nudge continues where the last stopped
            if self.t() - last_change > 8:
                self.notes['stuck'] += 1
                pool = ['Return', 'Space'] + [k for k in acts if not k.startswith('F')] + ['0', '1', '2', '3', '4', 'y', 'n', 'h'] + [k for k in acts if k.startswith('F')]
                pool = [k for i, k in enumerate(pool) if k not in pool[:i]]
                base = scr
                tried = []
                for _ in range(6):
                    k = pool[self.nudge % len(pool)]; self.nudge += 1
                    tried.append(k)
                    self.press(k, 250); time.sleep(0.3)
                    if k != 'Return':
                        self.press('Return', 200)
                    time.sleep(0.5)
                    if changed(base, self.emu.screen()) > 300:
                        self.ev('restart', 'screen reacted to ' + k)
                        self.notes.setdefault('restart_keys', {}).setdefault(k, 0)
                        self.notes['restart_keys'][k] += 1
                        break
                self.ev('stuck', 'no change for 8 s, tried ' + ','.join(tried))
                last_change = self.t()
            # OCR
            if ocr_job and ocr_job.done():
                try:
                    self.handle_ocr(ocr_job.result(), self.emu.screen())
                except Exception as e:
                    self.ev('ocr-error', repr(e))
                ocr_job = None
            if not ocr_job and self.t() - last_ocr > 6:
                last_ocr = self.t(); ocr_job = self.ocr_async(scr)
            # control: a new action every 0.15-1 s
            if time.monotonic() >= nxt:
                if held:
                    self.emu.key(held, False); held = None
                r = self.rnd.random()
                if dirs and r < 0.55:
                    held = self.rnd.choice(dirs)
                    self.emu.key(held, True); self.keys_sent += 1
                    nxt = time.monotonic() + self.rnd.uniform(0.15, 0.9)
                elif acts and r < 0.9:
                    k = self.rnd.choice(acts)
                    self.press(k, self.rnd.choice((80, 150, 400, 900)))
                    nxt = time.monotonic() + self.rnd.uniform(0.05, 0.4)
                else:
                    nxt = time.monotonic() + self.rnd.uniform(0.3, 1.0)
            if int(self.t()) % 30 == 0 and int(self.t()) != getattr(self, '_s', -1):
                self._s = int(self.t())
                self.ev('status', 'keys=%d activity=%d px since last status, held=%s' % (self.keys_sent, activity, held))
                activity = 0
            time.sleep(0.08)
        if held:
            self.emu.key(held, False)


# ---------------------------------------------------------------- main

def one(args):
    name, slots, a = args
    i = slots.get()
    try:
        return one_slot(name, i, a)
    finally:
        slots.put(i)


def one_slot(name, i, a):
    games = load_games()
    s = Session(games[name], a.minutes, a.port + i, ':%d' % (a.display + i), a.out, a.watch, a.seed + i)
    notes = s.run(verbose=a.verbose or a.jobs == 1)
    print('done %-12s keys=%d name_prompt=%s table=%s died=%s' % (name, notes['keys_sent'], notes['name_prompt'], notes['hiscore_table'], notes['died']), flush=True)
    return notes


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--games', help='comma separated names from games.lst')
    ap.add_argument('--all', action='store_true')
    ap.add_argument('--minutes', type=float, default=10)
    ap.add_argument('--jobs', type=int, default=1, help='parallel emulators')
    ap.add_argument('--watch', action='store_true', help='show the emulator window on this desktop (one game at a time)')
    ap.add_argument('--verbose', action='store_true', help='print events of parallel jobs too')
    ap.add_argument('--port', type=int, default=18200)
    ap.add_argument('--display', type=int, default=100)
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--seed', type=int, default=1)
    a = ap.parse_args()
    games = load_games()
    names = list(games) if a.all else [n for n in (a.games or '').split(',') if n]
    unknown = [n for n in names if n not in games]
    if unknown or not names:
        sys.exit('unknown or no games: %s' % unknown)
    if a.watch:
        a.jobs = 1
    import queue
    slots = queue.Queue()
    for i in range(a.jobs):
        slots.put(i)
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        list(ex.map(one, [(n, slots, a) for n in names]))


if __name__ == '__main__':
    main()
