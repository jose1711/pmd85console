# Hardware

[← back to README](../README.md)

## Parts

| Qty | Part | Note |
|---|---|---|
| 1 | [Raspberry Pi 1A+](http://rpishop.cz/248-raspberry-pi-1a) | |
| 1 | [Power adapter](https://www.ges.cz/cz/usb-napajec-napajeci-adapter-mw-5v-1-2a-sun-usb-GES07507424.html) | 5 V 1.2 A |
| 1 | [USB Wifi dongle](https://www.mironet.cz/edimax-wireless-nano-usb-20-adapter-80211n-150mbps-sw-wps+dp117994/) | RTL8188CUS, 50-75 mA |
| 1 | [HDMI cable](https://www.czc.cz/gembird-cablexpert-kabel-hdmi-hdmi-0-5m-1-4-m-m-stineny-zlacene-kontakty-cerna/248060/produkt) | 0.5 m |
| 1 | [Micro USB cable](https://www.alza.cz/roline-usb-2-0-usb-am-micro-usb-bm) | 1 m |
| 1 | [USB FTDI TTL/UART](https://www.aliexpress.com/item/New-High-Quality-USB-To-TTL-Serial-Module-FTDI-FT232RL-USB-3-3V-5V-To-TTL/32971767031.html) | 3.3 V, 6-pin |
| 1 | MicroSD | 2 GB |
| 1 | Keyboard | Chicony KU-0108s, 100 mA |
| 1 | [Green LED](https://www.ges.cz/cz/l-934gd-GES10700054.html) | 3 mm, 10 mA, 2.2 V |
| 1 | [Red LED](https://www.ges.cz/cz/l-934id-GES10701762.html) | 3 mm, 10 mA, 2 V |
| 1 | [Resistor 120R](https://www.ges.cz/cz/rm0207-120r-1-GES05300318.html) | |
| 1 | [Resistor 150R](https://www.ges.cz/cz/rm0207-150r-1-GES05300319.html) | |
| 1 | [BLS 02](https://www.ges.cz/cz/bls-02-GES06614037.html) | |
| 2 | [BLS 01](https://www.ges.cz/cz/bls-01-GES06614525.html) | |
| 4 | [BLS contact](https://www.ges.cz/cz/bls-contacts-GES06614047.html) | |
| 1 | [Copper wire](https://www.ges.cz/cz/liyv-14-bl-GES06913880.html) | 0.14 mm, 1 m |
| 4 | [Screw](https://www.ges.cz/cz/esst-m2-2x6-GES06814889.html) | M2.2x6 mm |

The 3D printable case is in `openscad/`.

A weak power supply is the most common source of trouble: crackling sound, slowdowns, random reboots.
Check it with `vcgencmd get_throttled` (`0x0` is fine, `0x50005` means undervoltage and throttling).

## UART

A serial console is useful when the network does not come up.

```
3.3V UART => | x | x | GND | TX | RX | ..
             | x | x |  x  | x  | x  | ..
```

```sh
minicom -D /dev/ttyUSB0 -b 115200
```

In minicom: `[Ctrl] > [A] > [Z] > [O] > Serial port setup > [F]low control > Off`.

## LEDs

A red power LED and a green activity LED on the GPIO header.

```
.. |  x  | x | x | x |  x  | x | x | x | GND | 16 | x | x |
.. | 3v3 | x | x | x | GND | x | x | x |  x  | x  | x | x |

           [RED]                    [GREEN]
            | |                       | |
     150R --  |                120R --  |
     [BGB]     -- 3.3V[17]     [BRB]     -- GPIO16[36]
       |                         |
      GND[25]                   GND[34]
```

`/boot/config.txt`:

```ini
# PWR LED (disable onboard)
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off

# ACT LED GPIO16 [36]
dtparam=act_led_gpio=16
dtparam=act_led_trigger=cpu
```
