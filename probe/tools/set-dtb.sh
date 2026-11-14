#!/usr/bin/env bash
# set-dtb: put a new device tree on a handheld, guarded so a bad one undoes itself.
#   probe/tools/set-dtb.sh install N NEW.dtb   stage NEW.dtb on unit N, arm the guard, reboot it
#   probe/tools/set-dtb.sh confirm N           wait for unit N on the USB link, then confirm
# The current tree stays in /boot as <name>.prev-<first 8 hex of its md5>. After install, the unit
# has to be confirmed within 8 minutes of booting; otherwise its guard (gameguy-dtb-guard, next to
# this script, installed as a boot service) restores the previous tree and reboots.
set -euo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
R="$HERE/r36s.sh"
DTB=rk3326-r36s-type1-panel1-linux.dtb
cmd=${1:-}; N=${2:?unit number}
case "$cmd" in
  install)
    NEW=${3:?new .dtb file}
    SUM=$(md5sum "$NEW" | cut -d' ' -f1)
    "$R" push "$N" "$NEW" /tmp/gameguy-new.dtb >/dev/null
    "$R" push "$N" "$HERE/gameguy-dtb-guard" /tmp/gameguy-dtb-guard >/dev/null
    "$R" ssh "$N" "bash -s" <<EOS
set -e
cd /boot
[ "\$(md5sum /tmp/gameguy-new.dtb | cut -d' ' -f1)" = "$SUM" ] || { echo "upload damaged; nothing changed"; exit 1; }
PREV=$DTB.prev-\$(md5sum $DTB | cut -c1-8)
[ -f "\$PREV" ] || sudo cp -f $DTB "\$PREV"
sudo install -m 755 /tmp/gameguy-dtb-guard /usr/local/bin/gameguy-dtb-guard
printf '%s\n' '[Unit]' 'Description=gameguy device-tree guard (undoes an unconfirmed device-tree change)' \
  'After=local-fs.target' '' '[Service]' 'Type=simple' 'ExecStart=/usr/local/bin/gameguy-dtb-guard' '' \
  '[Install]' 'WantedBy=multi-user.target' | sudo tee /etc/systemd/system/gameguy-dtb-guard.service >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable gameguy-dtb-guard.service >/dev/null 2>&1
echo "\$PREV" | sudo tee /boot/gameguy-dtb-trial >/dev/null
sudo cp -f /tmp/gameguy-new.dtb $DTB
sync
if [ "\$(md5sum $DTB | cut -d' ' -f1)" != "$SUM" ]; then
  sudo cp -f "\$PREV" $DTB; sudo rm -f /boot/gameguy-dtb-trial; sync
  echo "copy failed; previous tree restored"; exit 1
fi
echo "installed $SUM; previous tree kept as /boot/\$PREV"
EOS
    "$R" ssh "$N" 'sudo systemctl reboot' >/dev/null 2>&1 || true
    echo "unit $N is rebooting; next: $0 confirm $N (within 8 minutes)" ;;
  confirm)
    for i in $(seq 120); do
      if "$R" ssh "$N" true >/dev/null 2>&1; then
        "$R" ssh "$N" 'touch /tmp/gameguy-dtb-ok; sleep 3
          if [ -f /boot/gameguy-dtb-trial ]; then echo "NOT confirmed yet: guard still waiting"; else echo "confirmed"; fi
          echo "dr_mode: $(tr -d "\0" < /proc/device-tree/usb@ff300000/dr_mode 2>/dev/null)"'
        exit 0
      fi
      sleep 3
    done
    echo "unit $N did not come back within 6 minutes; its guard restores the previous tree 8 minutes after boot"
    exit 1 ;;
  *) sed -n '2,7p' "$0"; exit 1 ;;
esac
