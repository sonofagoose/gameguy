#!/bin/bash
# gameguy hardware probe — launcher for ArkOS / dArkOS / ArkOS4Clone (EmulationStation "Ports").
# Runs the probe (about 5 minutes including a 60 s stability test and a 30 s controls test)
# and writes results to gameguyprobe/results/ next to this script.
PROBE_ARGS="${*:-${PROBE_ARGS:---stress 60 --input 30}}"   # arguments override

# Standard PortMaster discovery: gives us $ESUDO and the SDL controller mapping for this device.
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
if [ -d "/opt/system/Tools/PortMaster/" ]; then controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then controlfolder="$XDG_DATA_HOME/PortMaster"
else controlfolder="/roms/ports/PortMaster"; fi
if [ -f "$controlfolder/control.txt" ]; then
  source "$controlfolder/control.txt"
  get_controls 2>/dev/null
  [ -n "$sdl_controllerconfig" ] && export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
fi
if [ "$(id -u)" = 0 ]; then ESUDO=""; else ESUDO=${ESUDO:-sudo}; fi

# Find the probe folder: next to this script (ArkOS: /roms/ports), or in ports/ when this script sits in
# ports_scripts/ (EmuELEC lists Ports from /storage/roms/ports_scripts).
HERE="$(dirname "$(readlink -f "$0")")"
GAMEDIR=""
for d in "$HERE/gameguyprobe" "$HERE/../ports/gameguyprobe" /storage/roms/ports/gameguyprobe /roms/ports/gameguyprobe \
         /roms2/ports/gameguyprobe; do
  [ -x "$d/probe-aarch64" ] || [ -f "$d/probe-aarch64" ] && { GAMEDIR="$(cd "$d" && pwd)"; break; }
done
[ -n "$GAMEDIR" ] || { echo "gameguyprobe folder not found near $HERE" > /tmp/gameguyprobe-error.txt; exit 1; }
cd "$GAMEDIR" || exit 1
STAMP=$(date +%Y%m%d-%H%M%S)
# Results go next to the probe; if that card is read-only, fall back to the internal home folder.
OUT="$GAMEDIR/results"
mkdir -p "$OUT" 2>/dev/null
if ! touch "$OUT/.writetest" 2>/dev/null; then
  OUT="${HOME:-/tmp}/gameguyprobe-results"
  mkdir -p "$OUT" 2>/dev/null || OUT=/tmp/gameguyprobe-results
  mkdir -p "$OUT"
  echo "probe folder is read-only; results in $OUT" > "$OUT/READONLY-NOTE-$STAMP.txt"
fi
rm -f "$GAMEDIR/results/.writetest" 2>/dev/null

# Root-only extras (best effort; ArkOS lets the ark user sudo without a password)
{
  echo "# root extras $STAMP"
  $ESUDO cat /sys/kernel/debug/clk/clk_summary 2>&1 | head -200
  echo "# gpio state (speaker amp enable is GPIO3_A7 = gpio-103 on RK3326)"
  $ESUDO cat /sys/kernel/debug/gpio 2>&1 | head -120
  echo "# amixer"
  amixer contents 2>&1 | head -120
  echo "# dmesg (before probe)"
  $ESUDO dmesg 2>&1 | tail -n 80
} > "$OUT/root-extras-$STAMP.txt" 2>&1

chmod +x ./probe-aarch64 2>/dev/null
./probe-aarch64 $PROBE_ARGS --out "$OUT" > "$OUT/console-$STAMP.log" 2>&1
echo "exit code $?" >> "$OUT/console-$STAMP.log"
$ESUDO dmesg 2>&1 | tail -n 120 > "$OUT/dmesg-after-$STAMP.txt"
sync
