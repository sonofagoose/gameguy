#!/usr/bin/env bash
# Write a firmware image to a microSD card, then verify it byte-for-byte.
# Usage: probe/tools/flash-card.sh [--no-fullcheck] /dev/mmcblkN [image.img]
# By default it first runs a full-surface capacity check (writes a unique pattern to every sector and
# reads it back) to catch fake-capacity cards, then flashes and verifies the image.
# Safety: refuses anything that is not a removable 28-34 GB card (the spare 32 GB cards), refuses the
# system disk, shows exactly what will be erased and asks you to type the device name to confirm.
set -euo pipefail
FULLCHECK=1
if [ "${1:-}" = "--no-fullcheck" ]; then FULLCHECK=0; shift; fi
DEV=${1:?usage: flash-card.sh [--no-fullcheck] /dev/mmcblkN [image.img]}
HERE="$(cd "$(dirname "$0")" && pwd)"
IMG=${2:-"$HERE/../../.tools/firmware/dArkOS4Clone-20261008.img"}
[ -b "$DEV" ] || { echo "not a block device: $DEV"; exit 1; }
[ -f "$IMG" ] || { echo "image not found: $IMG"; exit 1; }
case "$DEV" in /dev/mmcblk[0-9]|/dev/sd[a-z]) ;; *) echo "give the whole device (e.g. /dev/mmcblk0), not a partition"; exit 1;; esac
ROOTDEV=$(lsblk -no PKNAME "$(findmnt -no SOURCE /)" 2>/dev/null | tail -1 || true)
if lsblk -nro NAME "$DEV" | grep -q -E "^(${ROOTDEV:-none}|luks)"; then echo "refusing: $DEV holds the running system"; exit 1; fi
SIZE=$(lsblk -bdno SIZE "$DEV")
GB=$((SIZE / 1000000000))
if [ "$GB" -lt 28 ] || [ "$GB" -gt 34 ]; then
  echo "refusing: $DEV is ${GB} GB; this script only writes the 32 GB spare cards"
  exit 1
fi
ISZ=$(stat -c %s "$IMG")
echo "About to ERASE this card and write $(basename "$IMG") ($((ISZ / 1000000)) MB):"
lsblk -o NAME,SIZE,LABEL,FSTYPE,MOUNTPOINTS "$DEV"
read -r -p "Type the device name ($DEV) to continue: " ans
[ "$ans" = "$DEV" ] || { echo "cancelled"; exit 1; }
for p in $(lsblk -nro NAME "$DEV" | tail -n +2); do udisksctl unmount -b "/dev/$p" >/dev/null 2>&1 || true; done
if [ "$FULLCHECK" = 1 ]; then
  RUNID=$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')
  echo "== Capacity check 1/2: writing a unique pattern to all $((SIZE / 1000000)) MB (slowest step)"
  python3 -I "$HERE/card-check.py" gen "$SIZE" "$RUNID" | sudo dd of="$DEV" bs=4M iflag=fullblock oflag=direct status=progress
  sync
  echo "== Capacity check 2/2: reading it all back"
  if ! sudo dd if="$DEV" bs=4M iflag=direct status=none | python3 -I "$HERE/card-check.py" verify "$SIZE" "$RUNID"; then
    echo "This card is NOT what it claims. Do not use it."
    exit 1
  fi
fi
echo "== Writing the firmware image"
sudo dd if="$IMG" of="$DEV" bs=4M conv=fsync status=progress
sync
echo "Verifying (reads the card back; a few minutes)..."
if sudo cmp -n "$ISZ" "$IMG" "$DEV"; then echo "VERIFY OK"; else echo "VERIFY FAILED: do not use this card"; exit 1; fi
sudo blockdev --rereadpt "$DEV" || true
lsblk -o NAME,SIZE,LABEL,FSTYPE "$DEV"
echo "Done. Leave the card in the reader; the next step selects the console profile."
