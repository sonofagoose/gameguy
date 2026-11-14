#!/usr/bin/env bash
# Build the page toy.
#   ./build.sh          tests, laptop binary, handheld binary, dist/ package
#   ./build.sh laptop   tests and laptop binary only
# Needs Zig at ../../.tools/zig/zig (it is the compiler for both targets and translates the C headers).
# The rules, sound and arithmetic are the wheel toy's own files, used as they are (../wheel/src).
set -euo pipefail
cd "$(dirname "$0")"
ZIG=${ZIG:-../../.tools/zig/zig}
HEADERS=../../probe/third_party   # SDL2 and Khronos headers (declarations only; both load at run time)
mkdir -p build

build_for() {  # name, then extra zig flags for the target
  local name=$1; shift
  "$ZIG" translate-c "$@" -I "$HEADERS" -lc ../common/shim.h > "build/c-$name.zig"
  "$ZIG" build-exe "$@" -O ReleaseSafe --dep c --dep common --dep wheel -Mroot=src/main.zig -Mc="build/c-$name.zig" \
      --dep c -Mcommon=../common/common.zig \
      -Mwheel=../wheel/src/rules.zig \
      -lc -ldl -lm -femit-bin="build/page-$name" --cache-dir build/cache
}

echo "== tests (the camera; the wheel toy's rules)"
"$ZIG" test src/cam.zig --cache-dir build/cache 2>&1 | tail -1
"$ZIG" test ../wheel/src/world.zig --cache-dir build/cache 2>&1 | tail -1

echo "== laptop (x86_64)"
build_for x86_64
[ "${1:-}" = laptop ] && exit 0

echo "== handheld (aarch64, glibc 2.30 floor, Cortex-A35)"
build_for aarch64 -target aarch64-linux-gnu.2.30 -mcpu=cortex_a35
readelf -V build/page-aarch64 | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1 | sed 's/^/   highest glibc symbol: /'

echo "== package"
rm -rf dist
P=dist/ports
mkdir -p "$P/gameguypage"
cp build/page-aarch64 "$P/gameguypage/"
cp port/GameguyPage.sh "$P/"
chmod +x "$P/GameguyPage.sh" "$P/gameguypage/page-aarch64"
find dist -type f | sort
