#!/bin/bash
# roleswitch-check: runs ON a handheld, with the laptop cable plugged in and no second unit.
#   probe/tools/r36s.sh push N probe/tools/roleswitch-check.sh /tmp/roleswitch-check.sh
#   probe/tools/r36s.sh ssh N 'setsid nohup sudo bash /tmp/roleswitch-check.sh >/tmp/roleswitch.out 2>&1 </dev/null & sleep 1'
# It finds out which way of taking the OTG port from USB host mode back to device mode brings the
# laptop link back, and what repairs the link when it doesn't come back. It never switches the
# port's 5 V on. If nothing brings the link back it reboots; the boot service restores it.
# Log: /roms/ports/gameguylinktest/roleswitch-*.log (ends with DONE or REBOOTING).
export PATH="/usr/local/sbin:/usr/sbin:/sbin:$PATH"
if [ "$(id -u)" = 0 ]; then S=""; else S=sudo; fi
OUT=/roms/ports/gameguylinktest; mkdir -p "$OUT"
LOG="$OUT/roleswitch-$(date +%Y%m%d-%H%M%S).log"
OTG=$(ls /sys/devices/platform/*/*usb2-phy*/otg_mode 2>/dev/null | head -1)
G=/sys/kernel/config/usb_gadget/gameguy
IF=usb0
UNIT=$(ip -4 -o addr show $IF | sed -n 's/.* 10\.36\.\([0-9]*\)\.1\/.*/\1/p')
LAPTOP=10.36.$UNIT.2
ST=/sys/class/net/$IF/statistics

note() { echo "[$(date +%T)] $*" >> "$LOG"; }
w() { note "write $1 <- $2"; echo "$2" | $S tee "$1" >/dev/null 2>>"$LOG"; }
counters() { echo "rx=$(cat $ST/rx_packets) tx=$(cat $ST/tx_packets) tx_err=$(cat $ST/tx_errors) tx_drop=$(cat $ST/tx_dropped)"; }
snap() {
  note "  otg_mode=$(cat "$OTG") udc=$(cat /sys/class/udc/*/state 2>/dev/null | tr '\n' ' ')" \
    "carrier=$(cat /sys/class/net/$IF/carrier 2>/dev/null) $(ip -br addr show $IF 2>/dev/null | tr -s ' ') $(counters)" \
    "5V_pin=$($S awk '$1=="gpio-100"{print $NF}' /sys/kernel/debug/gpio 2>/dev/null)"
}
gadget_down() { w "$G/UDC" ""; }
gadget_up() {   # what gameguy-usbnet does, without touching otg_mode
  w "$G/UDC" "$(ls /sys/class/udc | head -1)"
  sleep 1
  $S ip -4 addr flush dev $IF; $S ip addr add "10.36.$UNIT.1/24" dev $IF; $S ip link set $IF up
  $S systemctl restart gameguy-dhcp.service
}
usbnet() { $S /usr/local/bin/gameguy-usbnet boot >> "$LOG" 2>&1; }
link_ok() {     # $1 = seconds to wait; true once the laptop answers
  local t0=$SECONDS
  $S ip neigh flush dev $IF 2>/dev/null
  while [ $((SECONDS - t0)) -lt "$1" ]; do
    if ping -c1 -W1 "$LAPTOP" >/dev/null 2>&1 || ip neigh show "$LAPTOP" dev $IF | grep -q REACHABLE; then
      note "  LINK OK after $((SECONDS - t0)) s"; return 0
    fi
    sleep 1
  done
  note "  LINK DEAD after $1 s"; return 1
}
diag() {
  snap
  note "  dhcp log:"; $S journalctl -u gameguy-dhcp --no-pager -n 6 >> "$LOG" 2>/dev/null
  note "  kernel log:"; $S dmesg | tail -n 14 >> "$LOG"
}
repair() {      # tried in order of how much they reset; says which one worked
  note " repair 1: unbind and rebind the gadget"
  gadget_down; sleep 1; gadget_up; link_ok 40 && { note " REPAIRED BY 1"; return 0; }
  diag
  note " repair 2: phy to automatic, then back to forced device mode"
  gadget_down; w "$OTG" otg; sleep 1; w "$OTG" peripheral; sleep 1; gadget_up
  link_ok 40 && { note " REPAIRED BY 2"; return 0; }
  diag
  # Re-probing or reloading dwc2 here is not a repair: on 2026-11-13 both left the controller
  # unable to enter device mode ("dwc2_wait_for_mode: Couldn't set device mode") until a reboot.
  note "REBOOTING: nothing brought the link back"
  sync; $S systemctl reboot; sleep 60
}
trial() {       # $1 = name; the rest of the script body is run by the caller before this
  if link_ok 40; then note "RESULT $1: link came back"; else diag; note "RESULT $1: link did NOT come back"; repair; fi
}

sleep 3
note "roleswitch-check on unit $UNIT; laptop $LAPTOP; kernel $(uname -r); dr_mode=$(tr -d '\0' < /proc/device-tree/usb@ff300000/dr_mode)"
snap
if ! link_ok 10; then note "DONE: the laptop link isn't up to begin with; nothing changed"; exit 1; fi

note "TRIAL 0: gadget unbound and rebound, no host mode"
gadget_down; sleep 3; usbnet
trial 0

note "TRIAL 1: host mode 5 s, then forced device mode (what the link test did)"
gadget_down; w "$OTG" host; sleep 5; snap; w "$OTG" peripheral; sleep 1; usbnet
trial 1

note "TRIAL 2: as trial 1, with the 5 V regulator driver unbound and rebound while in host mode (5 V stays off)"
gadget_down; w "$OTG" host; sleep 3
w /sys/bus/platform/drivers/reg-fixed-voltage/unbind vbus_host; sleep 2
w /sys/bus/platform/drivers/reg-fixed-voltage/bind vbus_host
snap; w "$OTG" peripheral; sleep 1; usbnet
trial 2

note "TRIAL 3: host mode 5 s, then the phy's automatic mode instead of forced device mode"
gadget_down; w "$OTG" host; sleep 5; w "$OTG" otg; sleep 1; snap; gadget_up
trial 3

note "putting the unit back to its normal state"
gadget_down; usbnet; snap
if link_ok 40; then note "DONE"; else note "REBOOTING: final state had no link"; sync; $S systemctl reboot; fi
