#!/bin/bash
# Back up this handheld's internal eMMC to the SD card the script lives on, in 1 GiB pieces
# (works on FAT32/exFAT); each piece is hashed while read, then re-hashed from the card to verify the copy.
# Works from stock EmuELEC (script in /storage/roms/ports_scripts) and from ArkOS4Clone (/roms/ports).
# Writes only to <card>/emmc-backups/<unit>-<date>/ ; the eMMC is only read.
if [ "$(id -u)" = 0 ]; then ESUDO=""; else ESUDO=sudo; fi
HERE="$(dirname "$(readlink -f "$0")")"
CARD="$(cd "$HERE/.." && pwd)"
say() { echo "$*" | tee -a "$LOG"; printf '%s\n' "$*" | $ESUDO tee /dev/tty1 >/dev/null 2>&1; }

# find the internal eMMC (block device whose controller reports type MMC)
DEV=""
for b in /sys/block/mmcblk*; do
  [ "$(cat "$b/device/type" 2>/dev/null)" = "MMC" ] && { DEV="/dev/$(basename "$b")"; break; }
done
STAMP=$(date +%Y%m%d-%H%M%S)
UNIT=$(cat "/sys/block/$(basename "${DEV:-none}")/device/cid" 2>/dev/null | cut -c1-12)
OUT="$CARD/emmc-backups/${UNIT:-unknown}-$STAMP"
mkdir -p "$OUT" || exit 1
LOG="$OUT/dump.log"
say "== gameguy eMMC dump $STAMP"
[ -n "$DEV" ] && [ -b "$DEV" ] || { say "No internal eMMC found."; ls /sys/block >> "$LOG"; sleep 6; exit 1; }
SECT=$(cat "/sys/block/$(basename "$DEV")/size")
BYTES=$((SECT * 512))
say "eMMC $DEV: $SECT sectors ($((BYTES / 1000000)) MB), cid $(cat /sys/block/$(basename $DEV)/device/cid 2>/dev/null)"
FREE=$(df -Pk "$OUT" | awk 'NR==2 {print $4}')
if [ $((FREE * 1024)) -lt $((BYTES + 64 * 1024 * 1024)) ]; then
  say "Not enough space on the card: need $((BYTES / 1000000)) MB, have $((FREE / 1000)) MB."; sleep 8; exit 1
fi
{ cat /proc/partitions; cat /proc/mounts; } >> "$LOG" 2>&1
sync
CHUNK_MB=1024
N=$(( (BYTES + CHUNK_MB * 1048576 - 1) / (CHUNK_MB * 1048576) ))
: > "$OUT/SHA256SUMS"
BAD=0
i=0
while [ $i -lt $N ]; do
  P=$(printf 'emmc.img.part%02d' $i)
  say "piece $((i + 1))/$N: reading ..."
  # one pass over the eMMC: the stream is hashed while it is written to the card
  H1=$($ESUDO dd if="$DEV" bs=1M skip=$((i * CHUNK_MB)) count=$CHUNK_MB 2>> "$LOG" | tee "$OUT/$P" | sha256sum | cut -d' ' -f1)
  sync
  echo 1 | $ESUDO tee /proc/sys/vm/drop_caches >/dev/null 2>&1   # re-read from the card, not RAM
  # one pass over the card: confirms the copy on the card is what was read
  H2=$(sha256sum "$OUT/$P" | cut -d' ' -f1)
  echo "$H1  $P" >> "$OUT/SHA256SUMS"
  if [ "$H1" != "$H2" ]; then say "piece $((i + 1)): card copy does NOT match what was read"; BAD=1; fi
  i=$((i + 1))
done
if [ $BAD = 0 ]; then
  say "VERIFIED: every piece on the card matches what was read from the eMMC."
  echo OK > "$OUT/VERIFIED"
else
  echo MISMATCH > "$OUT/VERIFIED"
fi
say "Saved to $OUT"
sleep 6
