#!/bin/bash
# Run the page toy with its logs in memory instead of on the SD card, and a watcher beside it.
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
D=/run/gameguytest
sudo mkdir -p $D && sudo chmod 777 $D
rm -f $D/*
python3 "$(dirname "$(readlink -f "$0")")/watch-device.py" 200 $D/mon.log &
MON=$!
snap() { for f in /sys/class/devfreq/dmc/trans_stat /sys/class/devfreq/ff400000.gpu/trans_stat; do grep Total $f; done; echo "cpufreq $(cat /sys/devices/system/cpu/cpufreq/policy0/stats/total_trans) gov $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor) dmc $(cat /sys/class/devfreq/dmc/governor) $(cat /sys/class/devfreq/dmc/cur_freq)"; }
snap > $D/before.txt
cd /roms/ports/gameguypage || exit 1
./page-aarch64 --out $D "$@" > $D/console.log 2>&1
snap > $D/after.txt
kill $MON
