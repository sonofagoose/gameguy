#!/bin/bash
# page: flat or deep? The wheel toy's garden as a page, a place, or both (EmulationStation "Ports" launcher).
#
# With a card named GAMEGUY in the TF2 slot, every session is kept on the card as a page of a
# book (design/the-card.md): the sound of the session, the day seen from above, a few facts and
# the log, with an index.html that any browser can open. Without one, session logs go to
# gameguypage/results/ next to this script, as before.

# Standard PortMaster discovery: gives the SDL controller mapping for this device.
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
if [ -d "/opt/system/Tools/PortMaster/" ]; then controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then controlfolder="$XDG_DATA_HOME/PortMaster"
else controlfolder="/roms/ports/PortMaster"; fi
if [ -f "$controlfolder/control.txt" ]; then
  source "$controlfolder/control.txt"
  get_controls 2>/dev/null
  [ -n "$sdl_controllerconfig" ] && export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
fi

HERE="$(dirname "$(readlink -f "$0")")"
GAMEDIR="$HERE/gameguypage"
cd "$GAMEDIR" || exit 1
mkdir -p results
STAMP=$(date +%Y%m%d-%H%M%S)
chmod +x ./page-aarch64 2>/dev/null
export PATH="/usr/local/sbin:/usr/sbin:/sbin:$PATH"

# ---------------------------------------------------------------- the game card

CARD=/run/gameguy-card
SLOT=ff380000.dwmmc   # the TF2 slot's controller on these handhelds
DRIVER=/sys/bus/platform/drivers/dwmmc_rockchip

# The first partition named GAMEGUY on an SD card. The built-in storage is never an SD card.
card_dev() {
  local b p
  for b in /sys/block/mmcblk[0-9]*; do
    [ "$(cat "$b/device/type" 2>/dev/null)" = SD ] || continue
    for p in /dev/"$(basename "$b")"p*; do
      [ -b "$p" ] && [ "$(lsblk -no LABEL "$p" 2>/dev/null)" = GAMEGUY ] && { echo "$p"; return; }
    done
  done
}

# This slot only looks for a card when the handheld starts, so a card put in later is not seen.
# Ask it to look again: but only if it is the slot this script knows, nothing in it is mounted,
# and the system does not live on it.
look_again() {
  [ -e "$DRIVER/$SLOT" ] || return
  local b root
  for b in /sys/block/mmcblk[0-9]*; do
    readlink -f "$b/device" | grep -q "$SLOT" || continue
    grep -q "^/dev/$(basename "$b")" /proc/mounts && return
  done
  root=$(lsblk -no PKNAME "$(findmnt -n -o SOURCE /)" 2>/dev/null)
  [ -n "$root" ] && readlink -f "/sys/block/$root/device" | grep -q "$SLOT" && return
  echo "$SLOT" | sudo -n tee "$DRIVER/unbind" > /dev/null 2>&1
  echo "$SLOT" | sudo -n tee "$DRIVER/bind" > /dev/null 2>&1
  local i
  for i in $(seq 1 40); do [ -n "$(card_dev)" ] && return; sleep 0.1; done
}

# The book's index: every session, newest first, readable in any browser.
write_index() {
  local root=$1 d f when played line
  {
    printf '%s\n' '<!DOCTYPE html>' '<html lang="en"><head><meta charset="utf-8">' \
      '<meta name="viewport" content="width=device-width, initial-scale=1">' '<title>gameguy</title>' '<style>' \
      'body{background:#0A0A0A;color:#E2D6C8;font-family:"Space Mono",ui-monospace,monospace;max-width:680px;margin:0 auto;padding:28px 18px}' \
      'h1{font-size:13px;font-weight:normal;letter-spacing:.35em;margin:0 0 36px}' \
      'article{margin:0 0 56px}' 'img{display:block;width:100%;border:1px solid #141414}' \
      'audio{display:block;width:100%;margin:10px 0 0}' \
      'p{font-size:12px;letter-spacing:.06em;line-height:1.7;color:#C0C0C0;margin:10px 0 0}' \
      '</style></head><body>' '<h1>GAMEGUY</h1>'
    for d in $(ls -1 "$root/book" 2>/dev/null | sort -r); do
      f="$root/book/$d"
      [ -d "$f" ] || continue
      printf '<article>\n'
      [ -f "$f/page.png" ] && printf '<img src="book/%s/page.png" alt="the day, from above">\n' "$d"
      [ -f "$f/song.wav" ] && printf '<audio controls preload="none" src="book/%s/song.wav"></audio>\n' "$d"
      if [ -f "$f/facts.txt" ]; then
        when=$(sed -n 's/^when=//p' "$f/facts.txt")
        played=$(sed -n 's/^played=//p' "$f/facts.txt" | cut -d. -f1)
        played=${played:-0}
        line="$when &middot; $((played / 60)) min $((played % 60)) s"
        grep -q '^found_drip=yes' "$f/facts.txt" && line="$line &middot; in with Drip"
        grep -q '^knots_opened=yes' "$f/facts.txt" && line="$line &middot; the knots came open"
        line="$line &middot; $(sed -n 's/^came_home=//p' "$f/facts.txt") came home"
        line="$line &middot; longest walk $(sed -n 's/^best_walk=//p' "$f/facts.txt")"
      else
        line="${d:0:4}-${d:4:2}-${d:6:2} ${d:9:2}:${d:11:2} &middot; cut off before it ended"
      fi
      printf '<p>%s &middot; <a style="color:#C0C0C0" href="book/%s/log.txt">log</a></p>\n' "$line" "$d"
      printf '</article>\n'
    done
    printf '</body></html>\n'
  } > "$root/index.html.new" && mv -f "$root/index.html.new" "$root/index.html"
}

write_readme() {
  cat > "$1/README.txt" <<'EOF'
This is a gameguy card.

It lives in the TF2 slot of a gameguy handheld. Every session played there leaves a page in
book/: the sound of the session (song.wav), the day seen from above (page.png), a few facts and
the log. Open index.html in any browser to read the whole book.

If gameguy/page-aarch64 is on this card, the handheld runs the game from the card itself.
EOF
}

WHERE=""
MOUNTED_HERE=no
DEV=$(card_dev)
if [ -z "$DEV" ]; then
  look_again
  DEV=$(card_dev)
fi
if [ -n "$DEV" ]; then
  WHERE=$(findmnt -n -o TARGET "$DEV" | head -1)   # already mounted (by ArkOS as /roms2, say)
  if [ -z "$WHERE" ]; then
    FS=$(lsblk -no FSTYPE "$DEV")
    # put right whatever a power cut may have left half-written
    [ "$FS" = exfat ] && sudo -n fsck.exfat -p "$DEV" > /dev/null 2>&1
    sudo -n mkdir -p "$CARD"
    sudo -n mount -t "$FS" -o uid=1000,gid=1000,umask=0000,noatime "$DEV" "$CARD" && WHERE=$CARD && MOUNTED_HERE=yes
  fi
fi

BIN=./page-aarch64
if [ -n "$WHERE" ]; then
  mkdir -p "$WHERE/book"
  CONSOLE="$WHERE/book/console.log"
  ARGS=(--book "$WHERE/book")
  # the game itself, carried on the card
  [ -x "$WHERE/gameguy/page-aarch64" ] && BIN="$WHERE/gameguy/page-aarch64"
else
  CONSOLE="results/console-$STAMP.log"
  ARGS=(--out results)
fi

# ---------------------------------------------------------------- the handheld

# Reading or writing the built-in storage stalls frames for up to a quarter of a second on this
# handheld: its controller raises about 70,000 interrupts a second on the core that also serves
# the GPU and the display (measured 2026-11-14, docs/hardware-target.md). So the storage
# controllers' interrupts get the last core to themselves while the toy runs, and the toy keeps
# to the other three.
PIN=""
SDIRQS=$(grep -a dw-mci /proc/interrupts | cut -d: -f1 | tr -d ' ')
for i in $SDIRQS; do
  echo 3 | sudo -n tee "/proc/irq/$i/smp_affinity_list" > /dev/null 2>&1 && PIN="taskset -c 0-2"
done
command -v taskset > /dev/null || PIN=""

# The menu can start a port with the clocks left to scale themselves ("ondemand"). On this
# handheld that leaves the GPU at its slowest, and a toy at about two thirds of its frame rate
# with a gap in the sound every half minute (measured 2026-11-15, docs/hardware-target.md). So
# the launcher pins the CPU, GPU and memory clocks at full speed itself. Whatever started it
# (the menu's perfnorm, or r36s.sh) puts the clocks back afterwards.
G_CPU=/sys/devices/system/cpu/cpufreq/policy0/scaling_governor
G_GPU=/sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor
G_MEM=/sys/devices/platform/dmc/devfreq/dmc/governor
WERE="cpu $(cat $G_CPU 2>/dev/null), gpu $(cat $G_GPU 2>/dev/null), memory $(cat $G_MEM 2>/dev/null)"
for g in $G_CPU $G_GPU $G_MEM; do echo performance | sudo -n tee "$g" > /dev/null 2>&1; done
# Let the toy's sound thread ask for real-time priority, ahead of everything ordinary.
sudo -n prlimit --pid $$ --rtprio=40:40 > /dev/null 2>&1

{ echo "session $STAMP"
  echo "clocks as started: $WERE"
  echo "clocks now: cpu $(cat $G_CPU 2>/dev/null), gpu $(cat $G_GPU 2>/dev/null), memory $(cat $G_MEM 2>/dev/null)"
  echo "priority: nice $(nice), real-time limit $(ulimit -r); storage interrupts on core(s) $(for i in $SDIRQS; do cat /proc/irq/$i/smp_affinity_list; done | sort -u | tr '\n' ' '); run with: ${PIN:-no pinning}"
  if [ -n "$WHERE" ]; then echo "game card: $DEV at $WHERE ($( [ "$MOUNTED_HERE" = yes ] && echo "mounted for this session" || echo "already mounted")); running $BIN"
  else echo "game card: none; results stay on the handheld"; fi
} > "$CONSOLE"
$PIN "$BIN" "${ARGS[@]}" "$@" >> "$CONSOLE" 2>&1
echo "exit code $?" >> "$CONSOLE"
for i in $SDIRQS; do echo 0-3 | sudo -n tee "/proc/irq/$i/smp_affinity_list" > /dev/null 2>&1; done

if [ -n "$WHERE" ]; then
  write_index "$WHERE"
  [ -f "$WHERE/README.txt" ] || write_readme "$WHERE"
  sync
  [ "$MOUNTED_HERE" = yes ] && sudo -n umount "$CARD"
fi
sync
