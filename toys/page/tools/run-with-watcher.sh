#!/bin/bash
# Run the page toy exactly as its launcher does (logs on the built-in storage, the storage
# interrupts on core 3, the toy on cores 0 to 2), with the watcher beside it writing to memory.
#   run-with-watcher.sh [gov=ondemand] [toy args...]
# The watcher's samples and a copy of the session log end up in /run/gameguytest/.
# gov=ondemand sets the CPU, GPU and memory clocks the way the menu's perfmax does when the
# menu's governor setting is "ondemand" (r36s.sh run pins all three at full speed instead).
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
GOV=""
case "$1" in gov=*) GOV=${1#gov=}; shift ;; esac
G_GPU=/sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor
G_CPU=/sys/devices/system/cpu/cpufreq/policy0/scaling_governor
G_DMC=/sys/devices/platform/dmc/devfreq/dmc/governor
D=/run/gameguytest
sudo mkdir -p $D && sudo chmod 777 $D
rm -f $D/*
if [ "$GOV" = ondemand ]; then
  echo simple_ondemand | sudo tee $G_GPU > /dev/null
  echo ondemand | sudo tee $G_CPU > /dev/null
  echo dmc_ondemand | sudo tee $G_DMC > /dev/null
  echo 85 | sudo tee /sys/devices/system/cpu/cpufreq/ondemand/up_threshold > /dev/null 2>&1
  echo 150 | sudo tee /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor > /dev/null 2>&1
fi
snap() { echo "governors: cpu $(cat $G_CPU), gpu $(cat $G_GPU), memory $(cat $G_DMC)"; echo "memory clock changes so far: $(grep Total /sys/class/devfreq/dmc/trans_stat | tr -dc 0-9)"; echo "gpu clock changes so far: $(grep Total /sys/class/devfreq/ff400000.gpu/trans_stat | tr -dc 0-9)"; echo "cpu clock changes so far: $(cat /sys/devices/system/cpu/cpufreq/policy0/stats/total_trans)"; }
snap > $D/before.txt
HERE="$(dirname "$(readlink -f "$0")")"
python3 "$HERE/watch-device.py" 900 $D/watch.jsonl &
WATCH=$!
cd /roms/ports/gameguypage || exit 1
mkdir -p results
STAMP=$(date +%Y%m%d-%H%M%S)
PIN=""
SDIRQS=$(grep -a dw-mci /proc/interrupts | cut -d: -f1 | tr -d ' ')
for i in $SDIRQS; do
  echo 3 | sudo -n tee "/proc/irq/$i/smp_affinity_list" > /dev/null 2>&1 && PIN="taskset -c 0-2"
done
sudo -n prlimit --pid $$ --rtprio=40:40 > /dev/null 2>&1   # the sound thread may ask for real-time
$PIN ./page-aarch64 --out results "$@" > "results/console-$STAMP.log" 2>&1
for i in $SDIRQS; do echo 0-3 | sudo -n tee "/proc/irq/$i/smp_affinity_list" > /dev/null 2>&1; done
kill $WATCH
snap > $D/after.txt
cp "results/page-$STAMP.txt" $D/ 2>/dev/null || cp "$(ls -t results/page-*.txt | head -1)" $D/
sync
