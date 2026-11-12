#!/bin/bash
# Run from the SD-card system (install card in TF1) on a unit with ArkOS4Clone installed on its eMMC.
#  1. Copies the gameguy probe + launchers into the eMMC system's Ports.
#  2. Patches the eMMC system's device tree so the OTG port can act as a USB *device* for a PC
#     (fix reported on r/R36S): usb2-phy otg-port status okay, usb@ff300000 dr_mode peripheral,
#     and the handheld stops driving 5 V out of the OTG port (vbus_host no longer always-on).
#     The original DTB is kept next to it as <name>.dtb.orig; GameguySetupEMMC.sh --restore puts it back.
# Trade-off: in peripheral mode the OTG port no longer hosts USB sticks / dongles (none are used here).
if [ "$(id -u)" = 0 ]; then ESUDO=""; else ESUDO=sudo; fi
SRC="$(dirname "$(readlink -f "$0")")"
LOG="$SRC/gameguyprobe/setup-emmc.log"
say() { echo "$*" | tee -a "$LOG"; printf '%s\n' "$*" | $ESUDO tee /dev/tty1 >/dev/null 2>&1; }
: > "$LOG"
say "== gameguy: set up eMMC system $(date)"
[ -b /dev/mmcblk2p1 ] && [ -b /dev/mmcblk2p3 ] || { say "No eMMC system found (mmcblk2p1/p3)."; lsblk >> "$LOG" 2>&1; sleep 6; exit 1; }
MB=/tmp/gameguy-emmc-boot; MR=/tmp/gameguy-emmc-roms
$ESUDO mkdir -p "$MB" "$MR"
$ESUDO mount /dev/mmcblk2p1 "$MB" >> "$LOG" 2>&1 || { say "mount eMMC BOOT failed"; sleep 6; exit 1; }
$ESUDO mount /dev/mmcblk2p3 "$MR" >> "$LOG" 2>&1 || { say "mount eMMC ROMS failed"; $ESUDO umount "$MB"; sleep 6; exit 1; }

DTB=$(tr -d '\r' < "$MB/boot.ini" | awk '/^load .*\.dtb$/ {print $NF; exit}')
say "eMMC boot.ini loads: $DTB"
if [ "${1:-}" = "--restore" ]; then
  [ -f "$MB/$DTB.orig" ] && $ESUDO cp -f "$MB/$DTB.orig" "$MB/$DTB" && say "restored original $DTB"
else
  # 1. ports
  $ESUDO mkdir -p "$MR/ports/gameguyprobe"
  for f in GameguyProbe.sh GameguyProbe-LongStress.sh GameguyUSBDiskMode.sh GameguyUSBNet.sh; do
    [ -f "$SRC/$f" ] && $ESUDO cp -f "$SRC/$f" "$MR/ports/" && say "copied $f"
  done
  $ESUDO cp -f "$SRC/gameguyprobe/probe-aarch64" "$SRC/gameguyprobe/README.txt" "$MR/ports/gameguyprobe/" && say "copied probe"
  $ESUDO cp -rf "$SRC/gameguyprobe/licenses" "$MR/ports/gameguyprobe/" 2>/dev/null
  # 2. device tree
  if [ -n "$DTB" ] && [ -f "$MB/$DTB" ]; then
    [ -f "$MB/$DTB.orig" ] || $ESUDO cp -f "$MB/$DTB" "$MB/$DTB.orig"
    T=/tmp/gameguy-patch.dtb
    cp -f "$MB/$DTB" "$T"
    ok=1
    fdtput -t s "$T" /syscon@ff2c0000/usb2-phy@100/otg-port status okay >> "$LOG" 2>&1 || ok=0
    fdtput -t s "$T" /usb@ff300000 dr_mode peripheral >> "$LOG" 2>&1 || ok=0
    fdtput -d "$T" /vbus_host regulator-always-on >> "$LOG" 2>&1 || say "(vbus_host always-on already absent)"
    if [ "$ok" = 1 ]; then
      $ESUDO cp -f "$T" "$MB/$DTB" && say "patched $DTB: otg-port okay, dr_mode peripheral, OTG 5V not forced on"
      {
        echo "otg-port status: $(fdtget "$MB/$DTB" /syscon@ff2c0000/usb2-phy@100/otg-port status)"
        echo "dr_mode: $(fdtget "$MB/$DTB" /usb@ff300000 dr_mode)"
      } >> "$LOG" 2>&1
    else
      say "DTB patch FAILED; eMMC device tree left unchanged"
    fi
  else
    say "could not find the eMMC DTB; device tree left unchanged"
  fi
fi
ls -la "$MB" "$MR/ports" >> "$LOG" 2>&1
sync
$ESUDO umount "$MR"; $ESUDO umount "$MB"
say "Done. Power off, remove the card, power on (boots the eMMC system)."
sleep 5
