#!/bin/bash
# Runs every game of games.lst (or the games given as arguments) on the Pi, each for SECS seconds (default 180),
# saves a screenshot at the end and the output of the emulator. Run it on the Pi:
#   raspberry/gametest.sh [-t secs] [game ...]
# Results go to ~/gametest (GAMETEST_OUT; not /tmp, a small tmpfs the screenshots fill up): <game>.bmp, <game>.log and summary.txt (game, exit code, sound underruns).
# The service is stopped for the test and started again at the end. Needs `sudo` for that (SUDO="sudo -A" and
# SUDO_ASKPASS=<script> when the user has a password).
SECS=180
[ "${1:-}" = "-t" ] && { SECS=$2; shift 2; }
SUDO=${SUDO:-sudo}
OUT=${GAMETEST_OUT:-$HOME/gametest}
SHARE=${PMD_SHARE_DIR:-$HOME/share}
BIN=${PMD_BIN:-$HOME/pmd85console/simpmd/bin/simpmd}
mkdir -p "$OUT"
GAMES=("$@")
[ ${#GAMES[@]} -gt 0 ] || mapfile -t GAMES < <(grep -v '^#' "$SHARE/games.lst" | cut -d';' -f1)
: > "$OUT/summary.txt"
$SUDO systemctl stop pmd85
cd "$SHARE"
set -a; [ -f ~/pmd85.env ] && . ~/pmd85.env; set +a
for g in "${GAMES[@]}"; do
	rm -f "$OUT/$g.bmp"
	SDL_VIDEODRIVER=kmsdrm PMD_GAME=$g PMD_SNDSTATS=1 PMD_SCREENSHOT="$OUT/$g.bmp" PMD_SCREENSHOT_MS=$((SECS * 1000)) \
		timeout $((SECS + 60)) "$BIN" > "$OUT/$g.log" 2>&1
	rc=$?
	under=$(grep -c "underrun" "$OUT/$g.log")
	echo "$g rc=$rc underrun_lines=$under shot=$([ -s "$OUT/$g.bmp" ] && echo yes || echo no)" >> "$OUT/summary.txt"
done
echo DONE >> "$OUT/summary.txt"
$SUDO systemctl start pmd85
