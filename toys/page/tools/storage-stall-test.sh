#!/bin/bash
# A/B: does giving the storage controllers' interrupts a core of their own stop storage activity
# from stalling frames?
#   storage-stall-test.sh default|moved write-builtin|read-builtin|read-card|write-card [toy args...]
# default: the device as it comes. moved: every dw-mci interrupt on core 3, the toy on cores 0-2.
# write-builtin: 256 KB written to the built-in storage (eMMC, /roms) and pushed out, every 2 s.
# read-builtin:  256 KB read straight from the built-in storage, every 2 s.
# read-card:     256 KB read straight from the card in the TF2 slot, every 2 s. Nothing is
#                mounted and nothing is written to the card.
# write-card:    256 KB written to a file on the card in the TF2 slot and pushed out, every 2 s.
#                The card is mounted for the test and unmounted after; the file is removed.
MODE=$1; KIND=$2; shift 2
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
D=/run/gameguytest/$KIND-$MODE
sudo mkdir -p $D && sudo chmod -R 777 /run/gameguytest
rm -f $D/*
BUILTIN=$(ls /sys/class/mmc_host/*/ | grep -o 'mmc[0-9]:[0-9a-f]*' | head -0; for b in /sys/block/mmcblk[0-9]; do [ "$(cat $b/device/type)" = MMC ] && basename $b; done | head -1)
CARD=$(for b in /sys/block/mmcblk[0-9]; do [ "$(cat $b/device/type)" = SD ] && basename $b; done | head -1)
IRQS=$(grep -a dw-mci /proc/interrupts | cut -d: -f1 | tr -d ' ')
M=/run/gameguycard
if [ "$KIND" = write-card ]; then
  sudo mkdir -p $M && sudo mount -o uid=1000,gid=1000,umask=000,noatime /dev/${CARD}p1 $M || exit 1
fi
RUN=""
if [ "$MODE" = moved ]; then
  for i in $IRQS; do echo 3 | sudo tee /proc/irq/$i/smp_affinity_list > /dev/null; done
  RUN="taskset -c 0-2"
fi
{ echo "kind $KIND; built-in storage $BUILTIN; card ${CARD:-none}; toy run with: ${RUN:-no pinning}"
  for i in $IRQS; do echo "irq $i on cores $(cat /proc/irq/$i/smp_affinity_list)"; done
  grep -a dw-mci /proc/interrupts; } > $D/setup.txt
poke() {
  case $KIND in
    write-builtin) dd if=/dev/zero of=/roms/ports/gameguypage/tools/poke.bin bs=64k count=4 conv=fsync 2>/dev/null ;;
    read-builtin)  sudo dd if=/dev/$BUILTIN of=/dev/null bs=64k count=4 skip=$((RANDOM % 4000)) iflag=direct 2>/dev/null ;;
    read-card)     sudo dd if=/dev/$CARD of=/dev/null bs=64k count=4 skip=$((RANDOM % 4000)) iflag=direct 2>/dev/null ;;
    write-card)    dd if=/dev/zero of=$M/poke.bin bs=64k count=4 conv=fsync 2>/dev/null ;;
  esac
}
( sleep 5; while true; do poke; echo "$(date +%s.%N) $KIND" >> $D/pokes.txt; sleep 2; done ) &
POKE=$!
cd /roms/ports/gameguypage || exit 1
$RUN ./page-aarch64 --out $D "$@" > $D/console.log 2>&1
kill $POKE
grep -a dw-mci /proc/interrupts >> $D/setup.txt
for i in $IRQS; do echo 0-3 | sudo tee /proc/irq/$i/smp_affinity_list > /dev/null; done
rm -f /roms/ports/gameguypage/tools/poke.bin
if [ "$KIND" = write-card ]; then rm -f $M/poke.bin; sync; sudo umount $M; fi
