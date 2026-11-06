# Manual check of the games

[← back to README](../README.md)

How to go through the games one by one and write down what works, so that `games.lst` (`KEYS`, `PAD`, `REMAP`,
`INPUT`) is right for every game. See [games.md](games.md) for the format.

## Before you start

- The Pi is up and runs one clean build (do not deploy while testing, see [service.md](service.md)).
- `PMD_SNDLEVEL=1` is set, so the sound can be judged afterwards from the journal.
- Have at hand: keyboard, gamepad, TV remote, a TV with sound.
- Keep one table (this file, or a CSV) with a row per game: game, starts, controls, gamepad, TV remote, text entry,
  sound, note.

## Order

1. Games that already have icons (AUTO, ZED, INVADERS, MANIC+, MANIC-1, BLUDISTE, POSTARIK): confirm only.
2. Games without `KEYS` and `PAD` (most of them), alphabetically, 5 to 10 minutes each.
3. Games that scan the whole keyboard (FRED, SACH, TETRIS, PENETR, SABOTER) last.

## One game

1. **Start:** it starts from the menu, the autoload types the right command (otherwise fix `NOTE`).
2. **Instructions:** read the instructions in the game if there are any (ROBOTIK shows them on [RCL]).
   Write the keys into `KEYS`; look for `K0`-`K11` in the text.
3. **Keyboard:** does it work as the instructions say? Which keys are needed to play (not only for the menus)?
4. **Gamepad:** can a round be finished? Which keys are missing (letters, function keys, two at once)? If so, `REMAP`.
5. **TV remote:** cursor keys, OK (Enter), Back (Esc) only. More than 5 buttons, letters, names, two keys at once:
   no `R` icon.
6. **Names and scores:** does the game ask for a name after the game? That needs the keyboard (or a trick with
   `REMAP`, e.g. MANIC types `A` on [Down]).
7. **Sound:** does it play, does it drop out? Look at `SND level` in the journal.
8. **Saved state:** [Alt]+[F5] and [Alt]+[F9] once, to see that it works.
9. **Esc:** a held [Esc] (and Back on the TV remote) returns to the menu.

## Writing it down

- `games.lst`: `KEYS`, `PAD`, `REMAP`, `INPUT` (`P`, `R`). Do not use `;` inside a column (it splits the line;
  check that no line has more than 7 columns).
- Copy `games.lst` to the Pi (`~/share/games.lst`) and restart the service; no build is needed for it.
- One commit after every 5 to 10 games.

## Helpers

- The web remote control (`/key`, `/screen`) and `raspberry/gametest.sh` (a screenshot of every game) save time.
- `PMD_SNDLEVEL=1` tells a silent game from a lost sound, see [service.md](service.md#sound).
- For games controlled by the function keys: find out from the instructions which of `K0`-`K3` are the directions,
  then `REMAP` (`Up=F1,...`); the original keys keep working.

## Gamepad on the Pi (hot-plug, found by the rescan)

The pad must work however it gets connected. The emulator opens a pad from the device event and, as a second chance, from a
rescan every 2 seconds (`Gamepad: <name> (found by the rescan)` in the journal). Check each case and write down what the journal says
(`journalctl -u pmd85 | grep -i gamepad`; `PMD_PADTRACE=1` in `~/pmd85.env` also prints the pad events and the inputs):

1. **Pad plugged in before the Pi boots** (power up with the pad connected): a `Gamepad: <name>` line after the boot, and the D-pad
   moves the menu selection. This case was reported as not working.
2. **Pad plugged in while the service runs:** the `Gamepad:` line appears, the pad works without a restart.
3. **Pad unplugged and plugged in again:** `Gamepad removed: <name>`, then `Gamepad: <name>`; the keys do not stay pressed.
4. **Pad that is already held when it is opened** (hold a button while plugging in): no stuck key afterwards, release works.
5. **A game with the pad in it:** JOE1 (D-pad right starts it, A jumps), JETPAC with the joystick in the menu (`4`): the D-pad and A move
   and fire; JSWILLY with `1` = JOYSTICK A: A (jump) does not pause the game.
6. **Two pads (or the pad and a keyboard that SDL reports as a joystick):** none keeps a direction pressed.

On the PC a pad can be tested without one: `PMD_VIRTPAD=<file>` attaches a virtual game controller inside the process, the first two
bytes of the file are the pressed buttons (see [usage.md](usage.md)); `PMD_PADSKIPADDED=1` ignores the device events, so only the
rescan can open it.

