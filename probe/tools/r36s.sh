#!/usr/bin/env bash
# r36s: talk to R36S handhelds over the USB-C data cable (golden image v2 + GameguyUSBNet).
# Each unit appears as a USB Ethernet adapter; the laptop gets 10.36.N.2, the unit is 10.36.N.1.
#
#   r36s.sh list                         connected units
#   r36s.sh ssh [N] [command...]         shell / command on unit N (default: the only one)
#   r36s.sh push [N] LOCAL REMOTE        copy files/dirs to the unit (rsync)
#   r36s.sh pull [N] REMOTE LOCAL        copy files/dirs from the unit
#   r36s.sh run [N] SCRIPT [args...]     stop EmulationStation, run SCRIPT on the unit's screen, restart ES
#   r36s.sh run-detached [N] SCRIPT ...  same, but keeps running after the cable is unplugged
#   r36s.sh stop-es [N] | start-es [N]
set -euo pipefail
ROOT="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
KEY="$ROOT/.tools/ssh/gameguy_r36s"
SSHO=(-i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5)

# Units are found by the laptop-side MAC each unit's gadget assigns (02:36:00:00:NN:02, NN = unit in hex).
# Address: IPv4 10.36.N.1 when DHCP worked, else IPv6 link-local fe80::36:ff:fe00:NN01%<iface> (always works).
ifaces() { for d in /sys/class/net/*; do m=$(cat "$d/address" 2>/dev/null); if [[ "$m" =~ ^02:36:00:00:([0-9a-f]{2}):02$ ]]; then echo "$((16#${BASH_REMATCH[1]})) $(basename "$d")"; fi; done; return 0; }
units() { ifaces | cut -d' ' -f1 | sort -un; }
iface_of() { ifaces | awk -v n="$1" '$1==n {print $2; exit}'; }
pick() {  # $1 may be a unit number; prints "N shift"
  local all; all=$(units)
  if [[ "${1:-}" =~ ^[0-9]+$ ]] && grep -qx "$1" <<<"$all"; then echo "$1 1"; return; fi
  local n; n=$(wc -l <<<"$all")
  [ -n "$all" ] || { echo "no unit connected (good data cable in the RIGHT port; GameguyUSBNet run once)" >&2; exit 1; }
  [ "$n" -eq 1 ] || { echo "several units connected: $(tr '\n' ' ' <<<"$all")- give the unit number" >&2; exit 1; }
  echo "$all 0"
}
addr() {  # bare address for ssh
  if ip -4 -o addr show 2>/dev/null | grep -q "10\.36\.$1\.2/"; then echo "10.36.$1.1"
  else printf 'fe80::36:ff:fe00:%02x01%%%s' "$1" "$(iface_of "$1")"; fi
}
host() { echo "ark@$(addr "$1")"; }
rhost() { local a; a=$(addr "$1"); [[ "$a" == *:* ]] && echo "ark@[$a]" || echo "ark@$a"; }   # rsync form

cmd=${1:-list}; shift || true
case "$cmd" in
  list)
    for n in $(units); do
      printf 'unit %-4s %-34s ' "$n" "$(addr "$n")"
      ssh "${SSHO[@]}" "$(host "$n")" 'echo "$(uname -r) | up $(cut -d. -f1 /proc/uptime)s | $(cat /sys/class/power_supply/battery/capacity 2>/dev/null)% batt"' 2>/dev/null || echo "(no ssh)"
    done ;;
  ssh)
    read -r N s < <(pick "${1:-}"); [ "$s" = 1 ] && shift
    exec ssh "${SSHO[@]}" -t "$(host "$N")" "$@" ;;
  push)
    read -r N s < <(pick "${1:-}"); [ "$s" = 1 ] && shift
    rsync -a --info=progress2 -e "ssh ${SSHO[*]}" "$1" "$(rhost "$N"):$2" ;;
  pull)
    read -r N s < <(pick "${1:-}"); [ "$s" = 1 ] && shift
    rsync -a --info=progress2 -e "ssh ${SSHO[*]}" "$(rhost "$N"):$1" "$2" ;;
  stop-es|start-es)
    read -r N s < <(pick "${1:-}")
    ssh "${SSHO[@]}" "$(host "$N")" "sudo systemctl ${cmd%-es} emulationstation" ;;
  run|run-detached)
    read -r N s < <(pick "${1:-}"); [ "$s" = 1 ] && shift
    script=$1; shift
    # mirror EmulationStation's Ports launch: "sudo perfmax %GOVERNOR% %ROM%; nice -n -19 %ROM%; sudo perfnorm"
    # = performance governors + ~/.asoundrc (dmix, 1024-frame periods) moved aside, restored afterwards
    if [ "$cmd" = run-detached ]; then RUNNER='cat > /tmp/r36s-run.sh; (setsid nohup bash /tmp/r36s-run.sh > /tmp/r36s-run.log 2>&1 < /dev/null &); echo detached'; else RUNNER='bash -s'; fi
    ssh "${SSHO[@]}" "$(host "$N")" "$RUNNER" <<EOS
set -u
G_GPU=/sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor
G_CPU=/sys/devices/system/cpu/cpufreq/policy0/scaling_governor
G_DMC=/sys/devices/platform/dmc/devfreq/dmc/governor
restore() {
  [ -f ~/.asoundrc.r36s-run ] && mv -f ~/.asoundrc.r36s-run ~/.asoundrc
  echo simple_ondemand | sudo tee \$G_GPU >/dev/null; echo ondemand | sudo tee \$G_CPU >/dev/null
  echo dmc_ondemand | sudo tee \$G_DMC >/dev/null
  sudo systemctl start emulationstation
}
trap restore EXIT
sudo systemctl stop emulationstation; sleep 1
for g in \$G_GPU \$G_CPU \$G_DMC; do echo performance | sudo tee \$g >/dev/null; done
[ -f ~/.asoundrc ] && mv -f ~/.asoundrc ~/.asoundrc.r36s-run
cd "\$(dirname '$script')" && sudo nice -n -19 sudo -u ark bash '$script' $*
EOS
    ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
