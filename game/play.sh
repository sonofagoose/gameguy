#!/bin/bash
# Play gameguy on the laptop, in a window twice the handheld's screen.
#
#   game/play.sh            the game, from the first evening (or where you left it)
#   game/play.sh room       the room: the walks and questions, as on the handheld
#   game/play.sh --scale 3  anything else is passed to the game
#
# Any game controller plays, its face buttons by where they are; one plugged in while playing is
# taken up. The keyboard plays too, laid out like the handheld:
#
#   left stick   W A S D (Ctrl held: half way)      right stick  the arrows
#   R1 (call)    E                                  R2 (hum)     R
#   L1           Q                                  L2           Z
#   bottom face  Space                              right face   Shift
#   left face    F                                  top face     G
#   Start        Tab (the songbook)                 Select       Backspace
#   leave        Esc held (Select and Start together)
#
# The game keeps its saves, takes and session logs in game/laptop/, apart from the handheld's.
set -e
HERE="$(dirname "$(readlink -f "$0")")"
cd "$HERE"
ZIG="$HERE/../.tools/zig/zig"
newest_source=$(find src scores -newer build/gameguy-x86_64 2>/dev/null | head -1)
if [ ! -f build/c-x86_64.zig ]; then
  echo "building everything for the laptop first (game/build.sh laptop)..."
  ./build.sh laptop > /dev/null
elif [ ! -x build/gameguy-x86_64 ] || [ -n "$newest_source" ]; then
  echo "building the game for the laptop..."
  "$ZIG" build-exe -O ReleaseSafe --dep c -Mroot=src/main.zig -Mc=build/c-x86_64.zig \
      -lc -ldl -lm -femit-bin=build/gameguy-x86_64 --cache-dir build/cache
fi
mkdir -p laptop/results
STAMP=$(date +%Y%m%d-%H%M%S)
args=()
if [ "$1" = room ]; then
  shift
  [ -d build/room ] || { echo "the room is made by the full build: game/build.sh"; exit 1; }
  args+=(--room "$HERE/build/room")
fi
cd laptop
exec ../build/gameguy-x86_64 --windowed --scale 2 --log "results/gameguy-$STAMP.txt" "${args[@]}" "$@"
