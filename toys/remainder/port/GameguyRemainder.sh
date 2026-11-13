#!/bin/bash
# remainder: a mechanic test for the gameguy game (EmulationStation "Ports" launcher).
# Session logs go to gameguyremainder/results/ next to this script.

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
GAMEDIR="$HERE/gameguyremainder"
cd "$GAMEDIR" || exit 1
mkdir -p results
STAMP=$(date +%Y%m%d-%H%M%S)
chmod +x ./remainder-aarch64 2>/dev/null
./remainder-aarch64 --out results "$@" > "results/console-$STAMP.log" 2>&1
echo "exit code $?" >> "results/console-$STAMP.log"
sync
