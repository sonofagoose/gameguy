#!/bin/bash
# Start a toy's launcher with the clocks left to scale themselves, as the menu does when its
# governor setting is "ondemand" (r36s.sh run pins them at full speed before it starts anything).
#   as-the-menu-might.sh /roms/ports/GameguyPage.sh [toy args...]
echo simple_ondemand | sudo tee /sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor > /dev/null
echo ondemand | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_governor > /dev/null
echo dmc_ondemand | sudo tee /sys/devices/platform/dmc/devfreq/dmc/governor > /dev/null
L=$1; shift
exec bash "$L" "$@"
