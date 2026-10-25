![CONSOLE](https://github.com/kyomahooin/pmd85console/raw/master/pmd85console.png "console")

DESCRIPTION

Raspberry Pi 1A+ Tesla PMD-85 retro console powered by modified Petr Tůma <a href="https://github.com/ceresek/simpmd">simpmd</a> (c) 2008.

![SCHEMA](https://github.com/kyomahooin/pmd85console/raw/master/pmd85console_schema.png "schema")

SCREEN

![SCREEN](https://github.com/kyomahooin/pmd85console/raw/master/pmd85console_screen.png "screen")

TODO

- Remove hardcoded paths.
- Menu scroll game preview.
- Fix sound.
- Fix window/renderer duplication.

BUG

- `snd flood alsa lib pcm.c:(snd_pcm_recover) underrun occured`
- `mesa loader: failed to retrieve device information`

HARDWARE

<pre>
1x <a target="_blank" href="http://rpishop.cz/248-raspberry-pi-1a">Raspberry</a> (1A+)
1x <a target="_blank" href="https://www.ges.cz/cz/usb-napajec-napajeci-adapter-mw-5v-1-2a-sun-usb-GES07507424.html">Power adapter</a> (5V 1.2A)
1x <a target="_blank" href="https://www.mironet.cz/edimax-wireless-nano-usb-20-adapter-80211n-150mbps-sw-wps+dp117994/">USB Wifi dongle</a> (RTL8188CUS/50-75mA)
1x <a target="_blank" href="https://www.czc.cz/gembird-cablexpert-kabel-hdmi-hdmi-0-5m-1-4-m-m-stineny-zlacene-kontakty-cerna/248060/produkt">HDMI cable</a> (0.5m)
1x <a target="_blank" href="https://www.alza.cz/roline-usb-2-0-usb-am-micro-usb-bm">Micro USB cable</a> (1m)
1x <a target="_blank" href="https://www.aliexpress.com/item/New-High-Quality-USB-To-TTL-Serial-Module-FTDI-FT232RL-USB-3-3V-5V-To-TTL/32971767031.html">USB FTDI TTL/UART</a> (3.3V 6-pin)
1x MicroSD (2GB)
1x Keyboard (Chicony KU-0108s/100mA)
1x <a target="_blank" href="https://www.ges.cz/cz/l-934gd-GES10700054.html">Green LED</a> (3mm 10mA 2.2V)
1x <a target="_blank" href="https://www.ges.cz/cz/l-934id-GES10701762.html">Red LED</a> (3mm 10mA 2V)
1x <a target="_blank" href="https://www.ges.cz/cz/rm0207-120r-1-GES05300318.html">Resistor 120R</a>
1x <a target="_blank" href="https://www.ges.cz/cz/rm0207-150r-1-GES05300319.html">Resistor 150R</a>
1x <a target="_blank" href="https://www.ges.cz/cz/bls-02-GES06614037.html">BLS 02</a>
2x <a target="_blank" href="https://www.ges.cz/cz/bls-01-GES06614525.html">BLS 01</a>
4x <a target="_blank" href="https://www.ges.cz/cz/bls-contacts-GES06614047.html">BLS contact</a>
1x <a target="_blank" href="https://www.ges.cz/cz/liyv-14-bl-GES06913880.html">Copper Wire</a> (0.14mm 1m)
4x <a target="_blank" href="https://www.ges.cz/cz/esst-m2-2x6-GES06814889.html">Screw</a> (M2.2x6mm)
</pre>

RPI

<pre>
wget --no-check-certificate https://downloads.raspberrypi.org/raspbian_lite_latest
# umount & write SD card / SD reader[!]
umount /dev/sdX[12] 2>/dev/null
unzip -p 2018-11-13-raspbian-stretch-lite.zip | dd of=/dev/sdX bs=4M

touch /boot/ssh
cat << EOF >> /boot/wpa_supplicant.conf
country=CZ
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
	ssid="Wireless LAN"
	scan_ssid=1
	psk="cleartext"
	key_mgmt=WPA-PSK
}
EOF

raspi-config > Advanced > GL Driver > Enable Fake KMS

apt-get update
apt-get install libgl1-mesa-dri

raspi-config > Advanced > GPU mem > 128
raspi-config > Advanced > Overclocking > Medium

dphys-swapfile swapoff
dphys-swapfile uninstall

systemctl disable avahi-daemon bluetooth paxctld rsync triggerhappy triggerhappy.socket nfs-client.target \
                  systemd-timesyncd apt-daily apt-daily.timer apt-daily-upgrade apt-daily-upgrade.timer \
                  dphys-swapfile networking dhcpcd ssh getty@tty1 rc-local wifi-country keyboard-setup \
                  alsa-restore systemd-rfkill

raspberry/deploy.sh [-p port] [-i key] [-n] [-o] user@host   (from the PC: sync, build, data, service; see below)

apt-get install vim mc ntpdate

/etc/fstab:
tmpfs	/tmp	tmpfs	defaults,noatime,nosuid,size=5m	0	0
tmpfs	/var/log	tmpfs	defaults,noatime,nosuid,mode=0755,size=5m	0	0

/etc/dhcpcd.conf:
interface wlan0
static ip_address=192.168.0.85/24
static routers=192.168.0.1
static domain_name_servers=xx.xx.xx.xx xx.xx.xx.xx
</pre>

UART

<pre>
3.3V UART => | x | x | GND | TX | RX | ..
             | x | x |  x  | x  | x  | ..

minicom -D /dev/ttyUSB0 -b 115200

[Ctrl] > [A] > [Z] > [O] > Serial port setup > [F]low control > Off
</pre>

LED

<pre name="led">
.. |  x  | x | x | x |  x  | x | x | x | GND | 16 | x | x |
.. | 3v3 | x | x | x | GND | x | x | x |  x  | x  | x | x |

           [RED]                    [GREEN]
            | |                       | |
     150R --  |                120R --  |
     [BGB]     -- 3.3V[17]     [BRB]     -- GPIO16[36]
       |                         |
      GND[25]                   GND[34]

/boot/config.txt:
# PWR LED(disable onboard)
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off

# ACT LED GPIO16[36]
dtparam=act_led_gpio=16
dtparam=act_led_trigger=cpu
</pre>

PLYMOUTH

<pre>
apt-get install plymouth plymouth-themes -> 0.9.4-1.1(Buster)

cp -r theme-pmd85 /usr/share/plymouth/themes/

plymouth-set-default-theme -R theme-pmd85

/usr/share/plymouth/plymouthd.defaults:
DeviceTimout=10

systemctl disable plymouth-start -> Shutdown/reboot only.

/boot/cmdline.txt:
logo.nologo quiet splash plymouth.ignore-serial-consoles vt.global_cursor_default=0

/boot/config.txt:
boot_delay=0
</pre>

SDL2

<pre>
wget --no-check-certificate https://www.libsdl.org/release/SDL2-2.0.9.tar.gz

apt-get install libgles2-mesa-dev libgbm-dev libudev-dev libasound2-dev liblzma-dev

autogen.sh
./configure --enable-video-kmsdrm --disable-video-opengl --disable-video-x11 --disable-video-rpi
make
make install

wget --no-check-certificate https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.15.tar.gz
autogen.sh
./configure
make
make install
</pre>

SIMPMD

<pre>
make clean
make PMD_BUILD=RELEASE PMD_SHARE=/usr/share/simpmd/
</pre>

`PMD_SHARE` is the directory (with trailing slash) holding ROMs `M1`/`M2-Patched-Tape`, `atari-classic.ttf`, logos `*.bmp`,
`games.lst` and game tapes in one flat directory; `raspberry/deploy.sh` creates it (`~/share`).

RUN

<pre>
bin/simpmd                  # logo -> menu: select game [<-][->], start [Enter] (the load command is typed automatically), quit [Esc]

# Start game directly (skip logo and menu), index: 0 FLAPPY, 1 BOULDER, 2 MANIC+, 3 FRED
PMD_AUTOSTART=0 bin/simpmd

# Start and load game automatically, no keyboard needed (examples, tested)
PMD_AUTOSTART=0 PMD_KEYS='MGLD 03|____H__ ____' bin/simpmd                  # FLAPPY: load, [H] play, [Space] skip controls
PMD_AUTOSTART=3 PMD_KEYS='MGLD 03|____H__ ____' bin/simpmd                  # FRED: load, [H] play, [Space] skip info
PMD_AUTOSTART=1 PMD_KEYS='MGLD 03|________H' bin/simpmd                     # BOULDER: load (~20s), [H] game menu
</pre>

Environment variables (test mode):

<pre>
PMD_AUTOSTART=<0-3>     Skip logo and menu, start selected game.
PMD_GAME=<name>         Skip logo and menu, start a game of games.lst (any of the list).
PMD_KEYS=<text>         Type text on the PMD-85 keyboard, '|' is [Enter], '_' is 2s pause, '<' '>' are the cursor
                        keys left and right, '^' is [Shift], E and Y are up and down in the games.
                        '~' waits until the tape stops loading (2s without a read).
PMD_AUTOLOAD=0         Do not type the load command of the game automatically (default on).
PMD_WEB=<port>          Remote control from a browser, see below. PMD_WEB_TOKEN=<secret> protects it.
PMD_SCREENSHOT=<file>   Save screen as BMP after PMD_SCREENSHOT_MS and exit.
PMD_SCREENSHOT_MS=<ms>  Screenshot delay, default 3000.
PMD_KEY_MS=<ms>         Key press/release time of PMD_KEYS, default 150.
PMD_SNDSTATS=1          Print sound underrun statistics on exit.
PMD_SCALE=<n>           Window size multiplier (288x256 * n), default 3; window is resizable.
PMD_RES=<w>x<h>         Video mode of the menu, logo and fullscreen (must be offered by the display).
PMD_KEYLOG=<file>       Log keyboard and window events, paint duration and queue lag.
PMD_PAD=<input>=<key>,...  Gamepad keys, see below.
</pre>

GAMES LIST

The menu shows four games with logos. [Up] or [E] (gamepad up) opens the list of all games from `games.lst`
in the share directory (one `NAME;MODEL;NOTE` line per tape, `NAME` is the tape file, `MODEL` 1 or 2 selects the
PMD 85-1 or PMD 85-2 ROM `M1` or `M2-Patched-Tape`, `NOTE` is shown in the list, the commands to type).
The emulator types them itself after the start of a game: `MGLD 00` and, for `MGLD 00, JUMP 2000`, the `JUMP`
once the tape stops loading, so selecting a game is enough. `PMD_AUTOLOAD=0` turns it off (type the commands by hand).
[Up]/[Down] or [E]/[Y] select, [Left]/[Right] move by a page, [Enter] starts, [Esc] goes back to the menu.
`simpmd/data/games.lst` lists the tapes of `simpmd/data/tapes` that work, according to the table in `simpmd/README`.
To add a game, copy its tape to the share directory and add a line to `games.lst`.
Start a game of the list directly (test mode): `PMD_GAME=BLUDISTE bin/simpmd`. `PMD_KEYS` replaces the automatic
load command.

DEPLOY AND SERVICE

`raspberry/deploy.sh [-p port] [-i identity] [-n] [-o] [user@]host` copies `simpmd` and `raspberry` to the Pi, installs
missing build packages, builds (`PMD_SHARE=$HOME/share/`), installs the tapes and `games.lst` to `~/share`
(existing files are kept, `games.lst` is replaced) and installs and starts `pmd85.service` (`-n` skips the service,
`-o` overclocks, takes effect after reboot). The service starts the emulator at boot. Esc in the main menu quits
the emulator and halts the machine, `systemctl stop/restart pmd85` does not. Settings (`PMD_WEB`, `PMD_WEB_TOKEN`,
`PMD_RES`, ...) go to `~/pmd85.env`, one `VAR=value` per line, `chmod 600`. Log: `/tmp/pmd85.log`.

Sound goes straight to ALSA (PipeWire is slow here). The emulator asks for mono 8-bit, which HDMI refuses on `hw:`,
so use the converting `plughw:` device: `SDL_AUDIODRIVER=alsa` and `AUDIODEV=plughw:0,0` for HDMI, `plughw:1,0` for the
headphone jack (`aplay -l` lists the cards). Without them SDL picks the default device.

REMOTE CONTROL

`PMD_WEB=<port>` starts a small web server, open `http://<host>:<port>/?t=<token>` in a browser (PC or phone) to see
the screen of the simulated machine and to play: keyboard keys and an on-screen gamepad are sent to the emulator
and work in the menu and in the games (up and down are [E] and [Y]). `PMD_WEB_TOKEN=<secret>` is required in the
URL (`?t=`), without a token everybody on the network can control the machine. The screen is read from the video
memory (12 KB per frame), there is no sound (it plays on the Pi), traffic is plain HTTP, use it on a trusted network only.
Set it in `~/pmd85.env`: `PMD_WEB=8085` and `PMD_WEB_TOKEN=<secret>`. Esc in the main menu asks for confirmation, it
quits the emulator and halts the Pi, Esc in a game returns to the menu. The first typed key waits until the
simulated processor has run 2 s, so the load command is not lost on a slow Pi.

GAMEPAD

A gamepad (USB, or Bluetooth if paired in the OS) works in the menu and in the games, its buttons are
translated to keyboard keys. Defaults follow the instructions of the games: D-pad and left stick up/down = [E] and [Y] (the PMD 85 keys for
up and down, host key Z), left/right = cursor keys, [A] = Space, [B] and [Start] = Enter, [X] = H, [Y] = I,
[LB] = Shift (jump in MANIC+), [RB] = keypad plus (RCL), [Back] = Escape (game back to menu, in the menu quit).
Override with `PMD_PAD`, inputs `up down left right a b x y lb rb back start`, keys are SDL key names:

<pre>
PMD_PAD='up=Up,down=Down,a=Space,lb=Left' bin/simpmd
</pre>

Pads without an SDL controller mapping use a common layout (hat or axes 0/1 = D-pad, buttons 0-7 = a b x y lb rb back start).

Keys after `MGLD 03|` depend on the game, add `_` pauses so the tape load finishes first (BOULDER ~20s, FLAPPY/FRED ~8s).
MANIC+ loads with `MGLD 02` (not 00 or 03), [Enter] starts the game:
`PMD_AUTOSTART=2 PMD_KEYS='MGLD 02|____________|' bin/simpmd`.
BOULDER: the second `H` may be lost, `PMD_KEY_MS=400` makes it pass.

GAMES

Screenshots captured with `PMD_SCREENSHOT` (examples above).

| FLAPPY | FRED | BOULDER DASH (game menu) |
|:------:|:----:|:------------------------:|
| ![FLAPPY](screenshots/flappy.png "flappy") | ![FRED](screenshots/fred.png "fred") | ![BOULDER](screenshots/boulder.png "boulder") |

HEADLESS

No monitor needed, video goes to software renderer and sound to file `sdlaudio.raw`:

<pre>
cd /tmp
PMD_AUTOSTART=0 PMD_KEYS='MGLD 03|____H__ ____' PMD_SCREENSHOT=/tmp/game.bmp PMD_SCREENSHOT_MS=34000 \
SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIODRIVER=disk bin/simpmd
</pre>

FILE

<pre>
              openscad/ - 3D printable retro case.
             raspberry/ - Raspbery support scripts.
                simpmd/ - Modified SDL2 PMD-85 emulator source code by Petr Tůma (c) 2008.
           theme-pmd85/ - Splash Plymouth theme.

       pmd85console.png - Retro console final.
pmd85console_schema.png - Retro console schematics.
      atari-classic.ttf - TTF font by Mark Simonson (c) 2016.
</pre>

SOURCE

https://github.com/KyomaHooin/pmd85console

