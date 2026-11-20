#!/usr/bin/env bash
# Build the game.
#   ./build.sh          tests, laptop build, the runs with no screen, the promise book, handheld
#                       build, the pack for Ports
#   ./build.sh laptop   everything up to the handheld build
# Needs Zig at ../.tools/zig/zig: it is the compiler for both machines and translates the C headers.
set -euo pipefail
cd "$(dirname "$0")"
ZIG=${ZIG:-../.tools/zig/zig}
HEADERS=../probe/third_party   # SDL2 and Khronos headers: declarations only, both load at run time
PROMISES="python3 -I ../spec/tools/promises.py"
mkdir -p build

build_for() {  # name, then extra zig flags for the target
  local name=$1; shift
  "$ZIG" translate-c "$@" -I "$HEADERS" -lc src/plat/shim.h > "build/c-$name.zig"
  "$ZIG" build-exe "$@" -O ReleaseSafe --dep c -Mroot=src/main.zig -Mc="build/c-$name.zig" \
      -lc -ldl -lm -femit-bin="build/gameguy-$name" --cache-dir build/cache
  "$ZIG" build-exe "$@" -O ReleaseFast bench/modes.zig -lc -femit-bin="build/modes-$name" --cache-dir build/cache
  "$ZIG" build-exe "$@" -O ReleaseSafe --dep rules -Mroot=tools/same_take.zig -Mrules=src/rules.zig \
      -lc -femit-bin="build/same-take-$name" --cache-dir build/cache
}

quiet_run() {  # label, then the command: it must write nothing to the error stream
  local label=$1; shift
  if ! SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy "$@" > "build/$label.out" 2> "build/$label.err"; then
    echo "the $label run failed:"; tail -5 "build/$label.out"; cat "build/$label.err"; exit 1
  fi
  if [ -s "build/$label.err" ]; then echo "the $label run wrote to the error stream:"; cat "build/$label.err"; exit 1; fi
}

echo "== the promise book: which moments the world must witness (spec/promises.md)"
$PROMISES --zig src/world/promise_list.zig
grep -c '^    "' src/world/promise_list.zig | sed 's/^/   witnessed promises: /'

echo "== tests (the rules, the sound, the arithmetic: nothing that needs a screen)"
"$ZIG" test src/rules.zig --cache-dir build/cache 2>&1 | tail -1

echo "== laptop (x86_64)"
build_for x86_64

echo "== no screen: the lines bench runs and dumps its frames"
rm -rf build/frames && mkdir -p build/frames
quiet_run lines build/gameguy-x86_64 --lines --headless --frames 6 --dump build/frames

echo "== no screen: the dark and the call, twenty seconds of the scripted hands, frames and sound kept"
quiet_run dark build/gameguy-x86_64 --headless --frames 1200 --dump build/frames --dump-every 150 --wav build/dark.wav
grep "^the dark:" build/dark.out | sed 's/^/   /'

echo "== no screen: the first evening and the asters, played by the scripted player, a frame at each standpoint a promise names"
quiet_run evening build/gameguy-x86_64 --scene evening --headless --dump build/frames --dump-every 100000 --wav build/evening.wav
grep "^the evening:" build/evening.out | tail -1 | sed 's/^/   /'
ls build/frames | grep '^promise-' | tr '\n' ' ' | sed 's/^/   /'; echo

echo "== no screen: the room opens with its walk and its clips"
rm -rf build/room && mkdir -p build/room && ln -s ../../../design/listen build/room/clips
$PROMISES --room build/room/promises.txt
python3 -I - > build/room/clips.txt <<'PY'
import re
rows = []
for line in open('../design/listen/README.md'):
    m = re.match(r'\|\s*(\d+-[a-z0-9-]+)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*$', line)
    if m:
        rows.append((int(m.group(1).split('-')[0]), m.group(1), m.group(3)))
for _, name, question in sorted(rows):
    print(f"{name}|{question}")
PY
quiet_run room build/gameguy-x86_64 --room build/room --headless --frames 5 --dump build/frames
grep "items" build/room.out | sed 's/^/   /'

echo "== same take: ten minutes of the dark, and the first evening with the walk to the great aster, fingerprinted"
build/same-take-x86_64 10 build/walk.take 2> build/same-take-x86_64.txt
grep -E "^(minute 10|evening end)" build/same-take-x86_64.txt | sed 's/^/   /'
identical=0
if [ -f results/same-take-aarch64.txt ]; then
  if diff -q <(grep -E "^(minute|evening)" build/same-take-x86_64.txt) <(grep -E "^(minute|evening)" results/same-take-aarch64.txt) > /dev/null; then
    echo "   the same as the handheld's last run, line for line"
    identical=1
  else
    echo "   DIFFERENT from the handheld's last run (results/same-take-aarch64.txt): run it there again"
  fi
fi
echo "fact same_take.identical $identical" > build/facts.txt

echo "== what each kept frame is made of (spec/texture.md, what makes a frame beautiful)"
grep -h "^fact beauty\." build/evening.out >> build/facts.txt || true
python3 -I ../spec/tools/beauty.py build/facts.txt >> build/facts.txt
grep "beauty\.\(page\|place\|bright\)" build/facts.txt | sed 's/^/   /'

echo "== a take, kept as a file: the walk played back through the game itself, from the file alone"
quiet_run replay build/gameguy-x86_64 --scene evening --headless --replay build/walk.take
met_live=$(grep -o "^witness garden.asters first=[0-9]*" build/same-take-x86_64.txt | tail -1)
met_back=$(grep -o "^witness garden.asters first=[0-9]*" build/replay.out | tail -1)
if [ -n "$met_live" ] && [ "$met_live" = "$met_back" ]; then
  echo "   the same moment on the same step: $met_back ($(stat -c %s build/walk.take) bytes)"
  echo "fact take.file_replays_same 1" >> build/facts.txt
else
  echo "   NOT the same: '$met_live' when played, '$met_back' when played back from the file"
  echo "fact take.file_replays_same 0" >> build/facts.txt
fi

echo "== the promise book: every claim, and where each promise stands (spec/promises/BOARD.md)"
$PROMISES | sed 's/^/   /'
[ "${PIPESTATUS[0]}" -eq 0 ] || { echo "the promise book refused something: see above"; exit 1; }
[ "${1:-}" = laptop ] && exit 0

echo "== handheld (aarch64, glibc 2.30 floor, Cortex-A35)"
build_for aarch64 -target aarch64-linux-gnu.2.30 -mcpu=cortex_a35
readelf -V build/gameguy-aarch64 | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1 | sed 's/^/   highest glibc symbol: /'

echo "== pack"
rm -rf dist
P=dist/ports
mkdir -p "$P/gameguy"
cp build/gameguy-aarch64 build/modes-aarch64 build/same-take-aarch64 "$P/gameguy/"
cp port/Gameguy.sh port/GameguyRoom.sh "$P/"
mkdir -p "$P/gameguy/room/clips"
cp build/room/clips.txt build/room/promises.txt "$P/gameguy/room/"
cp ../design/listen/*.wav "$P/gameguy/room/clips/"
chmod +x "$P/Gameguy.sh" "$P/GameguyRoom.sh" "$P/gameguy/gameguy-aarch64" "$P/gameguy/modes-aarch64" "$P/gameguy/same-take-aarch64"
find dist -type f -not -name '*.wav' | sort | sed 's/^/   /'; echo "   and $(ls dist/ports/gameguy/room/clips | wc -l) clips"
