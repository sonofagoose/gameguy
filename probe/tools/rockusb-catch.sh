#!/usr/bin/env bash
# Wait for a Rockchip device in rockusb/loader mode (USB 2207:330d, "USB download gadget"), grab it
# immediately so U-Boot stays in download mode, read identification, then keep it alive with a cheap
# command every second. Read-only: no writes, no erase.
# Usage: rockusb-catch.sh [OUTDIR] [KEEPALIVE_SECONDS]
OUT=${1:-/tmp/rockusb}
KEEP=${2:-600}
mkdir -p "$OUT"
echo "waiting for 2207:xxxx ..."
for _ in $(seq 1 36000); do
  if lsusb -d 2207: >/dev/null 2>&1; then break; fi
  sleep 0.1
done
lsusb -d 2207: || { echo "no Rockchip device appeared"; exit 1; }
date +%T
rkdeveloptool ld 2>&1 | tee "$OUT/ld.txt"
for c in rid rfi rci rcb; do echo "== $c"; rkdeveloptool $c 2>&1; done | tee "$OUT/info.txt"
echo "== reading first 32 MiB (MBR + bootloader area) as a test"
rkdeveloptool rl 0 65536 "$OUT/first32MiB.bin" 2>&1 | tail -2
ls -l "$OUT/first32MiB.bin" 2>/dev/null
echo "== keep-alive for ${KEEP}s (Ctrl+C or kill to stop)"
end=$((SECONDS + KEEP))
while [ $SECONDS -lt $end ]; do
  if ! rkdeveloptool td >/dev/null 2>&1; then echo "$(date +%T) device gone"; exit 0; fi
  sleep 1
done
echo "keep-alive finished; device still in rockusb mode"
