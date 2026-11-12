#!/usr/bin/env bash
# Write a whole-eMMC image to an R36S-class (RK3326) handheld over the OTG USB cable.
#   1. put the handheld in Rockchip download mode: off, hold VOL+, power on (good data cable!)
#   2. probe/tools/flash-emmc-usb.sh IMAGE [--parts 1,3]
#      IMAGE = one .img, or the directory of emmc.img.partNN pieces.
#      --parts N,M writes only those MBR partitions of IMAGE (fast update); it first checks that the
#      device's partition table (sector 0) is identical to the image's, and refuses otherwise.
# It switches the device to maskrom (rd 3), loads Rockchip's RAM loader (rkbin), writes the image with
# rkdeveloptool wl, re-reads and compares the first 32 MiB (the loaders only allow reading that region),
# then resets the device. Full verification happens on the device after it boots (sha256 of /dev/mmcblk*).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LOADER=${LOADER:-"$HERE/../../.tools/rkbin/rk3326_loader_v2.12.140.bin"}
SRC=${1:?usage: flash-emmc-usb.sh IMAGE_OR_PARTS_DIR [--parts 1,3]}
PARTS=""
[ "${2:-}" = "--parts" ] && PARTS=${3:?--parts needs a list like 1,3}
EMMC_SECTORS=15269888   # both units: Samsung eMCP, 7456 MB
[ -f "$LOADER" ] || { echo "loader missing: $LOADER"; exit 1; }
TMP=$(mktemp -d "${TMPDIR:-/tmp}/flashemmc.XXXX")
trap 'rm -rf "$TMP"' EXIT
if [ -d "$SRC" ]; then
  IMG="$TMP/joined.img"   # needs ~7.8 GB free in TMPDIR (set TMPDIR to a disk-backed folder)
  cat "$SRC"/emmc.img.part* > "$IMG"
else
  IMG="$SRC"
fi
SZ=$(stat -c %s "$IMG")
[ $((SZ % 512)) -eq 0 ] || { echo "image size not a multiple of 512"; exit 1; }
[ $((SZ / 512)) -le $EMMC_SECTORS ] || { echo "image larger than the eMMC"; exit 1; }
echo "image: $IMG ($((SZ / 1000000)) MB)"
echo "computing the image checksum (about 30 s)..."
SUM=$(sha256sum "$IMG" | cut -d' ' -f1)
echo "sha256 $SUM"
if [ -f "$IMG.sha256" ]; then
  grep -q "$SUM" "$IMG.sha256" && echo "matches $IMG.sha256" || { echo "DOES NOT MATCH $IMG.sha256"; exit 1; }
fi

echo "waiting for a Rockchip device (hold VOL+ while powering on, good cable)..."
until rkdeveloptool ld 2>/dev/null | grep -q -E 'Loader|Maskrom'; do sleep 0.3; done
rkdeveloptool ld
if rkdeveloptool ld | grep -q Loader; then
  rkdeveloptool rd 3 >/dev/null
  until rkdeveloptool ld 2>/dev/null | grep -q Maskrom; do sleep 0.3; done
fi
rkdeveloptool db "$LOADER" | tail -1
sleep 1
FS=$(rkdeveloptool rfi | awk '/Flash Size:.*Sectors/ {print $3}')
echo "device eMMC sectors: $FS"
[ "$FS" = "$EMMC_SECTORS" ] || { echo "unexpected eMMC size ($FS); refusing to write"; exit 1; }
if [ -n "$PARTS" ]; then
  rkdeveloptool rl 0 1 "$TMP/mbr.bin" >/dev/null
  if ! cmp -s -n 512 <(dd if="$IMG" bs=512 count=1 status=none) "$TMP/mbr.bin"; then
    echo "device partition table differs from the image's: refusing a partial write (flash the whole image instead)"
    rkdeveloptool rd >/dev/null; exit 1
  fi
  echo "device partition table matches the image"
  declare -a STARTS SIZES
  for n in ${PARTS//,/ }; do
    read -r st sz < <(sfdisk -d "$IMG" 2>/dev/null | awk -v n="$n" -F'[=,: ]+' '$0 ~ "img"n" :" {for(i=1;i<=NF;i++){if($i=="start")s=$(i+1); if($i=="size")z=$(i+1)}; print s, z}')
    [ -n "$st" ] || { echo "partition $n not found in image"; rkdeveloptool rd >/dev/null; exit 1; }
    dd if="$IMG" of="$TMP/p$n.img" bs=512 skip="$st" count="$sz" status=none
    STARTS[$n]=$st; SIZES[$n]=$sz
    echo "partition $n: start $st, $((sz / 2048)) MiB"
  done
  read -r -p "Type WRITE to overwrite partitions $PARTS on the handheld: " ans
  [ "$ans" = WRITE ] || { echo cancelled; rkdeveloptool rd >/dev/null; exit 1; }
  for n in ${PARTS//,/ }; do
    echo "writing partition $n ..."
    time rkdeveloptool wl "${STARTS[$n]}" "$TMP/p$n.img"
  done
else
  read -r -p "Type WRITE to overwrite the handheld's entire internal storage: " ans
  [ "$ans" = WRITE ] || { echo cancelled; rkdeveloptool rd >/dev/null; exit 1; }
  time rkdeveloptool wl 0 "$IMG"
fi
rkdeveloptool rl 0 65536 "$TMP/check.bin" >/dev/null
if cmp -n $((65536 * 512)) "$IMG" "$TMP/check.bin"; then echo "first 32 MiB read back OK"; else echo "WARNING: first 32 MiB differ"; fi
rkdeveloptool rd
echo "done; the handheld reboots. Verify on-device with GameguyDumpEMMC or sha256sum of /dev/mmcblk2."
