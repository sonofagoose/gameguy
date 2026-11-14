#!/bin/bash
# gameguy link test: two handhelds joined by one USB-C data cable between their right (OTG) ports.
# This unit becomes the USB host and powers the cable. The other unit, left exactly as it is (USB
# device mode, GameguyUSBNet's boot service), shows up here as a USB network adapter. The test
# measures how quick and steady the link is, logs everything, then puts this unit back into device
# mode so the laptop link works again. The screen says what to plug and unplug, and when.
# Needs the dual-role device tree (dr_mode "otg", 2026-11-13). Results: gameguylinktest/ beside this.
if [ "$(id -u)" = 0 ]; then ESUDO=""; else ESUDO=sudo; fi
export PATH="/usr/local/sbin:/usr/sbin:/sbin:$PATH"   # Ports and r36s.sh runs leave out the sbin folders
HERE="$(dirname "$(readlink -f "$0")")"
OUT="$HERE/gameguylinktest"; mkdir -p "$OUT"
LOG="$OUT/link-$(date +%Y%m%d-%H%M%S).log"
note() { echo "[$(date +%T)] $*" >> "$LOG"; }
say() { note "SCREEN: $*"; printf '%s\n' "$*" | $ESUDO tee /dev/tty1 >/dev/null 2>&1; }
w() { note "write $1 <- $2"; echo "$2" | $ESUDO tee "$1" >/dev/null 2>>"$LOG"; }

OTG=$(ls /sys/devices/platform/*/*usb2-phy*/otg_mode 2>/dev/null | head -1)
G=/sys/kernel/config/usb_gadget/gameguy
USBON=/sys/class/power_supply/usb/online
EXTCON=/sys/class/extcon/extcon0/state
BAT=/sys/class/power_supply/battery
VBUS_GPIO=100                                   # gpio3 pin 4: the switch for the port's 5 V
VREG=/sys/bus/platform/drivers/reg-fixed-voltage # its regulator driver (vbus_host)
FORCED_VBUS=0
LIF=""

pin() { $ESUDO awk -v g="gpio-$VBUS_GPIO" '$1==g {print $NF}' /sys/kernel/debug/gpio 2>/dev/null; }
# Is a computer (or anything else) feeding 5 V into this port? The phy reports it as USB=1.
# power_supply/usb/online is no use for this: it reads 0 whenever a charger is on the left port.
fed() { grep -q "^USB=1" $EXTCON; }
otg_switch() { for r in /sys/class/regulator/regulator.*; do [ "$(cat "$r/name")" = OTG_SWITCH ] && cat "$r/state"; done; }
vbus_users() { for r in /sys/class/regulator/regulator.*; do [ "$(cat "$r/name")" = vbus_host ] && cat "$r/num_users"; done; }
state() {
  note "state: otg_mode=$(cat "$OTG" 2>/dev/null) usb_online=$(cat $USBON 2>/dev/null) 5V_pin=$(pin) otg_switch=$(otg_switch)" \
    "extcon=[$(tr '\n' ' ' < /sys/class/extcon/extcon0/state 2>/dev/null)]" \
    "battery=$(cat $BAT/capacity)% $(cat $BAT/current_now)uA $(cat $BAT/voltage_now)uV $(cat $BAT/status)"
}
kernel_log() { note "kernel log (last ${1:-25}):"; $ESUDO dmesg | tail -n "${1:-25}" >> "$LOG"; }

RESTORED=0
restore() {
  [ "$RESTORED" = 1 ] && return
  RESTORED=1
  note "== putting this unit back into device mode"
  [ -n "$LIF" ] && $ESUDO ip addr flush dev "$LIF" 2>/dev/null
  if [ "$FORCED_VBUS" = 1 ]; then
    w /sys/class/gpio/gpio$VBUS_GPIO/value 0
    w /sys/class/gpio/unexport $VBUS_GPIO
    w $VREG/bind vbus_host
  fi
  w "$OTG" peripheral
  sleep 1
  $ESUDO /usr/local/bin/gameguy-usbnet boot >> "$LOG" 2>&1
  state
  kernel_log 15
  cp -f "$LOG" "$OUT/link-last.log"
}

$ESUDO sh -c 'printf "\033[2J\033[H" > /dev/tty1'
DR=$(tr -d '\0' < /proc/device-tree/usb@ff300000/dr_mode 2>/dev/null)
note "gameguy link test; dr_mode=$DR"
state
if [ "$DR" != otg ] || [ -z "$OTG" ]; then
  say "   This unit's USB port can't become a host (dr_mode=$DR)."
  say "   Nothing was changed."
  sleep 8; exit 1
fi
$ESUDO modprobe cdc_ether 2>>"$LOG"
$ESUDO modprobe cdc_ncm 2>>"$LOG"

say ""
say "   GAMEGUY LINK TEST"
say ""
say "   1. Unplug the laptop cable from this unit."
# Never power the cable while the laptop is powering it: wait until its 5 V is gone.
for i in $(seq 2400); do
  fed || break
  [ "$i" = 120 ] && say "      (Still powered. If a charger is in the left port, unplug that too.)"
  sleep 0.5
done
if fed; then
  say "   Still plugged in after 20 minutes. Stopping; nothing changed."
  sleep 8; exit 1
fi
note "laptop unplugged"
state

trap restore EXIT
[ -d "$G" ] && w "$G/UDC" ""
w "$OTG" host
sleep 2
state
kernel_log 20
note "5 V pin after switching to host: $(pin) (hi means the driver powers the port by itself)"

say ""
say "   2. Plug the USB-C cable from this unit's right port"
say "      into the other unit's right port. Keep the other unit on."
T0=$(date +%s.%N)
RN=""
for i in $(seq 360); do
  for d in /sys/class/net/*; do
    m=$(cat "$d/address" 2>/dev/null)
    if [[ "$m" =~ ^02:36:00:00:([0-9a-f]{2}):02$ ]]; then LIF=$(basename "$d"); RN=$((16#${BASH_REMATCH[1]})); break; fi
  done
  [ -n "$LIF" ] && break
  # The driver does not power the port by itself in host mode (seen 2026-11-13), so 3 s after
  # the prompt, if the port still has no power, take its switch from the
  # regulator and turn it on directly.
  if [ "$FORCED_VBUS" = 0 ] && [ "$i" -ge 6 ] && [ "$(pin)" != hi ]; then
    if [ "$(vbus_users)" != 0 ]; then
      note "no 5 V on the port, but its regulator is in use ($(vbus_users) users): not forcing it"
      FORCED_VBUS=2
      continue
    fi
    note "no 5 V on the port 3 s after the prompt: switching it on directly (gpio $VBUS_GPIO)"
    w $VREG/unbind vbus_host
    w /sys/class/gpio/export $VBUS_GPIO
    w /sys/class/gpio/gpio$VBUS_GPIO/direction high
    FORCED_VBUS=1
    state
  fi
  sleep 0.5
done
if [ -z "$LIF" ]; then
  note "no other unit appeared"
  state
  kernel_log 40
  say ""
  say "   No other unit showed up in 3 minutes."
  say "   Putting this unit back. Then plug it into the laptop."
  sleep 10; exit 1
fi
note "other unit $RN appeared as $LIF after $(awk -v a="$T0" -v b="$(date +%s.%N)" 'BEGIN{printf "%.1f", b-a}') s (5 V forced: $FORCED_VBUS)"

REMOTE=10.36.$RN.1
$ESUDO ip addr flush dev "$LIF"
$ESUDO ip addr add "10.36.$RN.2/24" dev "$LIF"
$ESUDO ip link set "$LIF" up
state
kernel_log 15
note "usb speeds: $(cat /sys/bus/usb/devices/*/speed 2>/dev/null | tr '\n' ' ')"
say ""
say "   Linked to unit $RN. Measuring for about a minute..."
for i in $(seq 20); do ping -c1 -W1 "$REMOTE" >/dev/null 2>&1 && break; done

( while true; do echo "$(date +%s) $(cat $BAT/current_now) $(cat $BAT/voltage_now) $(cat $USBON)" >> "$OUT/battery.tmp"; sleep 1; done ) &
BATPID=$!
note "== small packets (32 bytes of data), 100 a second for 30 s: game-state sized"
$ESUDO ping -q -i 0.01 -c 3000 -s 32 "$REMOTE" >> "$LOG" 2>&1
note "== large packets (1400 bytes), 200 a second for 10 s"
$ESUDO ping -q -i 0.005 -c 2000 -s 1400 "$REMOTE" >> "$LOG" 2>&1
note "== one ping every 0.2 s for 10 s, every reply listed"
ping -c 50 -i 0.2 "$REMOTE" >> "$LOG" 2>&1
note "== TCP: the other unit's ssh port"
{ time nc -z -w 3 "$REMOTE" 22; } >> "$LOG" 2>&1 && note "ssh port answered"
kill "$BATPID" 2>/dev/null
note "== battery samples (unix time, current uA, voltage uV, usb power present)"
cat "$OUT/battery.tmp" >> "$LOG" 2>/dev/null; rm -f "$OUT/battery.tmp"
state
kernel_log 20

say ""
say "   Results (round trips, ms):"
grep -E 'packets transmitted|^rtt' "$LOG" | head -4 | while read -r l; do say "   $l"; done
say ""
say "   Done. Unplug the cable between the units,"
say "   then plug this unit back into the laptop."
sleep 8
exit 0
