![CONSOLE](https://github.com/kyomahooin/pmd85console/raw/master/pmd85console.png "console")

# PMD-85 console

Raspberry Pi 1A+ Tesla PMD-85 retro console powered by modified Petr Tůma
[simpmd](https://github.com/ceresek/simpmd) (c) 2008.

![SCHEMA](https://github.com/kyomahooin/pmd85console/raw/master/pmd85console_schema.png "schema")

![SCREEN](https://github.com/kyomahooin/pmd85console/raw/master/pmd85console_screen.png "screen")

## Features

- Boots straight into a menu of 49 games, the load commands are typed automatically.
- Plays with the keyboard, a gamepad, a TV remote control (HDMI-CEC) or a browser (phone).
- Icons in the games list show which game suits which device.
- Saved state of a game ([Alt]+[F5] save, [Alt]+[F9] load), **experimental and not verified in real play**, see
  [doc/usage.md](doc/usage.md#saved-state-experimental).
- Runs as a service on a Raspberry Pi A+ (KMS/DRM, ALSA directly, no desktop; PipeWire is switched off by `deploy.sh`
  to leave the only core to the emulator).

## Quick start

1. Write Raspberry Pi OS Lite (32-bit) to a card with Raspberry Pi Imager (hostname `pmd85`, SSH on).
2. From the PC: `raspberry/deploy.sh pmd85@pmd85.local` (builds on the Pi, takes about 10 minutes).
3. Connect a monitor or a TV, power on, pick a game.

Details and the optional steps: [doc/install.md](doc/install.md).

## Documentation

| Topic | File |
|---|---|
| Parts, UART, LEDs | [doc/hardware.md](doc/hardware.md) |
| Installation on a Raspberry Pi, overclocking | [doc/install.md](doc/install.md) |
| Deployment, the service, sound, CEC start steps | [doc/service.md](doc/service.md) |
| Running the emulator, test mode, all `PMD_*` variables | [doc/usage.md](doc/usage.md) |
| Games list, `games.lst` format, notes on games | [doc/games.md](doc/games.md) |
| PC keyboard mapping and the PMD 85 keys | [doc/keyboard.md](doc/keyboard.md) |
| Gamepad, TV remote control, web remote control | [doc/remote.md](doc/remote.md) |
| Splash screen (Plymouth) | [doc/splash.md](doc/splash.md) |
| KAREL and KAREL3D commands | [README.karel.md](README.karel.md) |

## TODO

- Menu scroll game preview.
- Sound: long dropouts in the middle of a game are not explained (the buffer lead of 50 ms made the short
  underruns about 20 times rarer); diagnose with `PMD_SNDLEVEL=1`, see [doc/service.md](doc/service.md#sound).
- Saved state: verify it in real play (the sound after loading was not checked by ear), buttons for the gamepad, the TV
  remote and the web page.
- Fix window/renderer duplication (menu, logo and game each have their own window and renderer).
- TV remote: answer the power status requests of the TV (`cec-follower`) and send Active Source again, so the remote
  keeps working after the TV switches to another input.
- Icons of the controls in the games list for the rest of the games, arrows instead of F1-F4 (K0-K3) for games
  that use them, with an option to keep the original keys.

## Known bugs

- `snd flood alsa lib pcm.c:(snd_pcm_recover) underrun occured`
- `mesa loader: failed to retrieve device information`

## Files

```
openscad/               3D printable retro case
raspberry/              Raspberry Pi support scripts (deploy, service, HDMI/CEC helper)
simpmd/                 Modified SDL2 PMD-85 emulator source code by Petr Tůma (c) 2008
theme-pmd85/            Splash Plymouth theme
doc/                    Documentation
screenshots/            Game screenshots
pmd85console.png        Retro console final
pmd85console_schema.png Retro console schematics
simpmd/data/font/atari-classic.ttf   TTF font by Mark Simonson (c) 2016
```

## Source

https://github.com/KyomaHooin/pmd85console
