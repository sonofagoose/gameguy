#!/bin/bash
# EXPERIMENTAL — reboot into U-Boot's USB mass-storage mode ("ums").
# Only useful AFTER ArkOS4Clone has been installed to the internal eMMC (its U-Boot provides this mode).
# The whole internal eMMC then appears on the laptop as a USB disk over the OTG port (right-hand USB-C,
# USB-A-to-C data cable). Copy files / pull results / back up, then eject on the laptop and unplug:
# the handheld continues booting normally.
# If nothing appears on the laptop within ~20 s, unplug the cable; the unit boots normally.
ESUDO=${ESUDO:-sudo}
sync
$ESUDO systemctl reboot ums || $ESUDO reboot ums
