#!/bin/bash
# gameguy probe with a 10-minute stability phase: use this after changing overclock settings.
# A PASS here (0 errors, no crash, no freeze) is the bar for keeping a clock setting.
export PROBE_ARGS="--stress 600 --input 0"
exec "$(dirname "$(readlink -f "$0")")/GameguyProbe.sh"
