#!/bin/bash
# The room: Morgan's ears, eyes and hands answer, and every answer is logged in
# gameguy/results/ (EmulationStation "Ports" launcher). It is the game's launcher with one more word.
exec "$(dirname "$(readlink -f "$0")")/Gameguy.sh" --room room "$@"
