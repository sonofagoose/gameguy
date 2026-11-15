#!/bin/bash
# meadow: a 3D test for the gameguy game (EmulationStation "Ports" launcher).
# Session logs go to gameguymeadow/results/ next to this script.

# Standard PortMaster discovery: gives the SDL controller mapping for this device.
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

HERE="$(dirname "$(readlink -f "$0")")"
GAMEDIR="$HERE/gameguymeadow"
cd "$GAMEDIR" || exit 1
mkdir -p results
STAMP=$(date +%Y%m%d-%H%M%S)
chmod +x ./meadow-aarch64 2>/dev/null

# Reading or writing the built-in storage stalls frames for up to a quarter of a second on this
# handheld: its controller raises about 70,000 interrupts a second on the core that also serves
# the GPU and the display (measured 2026-11-14, docs/hardware-target.md). So the storage
# controllers' interrupts get the last core to themselves while the toy runs, and the toy keeps
# to the other three.
PIN=""
SDIRQS=$(grep -a dw-mci /proc/interrupts | cut -d: -f1 | tr -d ' ')
for i in $SDIRQS; do
  echo 3 | sudo -n tee "/proc/irq/$i/smp_affinity_list" > /dev/null 2>&1 && PIN="taskset -c 0-2"
done
command -v taskset > /dev/null || PIN=""

$PIN ./meadow-aarch64 --out results "$@" > "results/console-$STAMP.log" 2>&1
echo "exit code $?" >> "results/console-$STAMP.log"
for i in $SDIRQS; do echo 0-3 | sudo -n tee "/proc/irq/$i/smp_affinity_list" > /dev/null 2>&1; done
sync
