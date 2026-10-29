# Installation

[← back to README](../README.md)

Raspberry Pi OS Trixie Lite 32-bit, written with Raspberry Pi Imager, tested on a Pi A+.

## 1. Write the card

Raspberry Pi Imager:

- Device: **Raspberry Pi Zero/1** (the A+ is ARMv6).
- OS: *Raspberry Pi OS (other)* > *Raspberry Pi OS Lite (32-bit)*.
- In the customisation dialog set:

| Setting | Value |
|---|---|
| hostname | `pmd85` |
| user + password | `pmd85` / your password |
| wireless LAN | SSID, password, country (skip when using Ethernet) |
| services | enable SSH (password or public key) |

Write the card, put it into the Pi (monitor connected and switched on), power on and wait for the first boot
(several minutes on the A+, it resizes the card and applies the settings).

## 2. Deploy from the PC

The Pi needs the network, and `deploy.sh` needs sudo without a password:

```sh
ssh pmd85@pmd85.local 'echo "pmd85 ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/010_pmd85'
raspberry/deploy.sh pmd85@pmd85.local
```

The script builds on the Pi (about 10 minutes), installs ROMs, tapes and `games.lst` to `~/share`, and installs and
starts `pmd85.service`, the HDMI wait/hotplug script and the persistent journal.
Details and options: [service.md](service.md).

## 3. Faster boot (optional)

Cloud-init, swap resize and network wait take about 2 minutes on the A+:

```sh
scp raspberry/fastboot pmd85@pmd85.local:
ssh pmd85@pmd85.local 'sudo ./fastboot apply'
```

`fastboot revert` restores the originals. Wi-Fi profiles are not recreated, only DHCP Ethernet.

## 4. Splash screen (optional)

A random scene on every boot, see [splash.md](splash.md). On the Pi:

```sh
sudo apt install plymouth plymouth-themes
sudo cp -r theme-pmd85 /usr/share/plymouth/themes/    # copy the directory to the Pi first
sudo plymouth-set-default-theme -R theme-pmd85        # rebuilds the initramfs, takes minutes
```

`/boot/firmware/cmdline.txt` needs `quiet splash plymouth.ignore-serial-consoles` (the Imager image has them).

## 5. Settings (optional)

`~/pmd85.env`, `chmod 600`, one `VAR=value` per line. Then `sudo systemctl restart pmd85`.

| Variable | Meaning |
|---|---|
| `PMD_WEB=8085`, `PMD_WEB_TOKEN=<secret>` | remote control from a browser, see [remote.md](remote.md) |
| `SDL_AUDIODRIVER=alsa`, `AUDIODEV=plughw:0,0` | HDMI sound (`plughw:1,0` is the headphone jack) |

All emulator variables are in [usage.md](usage.md).

## 6. Check

```sh
systemctl status pmd85
journalctl -b -u pmd85        # log of the emulator, kept over reboots
vcgencmd get_throttled        # 0x0 is OK, 0x50005 = weak power supply
```

## Overclocking

Overclocking helps on the Pi A+: the emulation and the sound (the speaker samples are generated in real time,
a late emulation thread is a dropout) need the headroom.

- The *Medium* preset is 900 MHz: `arm_freq=900`, `over_voltage=2` in `/boot/firmware/config.txt`.
- A good power supply is required, undervoltage throttles the clock back.
- `deploy.sh -o` sets the overclock too, takes effect after a reboot.

## Build without `deploy.sh`

On the Pi (needs `libsdl2-dev`, `libsdl2-ttf-dev` and a C++ compiler):

```sh
cd simpmd
make clean
make PMD_BUILD=RELEASE PMD_SHARE="$HOME/share/"
```

`PMD_SHARE` is compiled in. It is the directory (with a trailing slash) that holds, in one flat directory:

- the ROMs `M1` and `M2-Patched-Tape`,
- the font `atari-classic.ttf`,
- the logos `*.bmp`,
- `games.lst`,
- the game tapes.

`raspberry/deploy.sh` creates it as `~/share`. A change of `sim_common.h` rebuilds everything (about 10 minutes on the A+).
