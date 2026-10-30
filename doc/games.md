# Games and the games list

[← back to README](../README.md)

## The list

The menu shows four games with logos. [Up] or [E] (gamepad up) opens the list of all games from `games.lst`
in the share directory. `simpmd/data/games.lst` lists the tapes of `simpmd/data/tapes` that work, according to the
table in `simpmd/README`.

| Key | In the list |
|---|---|
| [Up] / [Down] or [E] / [Y] | select |
| [Left] / [Right] | move by a page |
| [Enter] | start |
| [Esc] (hold it) | back to the menu |

After the start the emulator types the commands itself: `MGLD 00` and, for `MGLD 00, JUMP 2000`, the `JUMP` once
the tape stops loading, so selecting a game is enough. `PMD_AUTOLOAD=0` turns it off (type the commands by hand).

`POKE <hex address> <hex value>` in the note writes a byte to the memory once the tape has stopped loading; put it
after `JUMP`, because a game clears its variables when it starts. It is for a game that reads a variable it never sets
(the RAM of the real PMD 85 is not cleared at power on, here it is zero): CROSSI (Kamikadze) hangs in its explosion
routine when `39A4` is 0, so its note is `MGLD 00, JUMP 0000, POKE 39A4 01`.

To add a game, copy its tape to the share directory and add a line to `games.lst`.

### Icons

Icons left of the name show what the game can be played with besides the keyboard
(the legend is at the bottom of the list):

| Icon | Meaning |
|---|---|
| gamepad | the buttons of a gamepad are enough, see [remote.md](remote.md#gamepad) |
| TV remote | the TV remote control over HDMI-CEC is enough (cursor keys, OK, digits), see [remote.md](remote.md#tv-remote-control-hdmi-cec) |

A game without icons is keyboard only (text adventures, games that need many action keys) or its controls are not
known yet.

## Format of `games.lst`

One line per tape, columns separated by `;` (do not use `;` inside a column), `#` starts a comment.

```
NAME;MODEL;NOTE[;REMAP[;PAD[;KEYS[;INPUT[;CATEGORY]]]]]
```

| # | Column | Meaning |
|---|---|---|
| 1 | `NAME` | the tape file in the share directory |
| 2 | `MODEL` | `1` or `2`: the PMD 85-1 ROM `M1` or the PMD 85-2 ROM `M2-Patched-Tape` |
| 3 | `NOTE` | shown in the list, the commands to type (`MGLD 00, JUMP 2000`) |
| 4 | `REMAP` | host keys mapped to other PMD 85 keys for this game |
| 5 | `PAD` | buttons of the web remote control for this game |
| 6 | `KEYS` | free text with the controls, shown under the list (without diacritics) |
| 7 | `INPUT` | devices besides the keyboard: `P` gamepad, `R` TV remote |
| 8 | `CATEGORY` | a sub list of the games list (see below), empty for the games of the main list |

### `CATEGORY`

The games list shows the categories first, as rows `[ Name ] (number of games)`, then the games without a category.
[Enter] opens a category, its first row `(o uroven vys)` (or a held [Esc]) goes back to the main list. A category exists
as soon as a game names it (the order is the order of the first game in `games.lst`); the name is shown as it is
written, without diacritics. The columns before it must be there, empty if needed (`ZMRZLINY;2;MGLD 00;;;;;Pro nejmensi`).
The web remote control gets the same rows. Now: `Pro nejmensi` (DOMCEKY, POSTARIK, ROBOTIK, ZMRZLINY, SASKO), `Dema`
(FERLAJT, KANKAN), `Programovani` (KAREL, KAREL3D).

### `REMAP`

`HostKey=PmdKey,...` with SDL key names, e.g. `Left=Left Shift,Right=V`.
It applies to the keyboard, the gamepad and the browser alike.

- AUTO and ZED steer with [Shift] (left) and [V] (right) on the PMD 85, here with the cursor keys.
- MANIC: [Space] is mapped to [Shift] (jump), so the D-pad and the jump are on different hands.
- MANIC with a remote control: `Up=@Left Shift,Down=A`. [Up] jumps in the direction of the walk: press [Left] or
  [Right] first, then [Up] (within 400 ms of releasing the arrow); standing still, [Up] jumps straight up. The `@`
  before the target key means: also press the cursor key last used. A remote control can not press two keys at once.
  OK stays [Enter] (start of the game, end of the initials) and [Down] types `A`, so the initials after a game
  ("AAAAA") can be typed with the remote.

### Short, long and held keys in `REMAP`

`HostKey=Short|Long[|Held]` (any key of `REMAP`):

| Part | When it is sent |
|---|---|
| `Short` | a press shorter than 450 ms: sent when the key is released, held for 150 ms (a game that scans the keyboard slowly still sees it) |
| `Long` | a press longer than 450 ms, instead of `Short` |
| `Held` | optional, at once when the key goes down and until it is released (a jump must not wait for the release); `@Key` also presses the cursor key last used (held, or released less than 400 ms ago) |
- INVADERS: [End] / [PageDown] are the fast arrows, the digits `0`-`3` are on the gamepad.

### `PAD`

`Label:key,...` (SDL key names), e.g. `Left:Left,Fast left:End,Fire:Space,0:0`.

- `key&key` presses two keys at once (a mouse presses only one button), e.g. `Jump left:Left Shift&Left` in MANIC.
- Games without `PAD` get the default set: E, Y, cursor keys, Space, Enter, H, I, Shift, RCL, Esc.
- The menus get a short set.
- The keys known from the code of the games are in `games.lst` (INVADERS: fast arrows, fire and the difficulty
  digits; AUTO, ZED, MANIC, SASKO, ...).

### `KEYS`

Free text shown under the list for the selected game. "neznamo" is shown for games without it
(many games do not print their keys).

### `INPUT`

- `P`: the gamepad is enough (its buttons: D-pad/E/Y, Space, Enter, H, I, Shift, RCL).
- `R`: the TV remote is enough. The rule used to fill it: the game needs at most 5 buttons (the keys of `PAD`
  without [Esc] and without the keys that `REMAP` maps onto) and all of them are on the remote (cursor keys,
  OK = Enter, digits). A game that asks for letters (name or initials for the high scores, passwords, commands)
  never gets `R`, whatever the number of buttons; see [remote.md](remote.md#tv-remote-control-hdmi-cec).

## Notes on games

### INVADERS

- The ship moves by 3 steps with the fast arrows [End] and [PageDown] (the keys LLEFT and RRIGHT of the PMD 85);
  the gamepad [LB] and [RB] send them.
- The difficulty is `0`-`3` (4 is not playable). On the gamepad: D-pad up = 0, D-pad down = 1, [X] = 2, [Y] = 3.
  The TV remote plays in a limited mode: OK (Enter) is remapped to [Space], so it fires, and the cursor up and down
  select the difficulty `0` and `1` (the tested TV does not send the digits over CEC, so `2` and `3` are only on the
  gamepad). The fast arrows are not on the TV remote either.

### MANIC

- Loads with `MGLD 02` (MANIC+) or `MGLD 00` (MANIC-1).
- Cursor keys, [Shift] (jump), [S], [F1]; [F1] is a menu key.

### KAREL, KAREL3D

The games have no manual, the commands are in [README.karel.md](../README.karel.md).

### MESTO (Mesto robotu)

A text adventure. It asks for a password after the intro screens: `konvalinka` (case does not matter).
The game body is encrypted with a key made of the password (the password is not stored anywhere),
so a wrong one starts garbage.

### BOULDER

The second `H` may be lost when typing, `PMD_KEY_MS=400` makes it pass.

## Screenshots

Captured with `PMD_SCREENSHOT` (see [usage.md](usage.md)).

| FLAPPY | FRED | BOULDER DASH (game menu) |
|:------:|:----:|:------------------------:|
| ![FLAPPY](../screenshots/flappy.png "flappy") | ![FRED](../screenshots/fred.png "fred") | ![BOULDER](../screenshots/boulder.png "boulder") |
