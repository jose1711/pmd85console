#!/bin/sh
# Lokalny build simpmd z aktualneho repa + spustenie (bez sudo, nic sa neinstaluje do /usr).
#   tools/run-local.sh            prebuildovat (ak treba), obnovit data a spustit
#   tools/run-local.sh -n         len prebuildovat a obnovit data
#   tools/run-local.sh JETPAC     prebuildovat a rovno spustit hru (nazov podla games.lst, na velkosti pismen nezalezi)
#   tools/run-local.sh --list     vypisat nazvy hier
# Build: ~/tmp/simpmd-local/{src,bin}, data (plochy adresar): /data/jose/tmp/ss-share/ (PMD_SHARE)
set -e
REPO=$(cd "$(dirname "$0")/.." && pwd)/simpmd
L=$HOME/tmp/simpmd-local
SHARE=/data/jose/tmp/ss-share/
mkdir -p "$L/src" "$L/bin" "$SHARE"
cp "$REPO/Makefile" "$L/Makefile"
rsync -a --delete --exclude='*.o' --exclude='*.dep' "$REPO/src/" "$L/src/"
make -C "$L/src" -j"$(nproc)" PMD_BUILD=RELEASE PMD_SHARE="$SHARE" >"$L/build.log" 2>&1 || { tail -30 "$L/build.log"; exit 1; }
cp -u "$REPO"/data/roms/* "$REPO"/data/font/* "$REPO"/data/logo/* "$SHARE"
find "$REPO/data/tapes" -type f -exec cp -u {} "$SHARE" \;
cp "$REPO/data/games.lst" "$SHARE/games.lst"
echo "build OK: $L/bin/simpmd, data: $SHARE"
[ "$1" = "-n" ] && exit 0
cd "$L/bin" && exec ./simpmd "$@"
