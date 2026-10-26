#!/bin/bash
# Measure CPU and memory of simpmd on the Pi: stops pmd85.service, runs one game for WARMUP + SECS seconds,
# prints CPU use of the whole process and per thread, RSS and the throttling state, starts the service again.
#
# Usage: raspberry/bench.sh GAME [secs] [warmup]   (run on the Pi; extra PMD_* variables are passed through,
# SUDO="sudo -A" with SUDO_ASKPASS if sudo needs a password)
set -u
GAME=${1:?game name from games.lst}; SECS=${2:-60}; WARMUP=${3:-45}
HZ=$(getconf CLK_TCK)
SUDO=${SUDO:-sudo}
$SUDO systemctl stop pmd85
trap 'kill $PID 2>/dev/null; $SUDO systemctl start pmd85' EXIT
set -a; . ~/pmd85.env 2>/dev/null; set +a
unset PMD_WEB
cd ~/share
PMD_GAME=$GAME ~/pmd85console/simpmd/bin/simpmd >/tmp/bench.log 2>&1 &
PID=$!
sleep "$WARMUP"
kill -0 $PID 2>/dev/null || { echo "simpmd died"; tail /tmp/bench.log; exit 1; }
ticks() { awk '{print $14+$15}' /proc/$PID/stat; }
T0=$(ticks); S0=$(date +%s.%N)
declare -A TH0
for t in /proc/$PID/task/*; do TH0[$(basename $t)]=$(awk '{print $14+$15}' $t/stat); done
sleep "$SECS"
T1=$(ticks); S1=$(date +%s.%N)
echo "game=$GAME secs=$SECS freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) throttled=$(vcgencmd get_throttled)"
echo "cpu_total=$(echo "($T1-$T0)/$HZ/($S1-$S0)*100" | bc -l | xargs printf '%.1f')%"
for t in /proc/$PID/task/*; do
	id=$(basename $t); [ -n "${TH0[$id]:-}" ] || continue
	d=$(( $(awk '{print $14+$15}' $t/stat) - ${TH0[$id]} ))
	printf '  thread %-6s %-16s %5.1f%%\n' "$id" "$(cat $t/comm)" "$(echo "$d/$HZ/($S1-$S0)*100" | bc -l)"
done
echo "rss_kb=$(awk '/VmRSS/{print $2}' /proc/$PID/status)"
