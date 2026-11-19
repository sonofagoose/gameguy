#!/usr/bin/env bash
# Build the game.
#   ./build.sh          tests, laptop build, handheld build, the pack for Ports
#   ./build.sh laptop   tests and the laptop build only
# Needs Zig at ../.tools/zig/zig: it is the compiler for both machines and translates the C headers.
set -euo pipefail
cd "$(dirname "$0")"
ZIG=${ZIG:-../.tools/zig/zig}
HEADERS=../probe/third_party   # SDL2 and Khronos headers: declarations only, both load at run time
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

echo "== tests (the rules, the sound, the arithmetic: nothing that needs a screen)"
"$ZIG" test src/rules.zig --cache-dir build/cache 2>&1 | tail -1

echo "== laptop (x86_64)"
build_for x86_64

echo "== no screen: the lines bench runs, dumps its frames, and writes nothing to the error stream"
rm -rf build/frames && mkdir -p build/frames
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy build/gameguy-x86_64 --lines --headless --frames 6 \
    --dump build/frames > build/headless.out 2> build/headless.err
if [ -s build/headless.err ]; then echo "the run wrote to the error stream:"; cat build/headless.err; exit 1; fi
ls build/frames | sed 's/^/   /'

echo "== no screen: the dark and the call, twenty seconds of the scripted hands, frames and sound kept"
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy build/gameguy-x86_64 --headless --frames 1200 \
    --dump build/frames --dump-every 150 --wav build/dark.wav > build/dark.out 2> build/dark.err
if [ -s build/dark.err ]; then echo "the run wrote to the error stream:"; cat build/dark.err; exit 1; fi
tail -1 build/dark.out | sed 's/^/   /'

echo "== same take: ten minutes of the world and the sound, fingerprinted"
build/same-take-x86_64 10 2> build/same-take-x86_64.txt
tail -1 build/same-take-x86_64.txt | sed 's/^/   /'
if [ -f results/same-take-aarch64.txt ]; then
  if diff -q <(grep minute build/same-take-x86_64.txt) <(grep minute results/same-take-aarch64.txt) > /dev/null; then
    echo "   the same as the handheld's last run, minute for minute"
  else
    echo "   DIFFERENT from the handheld's last run (results/same-take-aarch64.txt): run it there again"
  fi
fi
[ "${1:-}" = laptop ] && exit 0

echo "== handheld (aarch64, glibc 2.30 floor, Cortex-A35)"
build_for aarch64 -target aarch64-linux-gnu.2.30 -mcpu=cortex_a35
readelf -V build/gameguy-aarch64 | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1 | sed 's/^/   highest glibc symbol: /'

echo "== pack"
rm -rf dist
P=dist/ports
mkdir -p "$P/gameguy"
cp build/gameguy-aarch64 build/modes-aarch64 build/same-take-aarch64 "$P/gameguy/"
cp port/Gameguy.sh "$P/"
chmod +x "$P/Gameguy.sh" "$P/gameguy/gameguy-aarch64" "$P/gameguy/modes-aarch64"
find dist -type f | sort | sed 's/^/   /'
