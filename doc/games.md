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
NAME;MODEL;NOTE[;REMAP[;PAD[;KEYS[;INPUT]]]]
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

### `REMAP`

`HostKey=PmdKey,...` with SDL key names, e.g. `Left=Left Shift,Right=V`.
It applies to the keyboard, the gamepad and the browser alike.

- AUTO and ZED steer with [Shift] (left) and [V] (right) on the PMD 85, here with the cursor keys.
- MANIC: [Space] is mapped to [Shift] (jump), so the D-pad and the jump are on different hands.
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
  On the TV remote: the digits `0`-`3`, OK (Enter is remapped to [Space]) fires.

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
