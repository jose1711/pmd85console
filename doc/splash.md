# Splash screen (Plymouth)

[← back to README](../README.md)

The theme `theme-pmd85` has 24 scenes (computer drawing, 4 game logos, monitor, tape loading and the photos of the
PMD 85). It starts with a random one on every boot and changes the picture to the next one every 30 seconds
(`SCENE_SECONDS` in `theme-pmd85.script`), under it a block progress bar with a blinking cursor.

## Install

```sh
apt-get install plymouth plymouth-themes          # 0.9.4-1.1 (Buster)
cp -r theme-pmd85 /usr/share/plymouth/themes/
plymouth-set-default-theme -R theme-pmd85         # -R rebuilds the initramfs
```

## Settings

`/usr/share/plymouth/plymouthd.defaults`:

```ini
DeviceTimout=10
```

`/boot/cmdline.txt`:

```
logo.nologo quiet splash plymouth.ignore-serial-consoles vt.global_cursor_default=0
```

`/boot/config.txt`:

```ini
boot_delay=0
```

To show the splash only on shutdown and reboot: `systemctl disable plymouth-start`.

## Adding a scene

- The scenes 1-7 are drawn by `theme-pmd85/make-splash.py` (Pillow), the next ones are the photos of `theme-photos/`
  (`.jpg` or `.png`, in the order of their names) scaled down to fit 830x570. To add a photo, put it to `theme-photos/`
  and run `python3 -I make-splash.py` in `theme-pmd85/`; it writes `scene-N.png`, `scenes.count` and `SCENES` of
  `theme-pmd85.script`. The originals stay out of the theme (they would go to the initramfs).
- Plymouth reads PNG only, a scene is read when it is shown (every 30 s), keep the photos small.
- Rebuild the initramfs (`plymouth-set-default-theme -R theme-pmd85`).
- The change of the pictures is not tested with plymouthd (it needs the console and root), only the layout of the scenes
  was checked.
