#!/bin/bash
# gameguy: the game (EmulationStation "Ports" launcher).
# Session logs go to gameguy/results/ next to this script.
# Anything after the script's name is passed to the game, e.g. --lines for the benchmark.

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
GAMEDIR="$HERE/gameguy"
cd "$GAMEDIR" || exit 1
mkdir -p results
STAMP=$(date +%Y%m%d-%H%M%S)
chmod +x ./gameguy-aarch64 2>/dev/null

# Three things every toy's launcher learned (docs/hardware-target.md):
# 1. The storage controllers' interrupts get the last core to themselves, and the game keeps to
#    the other three. Without that, any read or write of the built-in storage stalls frames.
PIN=""
SDIRQS=$(grep -a dw-mci /proc/interrupts | cut -d: -f1 | tr -d ' ')
for i in $SDIRQS; do
  echo 3 | sudo -n tee "/proc/irq/$i/smp_affinity_list" > /dev/null 2>&1 && PIN="taskset -c 0-2"
done
command -v taskset > /dev/null || PIN=""

# 2. The CPU, GPU and memory clocks are pinned at full speed. Left to scale, the GPU sits at its
#    slowest. Whatever started this (the menu's perfnorm, or r36s.sh) puts them back afterwards.
G_CPU=/sys/devices/system/cpu/cpufreq/policy0/scaling_governor
G_GPU=/sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor
G_MEM=/sys/devices/platform/dmc/devfreq/dmc/governor
WERE="cpu $(cat $G_CPU 2>/dev/null), gpu $(cat $G_GPU 2>/dev/null), memory $(cat $G_MEM 2>/dev/null)"
for g in $G_CPU $G_GPU $G_MEM; do echo performance | sudo -n tee "$g" > /dev/null 2>&1; done

# 3. The sound thread may ask for real-time priority.
sudo -n prlimit --pid $$ --rtprio=40:40 > /dev/null 2>&1

# The backlight is the game's to set while it runs (it is the sun), and is put back afterwards.
BL=/sys/class/backlight/backlight/brightness
BL_WAS=$(cat $BL 2>/dev/null)
[ -n "$BL_WAS" ] && sudo -n chmod a+w $BL 2>/dev/null

{ echo "clocks as started: $WERE"
  echo "clocks now: cpu $(cat $G_CPU 2>/dev/null), gpu $(cat $G_GPU 2>/dev/null), memory $(cat $G_MEM 2>/dev/null)"
  echo "priority: nice $(nice), real-time limit $(ulimit -r); storage interrupts on core(s) $(for i in $SDIRQS; do cat /proc/irq/$i/smp_affinity_list; done | sort -u | tr '\n' ' '); run with: ${PIN:-no pinning}"
  echo "backlight as started: ${BL_WAS:-unknown}"
} > "results/console-$STAMP.log"
$PIN ./gameguy-aarch64 --log "results/gameguy-$STAMP.txt" "$@" >> "results/console-$STAMP.log" 2>&1
echo "exit code $?" >> "results/console-$STAMP.log"

[ -n "$BL_WAS" ] && { echo "$BL_WAS" > $BL 2>/dev/null; sudo -n chmod 644 $BL 2>/dev/null; }
for i in $SDIRQS; do echo 0-3 | sudo -n tee "/proc/irq/$i/smp_affinity_list" > /dev/null 2>&1; done
sync
