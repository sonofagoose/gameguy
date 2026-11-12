#!/usr/bin/env bash
# Apply an ArkOS4Clone console profile to a freshly flashed card's BOOT partition — the same file
# operations as the official dtb_selector (dtbTools CopySelectedConsole), without the interactive TUI.
# Usage: probe/tools/select-console.sh /run/media/$USER/BOOT ["clone type1 panel1"] [arkos4clone_fix|original]
# Default profile: Clone R36S > Type 1 Panel 1 (no amplifier). The "amp" variant sets use-ext-amplifier,
# which turns off the RK817 class-D speaker driver; these boards drive the speaker from the RK817 directly
# (stock DTB has no use-ext-amplifier). Panel init sequence is identical across the Type 1 candidates.
# Default battery driver: arkos4clone_fix.
# No overclock is applied (profile default: CPU 1296 / GPU 520 / DDR 666).
set -euo pipefail
B=${1:?usage: select-console.sh BOOT_MOUNTPOINT [profile] [battery]}
PROFILE=${2:-"clone type1 panel1"}
BATT=${3:-arkos4clone_fix}
C="$B/consoles"
[ -d "$C/$PROFILE" ] || { echo "profile not found: $C/$PROFILE"; ls "$C"; exit 1; }
[ -f "$C/kernel/$BATT/Image" ] || { echo "kernel not found: $C/kernel/$BATT/Image"; exit 1; }
echo "BOOT: $B"
echo "profile: $PROFILE | battery driver: $BATT"
shopt -s nullglob
for f in "$B"/*.dtb "$B"/*.ini "$B"/*.orig "$B"/*.tony "$B"/.cn; do [ -e "$f" ] || continue; echo "  remove $(basename "$f")"; rm -f "$f"; done
[ -d "$B/BMPs" ] && rm -rf "$B/BMPs"
cp -v "$C/$PROFILE"/* "$B/"
cp -v "$C/kernel/$BATT/Image" "$B/Image"
# extra source for the Type 1 / K36-family entries in dtbTools console config: logo/480P/
[ -d "$C/logo/480P" ] && cp -v "$C/logo/480P"/* "$B/"
printf '%s\n' "$PROFILE" > "$B/.gameguy-profile"
sync
echo "--- boot.ini (active lines)"
grep -v -E '^\s*(#|$)' "$B/boot.ini"
echo "OK. Eject the card (udisksctl unmount + power-off), then put it in the handheld's TF1-OS slot."
