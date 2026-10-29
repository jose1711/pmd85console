# Deployment and the service

[← back to README](../README.md)

## `deploy.sh`

```sh
raspberry/deploy.sh [-p port] [-i identity] [-n] [-o] [user@]host
```

It copies `simpmd` and `raspberry` to the Pi, installs missing build packages and builds (`PMD_SHARE=$HOME/share/`).
It also installs the tapes and `games.lst` to `~/share` (existing files are kept, `games.lst` is replaced) and
installs and starts `pmd85.service`.

| Option | Meaning |
|---|---|
| `-p port` | SSH port |
| `-i identity` | SSH key |
| `-n` | do not install the service |
| `-o` | overclock, takes effect after a reboot |

## `pmd85.service`

The service starts the emulator at boot.

- [Esc] (held) in the main menu quits the emulator. `systemctl stop/restart pmd85` does not halt the machine.
  The Pi is halted only with `PMD_HALT=1` in `~/pmd85.env` (default off).
- Settings (`PMD_WEB`, `PMD_WEB_TOKEN`, `PMD_RES`, ...) go to `~/pmd85.env`, one `VAR=value` per line, `chmod 600`.
  Restart the service afterwards: `sudo systemctl restart pmd85`.
- Log: `journalctl -b -u pmd85` (persistent journal, `raspberry/journald-pmd85.conf`).
- The service user needs the `input` group (the unit has it).

### Start steps (`pmd85-hdmi`)

The helper `raspberry/pmd85-hdmi` (installed as `/usr/local/sbin/pmd85-hdmi`) runs before the emulator:

| Step | What it does |
|---|---|
| `wake` | Wakes the TV over HDMI-CEC: the Pi announces itself as a playback device and sends *Image View On* and *Active Source*. Needs `cec-ctl` from v4l-utils and a TV with CEC enabled, otherwise it does nothing. |
| `keymap` | Rewrites the keymap of the CEC input device: OK gives Enter, Back gives Esc, see [remote.md](remote.md#tv-remote-control-hdmi-cec). Needs python3. |
| `wait` | Waits up to 45 s for a connected HDMI output. The emulator starts anyway (web remote only). |
| `hotplug` | Called by udev (`99-pmd85-hdmi.rules`) on a display change: restarts the service when a monitor appears that was not there at the start. |

## Sound

Sound goes straight to ALSA (PipeWire is slow here). The emulator asks for mono 8-bit, which HDMI refuses on `hw:`,
so use the converting `plughw:` device. In `~/pmd85.env`:

| Output | Settings |
|---|---|
| HDMI | `SDL_AUDIODRIVER=alsa`, `AUDIODEV=plughw:0,0` |
| headphone jack | `SDL_AUDIODRIVER=alsa`, `AUDIODEV=plughw:1,0` |

`aplay -l` lists the cards. Without these settings SDL picks the default device.

If the sound drops out, set `PMD_SNDLEVEL=1` and look at the log:

```sh
journalctl -u pmd85 | grep 'SND level'
```

- `peak 0` and `speaker changes 0`: the game itself is silent (e.g. MANIC plays only some of the time).
- `peak 0` with many `speaker changes`: the sound chain of the emulator loses the sound.
- `generator calls` near 0: the emulation does not run (starved by something else on the single core, e.g. a build).
- `peak` above 0 but nothing is heard: the TV or HDMI does not play it.
Underruns are counted there too; `PMD_SNDLEAD` (default 50 ms) keeps a reserve in the buffer.

## Measuring

`raspberry/bench.sh GAME [secs] [warmup]` (on the Pi) stops the service, runs one game and prints CPU use per thread,
memory and the throttling state, then starts the service again.

`raspberry/gametest.sh` runs every game for N seconds and stores a screenshot and the sound statistics
(`GAMETEST_OUT`, default `~/gametest`).
