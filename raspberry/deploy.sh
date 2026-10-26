#!/bin/bash
# Deploy simpmd to a Raspberry Pi (Raspberry Pi OS Bookworm/Trixie) over SSH: sync sources, install
# build dependencies, build, install data to ~/share, install and enable pmd85.service.
#
# Usage: raspberry/deploy.sh [-p ssh-port] [-i identity] [-n] [-o] [user@]host
#   -n    do not enable/start the systemd service (build and install data only)
#   -o    overclock: set arm_freq=1000, gpu_mem=128 and vc4-kms-v3d in config.txt (real Pi only,
#         takes effect after reboot; prints vcgencmd get_throttled)
#
# Needs: rsync and ssh locally; passwordless sudo for the remote user (only for missing packages, the
# service and -o; use -n and install the service by hand otherwise).
set -euo pipefail

PORT=22; IDENT=(); SERVICE=1; OVERCLOCK=0
while getopts p:i:no opt; do
	case $opt in
		p) PORT=$OPTARG ;;
		i) IDENT=(-i "$OPTARG" -o IdentitiesOnly=yes) ;;
		n) SERVICE=0 ;;
		o) OVERCLOCK=1 ;;
		*) sed -n '2,10p' "$0"; exit 2 ;;
	esac
done
shift $((OPTIND - 1))
[ $# -eq 1 ] || { sed -n '2,10p' "$0"; exit 2; }
HOST=$1

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SSH_OPTS=(-p "$PORT" "${IDENT[@]}" -o StrictHostKeyChecking=accept-new)
rssh() { ssh "${SSH_OPTS[@]}" "$HOST" "$@"; }

echo "== sync sources"
rssh 'mkdir -p pmd85console'
rsync -a --delete -e "ssh ${SSH_OPTS[*]}" \
	--exclude '*.o' --exclude '*.dep' --exclude 'simpmd/bin/simpmd' \
	"$ROOT/simpmd" "$ROOT/raspberry" "$HOST:pmd85console/"

echo "== install packages, build, install data"
rssh 'bash -se' <<'REMOTE'
set -euo pipefail
cd ~/pmd85console
PKGS="build-essential libsdl2-dev libsdl2-ttf-dev libasound2-dev libgl1-mesa-dri"
MISSING=$(for p in $PKGS; do dpkg -s "$p" >/dev/null 2>&1 || echo "$p"; done)
if [ -n "$MISSING" ]; then
	sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $MISSING
fi
mkdir -p ~/share simpmd/bin
cp -n simpmd/data/roms/M* simpmd/data/font/* simpmd/data/logo/* \
	simpmd/data/tapes/games-pmd1/* simpmd/data/tapes/games-pmd2/* ~/share/
cp -f simpmd/data/games.lst ~/share/
cd simpmd/src
make clean
make -j"$(nproc)" PMD_BUILD=RELEASE PMD_SHARE="$HOME/share/"
ls -l ../bin/simpmd
REMOTE

if [ "$SERVICE" = 1 ]; then
	echo "== install service"
	rssh 'bash -se' <<'REMOTE'
set -euo pipefail
sed "s|@USER@|$USER|g; s|@HOME@|$HOME|g" ~/pmd85console/raspberry/pmd85.service \
	| sudo tee /etc/systemd/system/pmd85.service >/dev/null
sudo install -m 755 ~/pmd85console/raspberry/pmd85-hdmi /usr/local/sbin/pmd85-hdmi
sudo install -m 644 ~/pmd85console/raspberry/99-pmd85-hdmi.rules /etc/udev/rules.d/99-pmd85-hdmi.rules
sudo udevadm control --reload
sudo systemctl daemon-reload
sudo systemctl enable pmd85.service
systemctl cat pmd85.service | sed -n '1,12p'
REMOTE
fi
if [ "$OVERCLOCK" = 1 ]; then
	echo "== overclock (config.txt)"
	rssh 'bash -se' <<'REMOTE'
set -euo pipefail
CFG=/boot/firmware/config.txt
[ -f "$CFG" ] || CFG=/boot/config.txt
if [ ! -f "$CFG" ]; then
	echo "config.txt not found (not a real Pi?), skipping"; exit 0
fi
sudo cp -n "$CFG" "$CFG.pmd85.bak"
# drop a previous block, then append a fresh one (idempotent)
sudo sed -i '/^# pmd85 begin/,/^# pmd85 end/d' "$CFG"
{
	echo "# pmd85 begin"
	echo "[all]"
	echo "arm_freq=1000"
	echo "gpu_mem=128"
	grep -q '^dtoverlay=vc4-kms-v3d' "$CFG" || echo "dtoverlay=vc4-kms-v3d"
	echo "# pmd85 end"
} | sudo tee -a "$CFG" >/dev/null
sed -n '/^# pmd85 begin/,/^# pmd85 end/p' "$CFG"
echo "backup: $CFG.pmd85.bak; reboot to apply"
if command -v vcgencmd >/dev/null; then
	vcgencmd get_throttled || true
	echo "(0x0 = OK; 0x50005 = undervoltage + throttling: fix the power supply before overclocking)"
	vcgencmd measure_clock arm || true
fi
REMOTE
fi
echo "== done"
