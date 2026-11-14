#!/bin/bash
# A/B: does moving the SD controller's interrupt off the core that serves the GPU and the display
# stop SD-card writes from stalling frames?   stalltest.sh default|moved [toy args...]
MODE=$1; shift
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
D=/run/gameguytest/$MODE
sudo mkdir -p $D && sudo chmod -R 777 /run/gameguytest
rm -f $D/*
IRQ=$(grep -a dw-mci /proc/interrupts | sort -k2 -n -r | head -1 | cut -d: -f1 | tr -d ' ')
RUN=""
if [ "$MODE" = moved ]; then
  echo 3 | sudo tee /proc/irq/$IRQ/smp_affinity_list > /dev/null
  RUN="taskset -c 0-2"
fi
echo "irq $IRQ on cpus $(cat /proc/irq/$IRQ/smp_affinity_list); toy run with: ${RUN:-no pinning}" > $D/setup.txt
grep -a dw-mci /proc/interrupts >> $D/setup.txt
# a write to the SD card every two seconds, pushed out at once
( sleep 5; while true; do dd if=/dev/zero of=/roms/ports/gameguypage/tools/poke.bin bs=64k count=4 conv=fsync 2>/dev/null; echo "$(date +%s.%N) poke" >> $D/pokes.txt; sleep 2; done ) &
POKE=$!
cd /roms/ports/gameguypage || exit 1
$RUN ./page-aarch64 --out $D "$@" > $D/console.log 2>&1
kill $POKE
grep -a dw-mci /proc/interrupts >> $D/setup.txt
echo 0-3 | sudo tee /proc/irq/$IRQ/smp_affinity_list > /dev/null
echo "restored: irq $IRQ on cpus $(cat /proc/irq/$IRQ/smp_affinity_list)" >> $D/setup.txt
rm -f /roms/ports/gameguypage/tools/poke.bin
