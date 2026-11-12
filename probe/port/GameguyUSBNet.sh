#!/bin/bash
# gameguy USB network: the handheld appears to a connected PC as a USB Ethernet adapter (CDC-ECM).
#   handheld 10.36.N.1, PC gets 10.36.N.2 by DHCP (N is derived from this unit's eMMC, so two
#   handhelds on one PC never clash). SSH: user ark, key from gameguy-ssh/authorized_keys.
# First run from Ports also installs a boot service, so afterwards the link comes up by itself
# whenever the system boots: just plug the cable in and ssh.
# Needs the device-tree patch in golden image v2 (OTG port in peripheral mode).
MODE=${1:-ports}
if [ "$(id -u)" = 0 ]; then ESUDO=""; else ESUDO=sudo; fi
SELF="$(readlink -f "$0")"
HERE="$(dirname "$SELF")"
LOG=/tmp/gameguy-usbnet.log
: > "$LOG" 2>/dev/null || LOG=/dev/null
msg() { echo "$*" >> "$LOG"; [ "$MODE" = ports ] && printf '%s\n' "$*" | $ESUDO tee /dev/tty1 >/dev/null 2>&1; }
run() { echo "+ $*" >> "$LOG"; $ESUDO "$@" >> "$LOG" 2>&1; }
w() { echo "$2" | $ESUDO tee "$1" >/dev/null; }

# unit number from the internal eMMC's CID
CID=""
for b in /sys/block/mmcblk*; do
  [ "$(cat "$b/device/type" 2>/dev/null)" = MMC ] && { CID=$(cat "$b/device/cid"); break; }
done
SUM=0
for i in $(seq 0 2 $((${#CID} - 2))); do SUM=$((SUM + 16#${CID:$i:2})); done
N=$((SUM % 200 + 20))
NH=$(printf '%02x' "$N")
IP=10.36.$N.1

msg "gameguy USB network: unit $N (cid ${CID:0:12}...)"
run modprobe dwc2
run modprobe libcomposite
run modprobe usb_f_ecm
mountpoint -q /sys/kernel/config || run mount -t configfs none /sys/kernel/config
G=/sys/kernel/config/usb_gadget/gameguy
[ -d "$G" ] && w "$G/UDC" ""
UDC=$(ls /sys/class/udc 2>/dev/null | head -1)
if [ -z "$UDC" ]; then
  msg "No USB device controller: the OTG port is not in device mode (needs golden image v2)."
  dmesg | grep -i -E 'dwc2|udc|otg|usb2phy' | tail -30 >> "$LOG"
  cp -f "$LOG" "$HERE/gameguyprobe/usbnet-last.log" 2>/dev/null
  [ "$MODE" = ports ] && sleep 6
  exit 1
fi
if [ ! -d "$G" ]; then
  run mkdir -p "$G/strings/0x409" "$G/configs/c.1/strings/0x409" "$G/functions/ecm.usb0"
  w "$G/idVendor" 0x1d6b
  w "$G/idProduct" 0x0104
  w "$G/bcdDevice" 0x0100
  w "$G/bcdUSB" 0x0200
  w "$G/strings/0x409/manufacturer" "gameguy"
  w "$G/strings/0x409/product" "R36S unit $N"
  w "$G/strings/0x409/serialnumber" "gameguy-$N"
  w "$G/configs/c.1/strings/0x409/configuration" "ECM"
  w "$G/configs/c.1/MaxPower" 100
  w "$G/functions/ecm.usb0/dev_addr" "02:36:00:00:$NH:01"
  w "$G/functions/ecm.usb0/host_addr" "02:36:00:00:$NH:02"
  run ln -s "$G/functions/ecm.usb0" "$G/configs/c.1/"
fi
w "$G/UDC" "$UDC"
sleep 1
IF=$(cat "$G/functions/ecm.usb0/ifname" 2>/dev/null || echo usb0)
run ip addr flush dev "$IF"
run ip addr add "$IP/24" dev "$IF"
run ip link set "$IF" up
# DHCP for the PC side runs as its own systemd service: anything started from a Port lives in
# EmulationStation's cgroup and is killed whenever EmulationStation is stopped.
[ -f /tmp/dnsmasq-gameguy.pid ] && $ESUDO kill "$(cat /tmp/dnsmasq-gameguy.pid)" 2>/dev/null
printf '%s\n' '[Unit]' 'Description=gameguy USB network DHCP (dnsmasq)' 'After=network-pre.target' '' '[Service]' \
  "ExecStart=/usr/sbin/dnsmasq --keep-in-foreground --conf-file=/dev/null --interface=$IF --bind-interfaces --port=0 --dhcp-range=10.36.$N.2,10.36.$N.2,255.255.255.0,12h --dhcp-option=3 --dhcp-option=6 --dhcp-authoritative --log-facility=/tmp/dnsmasq-gameguy.log" \
  'Restart=always' 'RestartSec=2' '' '[Install]' 'WantedBy=multi-user.target' \
  | $ESUDO tee /etc/systemd/system/gameguy-dhcp.service >/dev/null
run systemctl daemon-reload
run systemctl restart gameguy-dhcp.service

# SSH: key login for user ark. Keys go to a root-owned file that sshd trusts regardless of the
# permissions of /home/ark (ArkOS-family home folders are often group/world-writable, which makes
# sshd's StrictModes ignore ~/.ssh/authorized_keys).
KEYS="$HERE/gameguy-ssh/authorized_keys"
if [ -f "$KEYS" ]; then
  run install -m 644 -o root -g root "$KEYS" /etc/ssh/gameguy_authorized_keys
  # this firmware ships /etc and /home/ark mode 777, so sshd's StrictModes refuses every key
  CONF=$'AuthorizedKeysFile .ssh/authorized_keys /etc/ssh/gameguy_authorized_keys\nStrictModes no'
  if grep -q '^Include /etc/ssh/sshd_config.d' /etc/ssh/sshd_config 2>/dev/null; then
    echo "$CONF" | $ESUDO tee /etc/ssh/sshd_config.d/gameguy.conf >/dev/null
  elif ! grep -q gameguy_authorized_keys /etc/ssh/sshd_config 2>/dev/null; then
    echo "$CONF" | $ESUDO tee -a /etc/ssh/sshd_config >/dev/null
  fi
  run systemctl restart ssh || run systemctl restart sshd
fi
run systemctl start ssh || run systemctl start sshd

# boot service (installed once, from the Ports launch)
[ "$MODE" = ports ] && run install -m 755 "$SELF" /usr/local/bin/gameguy-usbnet   # keep the boot copy current
if [ "$MODE" = ports ] && [ ! -f /etc/systemd/system/gameguy-usbnet.service ]; then
  printf '%s\n' '[Unit]' 'Description=gameguy USB network (CDC-ECM gadget + DHCP + ssh)' \
    'After=local-fs.target' '' '[Service]' 'Type=oneshot' 'RemainAfterExit=yes' \
    'ExecStart=/usr/local/bin/gameguy-usbnet boot' '' '[Install]' 'WantedBy=multi-user.target' \
    | $ESUDO tee /etc/systemd/system/gameguy-usbnet.service >/dev/null
  run systemctl daemon-reload
  run systemctl enable gameguy-usbnet.service
  msg "installed boot service: the USB link will come up by itself from now on"
fi
{ ip addr show "$IF"; cat "$G/UDC"; } >> "$LOG" 2>&1
printf 'unit=%s ip=%s cid=%s\n' "$N" "$IP" "$CID" > "$HERE/gameguyprobe/usbnet-info.txt" 2>/dev/null
cp -f "$LOG" "$HERE/gameguyprobe/usbnet-last.log" 2>/dev/null
msg "USB network up: ssh ark@$IP  (link stays up; returns to the menu)"
[ "$MODE" = ports ] && sleep 4
exit 0
