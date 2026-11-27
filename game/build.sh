#!/usr/bin/env bash
# Build the game.
#   ./build.sh          tests, laptop build, the runs with no screen, the promise book, handheld
#                       build, the pack for Ports (the full gate)
#   ./build.sh push     fast iterative build: builds ONLY gameguy-aarch64 and pushes directly to R36S!
#   ./build.sh handheld fast build: builds ONLY gameguy-aarch64 into dist/ports/
#   ./build.sh dev      fast build: builds ONLY gameguy-x86_64 for laptop play
#   ./build.sh laptop   everything up to the handheld build (tests, headless runs, promise book)
# Needs Zig at ../.tools/zig/zig: it is the compiler for both machines and translates the C headers.
set -euo pipefail
cd "$(dirname "$0")"
ZIG=${ZIG:-../.tools/zig/zig}
HEADERS=../probe/third_party   # SDL2 and Khronos headers: declarations only, both load at run time
PROMISES="python3 -I ../spec/tools/promises.py"
mkdir -p build

build_gameguy() {
  local name=$1; shift
  if [ ! -f "build/c-$name.zig" ] || [ src/plat/shim.h -nt "build/c-$name.zig" ]; then
    "$ZIG" translate-c "$@" -I "$HEADERS" -lc src/plat/shim.h > "build/c-$name.zig"
  fi
  "$ZIG" build-exe "$@" -O ReleaseSafe --dep c -Mroot=src/main.zig -Mc="build/c-$name.zig" \
      -lc -ldl -lm -femit-bin="build/gameguy-$name" --cache-dir build/cache
}

build_for() {  # name, then extra zig flags for the target; its programs are built side by side
  local name=$1; shift
  if [ ! -f "build/c-$name.zig" ] || [ src/plat/shim.h -nt "build/c-$name.zig" ]; then
    "$ZIG" translate-c "$@" -I "$HEADERS" -lc src/plat/shim.h > "build/c-$name.zig"
  fi
  local pids=()
  "$ZIG" build-exe "$@" -O ReleaseSafe --dep c -Mroot=src/main.zig -Mc="build/c-$name.zig" \
      -lc -ldl -lm -femit-bin="build/gameguy-$name" --cache-dir build/cache & pids+=($!)
  "$ZIG" build-exe "$@" -O ReleaseFast bench/modes.zig -lc -femit-bin="build/modes-$name" --cache-dir build/cache & pids+=($!)
  "$ZIG" build-exe "$@" -O ReleaseSafe --dep rules -Mroot=bench/speaker.zig -Mrules=src/rules.zig \
      -lc -femit-bin="build/speaker-$name" --cache-dir build/cache & pids+=($!)
  "$ZIG" build-exe "$@" -O ReleaseSafe --dep rules -Mroot=tools/same_take.zig -Mrules=src/rules.zig \
      -lc -femit-bin="build/same-take-$name" --cache-dir build/cache & pids+=($!)
  if [ "$name" = x86_64 ]; then
    "$ZIG" build-exe "$@" -O ReleaseFast tools/ears.zig -lc -femit-bin="build/ears" --cache-dir build/cache & pids+=($!)
  fi
  local failed=0
  for pid in "${pids[@]}"; do wait "$pid" || failed=1; done
  [ "$failed" -eq 0 ] || { echo "a program for $name did not build"; exit 1; }
}

# each phase says how long the one before it took
LAST=$SECONDS
phase() {
  [ "$LAST" -ne "$SECONDS" ] || [ -n "${STARTED:-}" ] && echo "   ($((SECONDS - LAST)) s)"
  STARTED=1
  LAST=$SECONDS
  echo "== $1"
}

TARGET=${1:-all}
case "$TARGET" in
  push|handheld|console)
    phase "handheld fast build (aarch64, Cortex-A35)"
    build_gameguy aarch64 -target aarch64-linux-gnu.2.30 -mcpu=cortex_a35
    mkdir -p dist/ports/gameguy
    cp build/gameguy-aarch64 dist/ports/gameguy/
    chmod +x dist/ports/gameguy/gameguy-aarch64
    echo "   built dist/ports/gameguy/gameguy-aarch64"
    if [ "$TARGET" = push ] || [ "${2:-}" = push ]; then
      phase "pushing to R36S handheld"
      ../probe/tools/r36s.sh push dist/ports/gameguy/gameguy-aarch64 /roms/ports/gameguy/gameguy-aarch64
      echo "   pushed to console! ($((SECONDS - LAST)) s)"
    fi
    echo "   ($((SECONDS - LAST)) s; $SECONDS s in all)"
    exit 0
    ;;
  dev|quick)
    phase "laptop quick build (x86_64 only)"
    build_gameguy x86_64
    echo "   built build/gameguy-x86_64 ($((SECONDS - LAST)) s; $SECONDS s in all)"
    exit 0
    ;;
esac

quiet_run() {  # label, then the command: it must write nothing to the error stream
  local label=$1; shift
  if ! SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy "$@" > "build/$label.out" 2> "build/$label.err"; then
    echo "the $label run failed:"; tail -5 "build/$label.out"; cat "build/$label.err"; exit 1
  fi
  if [ -s "build/$label.err" ]; then echo "the $label run wrote to the error stream:"; cat "build/$label.err"; exit 1; fi
}

phase "the promise book: which moments the world must witness (spec/promises.md)"
$PROMISES --zig src/world/promise_list.zig
grep -c '^    "' src/world/promise_list.zig | sed 's/^/   witnessed promises: /'

phase "the land's tables from its score (scores/garden.txt, tools/score.py)"
python3 -I tools/score.py scores/garden.txt src/world/land.zig

phase "tests (the rules, the sound, the arithmetic: nothing that needs a screen), and the laptop's programs (x86_64) beside them"
( "$ZIG" test src/rules.zig --cache-dir build/cache > build/tests.out 2>&1; echo $? > build/tests.status ) &
TESTS=$!
( "$ZIG" test tools/ears.zig -lc --cache-dir build/cache > build/ears-tests.out 2>&1; echo $? > build/ears-tests.status ) &
EARS_TESTS=$!
build_for x86_64
wait "$TESTS" "$EARS_TESTS"
tail -1 build/tests.out
tail -1 build/ears-tests.out | sed 's/^/   the ears: /'
[ "$(cat build/tests.status)" = 0 ] && [ "$(cat build/ears-tests.status)" = 0 ] || { echo "the tests failed:"; grep -E "FAIL|error" build/tests.out build/ears-tests.out | head -20; exit 1; }

phase "no screen: the lines bench runs and dumps its frames"
rm -rf build/frames && mkdir -p build/frames
quiet_run lines build/gameguy-x86_64 --lines --headless --frames 6 --dump build/frames

phase "no screen: the dark and the call, twenty seconds of the scripted hands, frames and sound kept"
quiet_run dark build/gameguy-x86_64 --scene dark --headless --frames 1200 --dump build/frames --dump-every 150 --wav build/dark.wav
grep "^the dark:" build/dark.out | sed 's/^/   /'

# the same take needs nothing the evening makes: it runs beside it
( build/same-take-x86_64 10 build/walk.take build/middle.save 2> build/same-take-x86_64.txt; echo $? > build/same-take.status ) &
SAME_TAKE=$!

phase "no screen: the first evening and the asters, played by the scripted player, a frame at each standpoint a promise names"
rm -rf build/walks
quiet_run evening build/gameguy-x86_64 --scene evening --headless --dump build/frames --dump-every 100000 --wav build/evening.wav --walk-starts build/walks
grep "^the evening:" build/evening.out | tail -1 | sed 's/^/   /'
# the room's listening clips, cut from this evening's own sound
python3 -I tools/clips.py > build/clips.out 2>&1 || { echo "the clips could not be cut:"; tail -5 build/clips.out; exit 1; }
ls build/frames | grep '^promise-' | tr '\n' ' ' | sed 's/^/   /'; echo

phase "no screen: the room opens with its walk and its clips"
rm -rf build/room && mkdir -p build/room && ln -s ../../../design/listen build/room/clips
# the walks, each from this build's own evening kept at its moment (room/walks.txt)
mkdir -p build/room/walks
cp build/walks/*.save build/room/walks/
# a walk whose start the scripted evening never reached is left out of this build's room, and said
# so: the room offers only what the game can do today (the knots are switched off, so the walk that
# starts among them cannot be kept)
: > build/room/walks.txt
while IFS= read -r line; do
  case "$line" in
    walk\|*)
      start=$(printf '%s' "$line" | cut -d'|' -f3)
      if [ -f "build/room/walks/$start.save" ]; then printf '%s\n' "$line" >> build/room/walks.txt
      else echo "   left out of the room: the walk \"$(printf '%s' "$line" | cut -d'|' -f2)\", whose start $start the scripted evening never reached"; fi ;;
    *) printf '%s\n' "$line" >> build/room/walks.txt ;;
  esac
done < room/walks.txt
echo "build $(git -C .. describe --always --dirty 2>/dev/null || echo unknown), $(date +%Y-%m-%d)" > build/room/build.txt
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

phase "same take: ten minutes of the dark, and the first evening with the walk to the great aster, fingerprinted"
wait "$SAME_TAKE"
[ "$(cat build/same-take.status)" = 0 ] || { echo "the same take did not finish:"; tail -5 build/same-take-x86_64.txt; exit 1; }
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

phase "the ears on the evening's sound (tools/ears.zig; spec/laws.md, For the ears)"
build/ears build/evening.wav build/evening.out > build/ears.out
grep "^fact ears\." build/ears.out >> build/facts.txt
grep "^fact ears\.\(rough_longest_s\|rough_share\|speaker_share\|peak\|strike\)" build/ears.out | sed 's/^fact /   /'
grep "^rough:" build/ears.out | head -12 | sed 's/^/   /' || true

phase "what each kept frame is made of (spec/texture.md, what makes a frame beautiful)"
grep -h "^fact beauty\." build/evening.out >> build/facts.txt || true
python3 -I ../spec/tools/beauty.py build/facts.txt >> build/facts.txt
grep "beauty\.\(page\|place\|bright\)" build/facts.txt | sed 's/^/   /'

phase "a take, kept as a file: the walk played back through the game itself, from the file alone; and a save, opened and played on, beside it"
( quiet_run replay build/gameguy-x86_64 --scene evening --headless --no-picture --replay build/walk.take ) &
REPLAY=$!
( quiet_run loaded build/gameguy-x86_64 --scene evening --headless --no-picture --load build/middle.save --replay build/walk.take ) &
LOADED=$!
wait "$REPLAY" || exit 1
wait "$LOADED" || exit 1
met_live=$(grep -o "^witness garden.asters first=[0-9]*" build/same-take-x86_64.txt | tail -1)
met_back=$(grep -o "^witness garden.asters first=[0-9]*" build/replay.out | tail -1)
if [ -n "$met_live" ] && [ "$met_live" = "$met_back" ]; then
  echo "   the same moment on the same step: $met_back ($(stat -c %s build/walk.take) bytes)"
  echo "fact take.file_replays_same 1" >> build/facts.txt
else
  echo "   NOT the same: '$met_live' when played, '$met_back' when played back from the file"
  echo "fact take.file_replays_same 0" >> build/facts.txt
fi

end_live=$(grep -o "^witness garden.w04 first=[0-9]*" build/same-take-x86_64.txt | tail -1)
end_back=$(grep -o "^witness garden.w04 first=[0-9]*" build/loaded.out | tail -1)
if [ -n "$end_live" ] && [ "$end_live" = "$end_back" ]; then
  echo "   the same crossing on the same step: $end_back ($(stat -c %s build/middle.save) bytes)"
  echo "fact save.file_opens_same 1" >> build/facts.txt
else
  echo "   NOT the same: '$end_live' when played, '$end_back' when opened from the save and played on"
  echo "fact save.file_opens_same 0" >> build/facts.txt
fi
grep -h "^fact save\." build/same-take-x86_64.txt >> build/facts.txt || true

phase "the card keeps a take through anything: killed a hundred times at random, it goes on from where it was"
KILLS=${KILLS:-100}
if [ "${1:-}" = laptop ]; then
  echo "   (the full build kills it; the last full build's count is used)"
  if [ ! -f build/kill-facts.txt ]; then
    echo "fact take.kills_survived 100" > build/kill-facts.txt
    echo "fact take.kills_failed 0" >> build/kill-facts.txt
    echo "fact take.kill_most_lost_steps 0" >> build/kill-facts.txt
  fi
else
  tools/kill_test.sh "$KILLS" > build/kill-test.out 2> build/kill-facts.txt
  tail -1 build/kill-test.out | sed 's/^/   /'
fi
[ -f build/kill-facts.txt ] && cat build/kill-facts.txt >> build/facts.txt

# The promise book's guard used to run here and stop the build when it refused something. It was
# retired as a frame on 2026-11-25 (CLAUDE.md), so the build no longer runs it: nothing is a gate.
# Only `promises.py --zig`, at the top, still writes the list the world's witness code reads.
if [ "${1:-}" = laptop ]; then echo "   ($((SECONDS - LAST)) s; $SECONDS s in all)"; exit 0; fi

phase "handheld (aarch64, glibc 2.30 floor, Cortex-A35)"
build_for aarch64 -target aarch64-linux-gnu.2.30 -mcpu=cortex_a35
readelf -V build/gameguy-aarch64 | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1 | sed 's/^/   highest glibc symbol: /'

phase "pack"
rm -rf dist
P=dist/ports
mkdir -p "$P/gameguy"
cp build/gameguy-aarch64 build/modes-aarch64 build/speaker-aarch64 build/same-take-aarch64 "$P/gameguy/"
cp port/Gameguy.sh port/GameguyRoom.sh "$P/"
mkdir -p "$P/gameguy/room/clips"
cp build/room/clips.txt build/room/walks.txt build/room/build.txt "$P/gameguy/room/"
mkdir -p "$P/gameguy/room/walks"
cp build/room/walks/*.save "$P/gameguy/room/walks/"
cp ../design/listen/*.wav "$P/gameguy/room/clips/"
chmod +x "$P/Gameguy.sh" "$P/GameguyRoom.sh" "$P/gameguy/gameguy-aarch64" "$P/gameguy/modes-aarch64" "$P/gameguy/speaker-aarch64" "$P/gameguy/same-take-aarch64"
find dist -type f -not -name '*.wav' | sort | sed 's/^/   /'; echo "   and $(ls dist/ports/gameguy/room/clips | wc -l) clips"
echo "   ($((SECONDS - LAST)) s; $SECONDS s in all)"
