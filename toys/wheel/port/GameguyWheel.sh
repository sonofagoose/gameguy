#!/bin/bash
# wheel: a mechanic test for the gameguy game (EmulationStation "Ports" launcher).
# Session logs go to gameguywheel/results/ next to this script.

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
GAMEDIR="$HERE/gameguywheel"
cd "$GAMEDIR" || exit 1
mkdir -p results
STAMP=$(date +%Y%m%d-%H%M%S)
chmod +x ./wheel-aarch64 2>/dev/null

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

# The menu can start a port with the clocks left to scale themselves ("ondemand"). On this
# handheld that leaves the GPU at its slowest, and a toy at about two thirds of its frame rate
# with a gap in the sound every half minute (measured 2026-11-15, docs/hardware-target.md). So
# the launcher pins the CPU, GPU and memory clocks at full speed itself. Whatever started it
# (the menu's perfnorm, or r36s.sh) puts the clocks back afterwards.
G_CPU=/sys/devices/system/cpu/cpufreq/policy0/scaling_governor
G_GPU=/sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor
G_MEM=/sys/devices/platform/dmc/devfreq/dmc/governor
WERE="cpu $(cat $G_CPU 2>/dev/null), gpu $(cat $G_GPU 2>/dev/null), memory $(cat $G_MEM 2>/dev/null)"
for g in $G_CPU $G_GPU $G_MEM; do echo performance | sudo -n tee "$g" > /dev/null 2>&1; done
# Let the toy's sound thread ask for real-time priority, ahead of everything ordinary.
sudo -n prlimit --pid $$ --rtprio=40:40 > /dev/null 2>&1

{ echo "clocks as started: $WERE"
  echo "clocks now: cpu $(cat $G_CPU 2>/dev/null), gpu $(cat $G_GPU 2>/dev/null), memory $(cat $G_MEM 2>/dev/null)"
  echo "priority: nice $(nice), real-time limit $(ulimit -r); storage interrupts on core(s) $(for i in $SDIRQS; do cat /proc/irq/$i/smp_affinity_list; done | sort -u | tr '\n' ' '); run with: ${PIN:-no pinning}"
} > "results/console-$STAMP.log"
$PIN ./wheel-aarch64 --out results "$@" >> "results/console-$STAMP.log" 2>&1
echo "exit code $?" >> "results/console-$STAMP.log"
for i in $SDIRQS; do echo 0-3 | sudo -n tee "/proc/irq/$i/smp_affinity_list" > /dev/null 2>&1; done
sync
