#!/usr/bin/env bash
# Build the meadow toy.
#   ./build.sh          tests, laptop binary, handheld binary, dist/ package
#   ./build.sh laptop   tests and laptop binary only
# Needs Zig at ../../.tools/zig/zig (it is the compiler for both targets and translates the C headers).
set -euo pipefail
cd "$(dirname "$0")"
ZIG=${ZIG:-../../.tools/zig/zig}
HEADERS=../../probe/third_party   # SDL2 and Khronos headers (declarations only; both load at run time)
mkdir -p build

build_for() {  # name, then extra zig flags for the target
  local name=$1; shift
  "$ZIG" translate-c "$@" -I "$HEADERS" -lc ../common/shim.h > "build/c-$name.zig"
  "$ZIG" build-exe "$@" -O ReleaseSafe --dep c --dep common -Mroot=src/main.zig -Mc="build/c-$name.zig" \
      --dep c -Mcommon=../common/common.zig \
      -lc -ldl -lm -femit-bin="build/meadow-$name" --cache-dir build/cache
}

echo "== rules tests (math, land, shapes, movement)"
"$ZIG" test src/mesh.zig --cache-dir build/cache 2>&1 | tail -1
"$ZIG" test src/player.zig --cache-dir build/cache 2>&1 | tail -1

echo "== laptop (x86_64)"
build_for x86_64
[ "${1:-}" = laptop ] && exit 0

echo "== handheld (aarch64, glibc 2.30 floor, Cortex-A35)"
build_for aarch64 -target aarch64-linux-gnu.2.30 -mcpu=cortex_a35
readelf -V build/meadow-aarch64 | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1 | sed 's/^/   highest glibc symbol: /'

echo "== package"
rm -rf dist
P=dist/ports
mkdir -p "$P/gameguymeadow"
cp build/meadow-aarch64 "$P/gameguymeadow/"
cp port/GameguyMeadow.sh "$P/"
chmod +x "$P/GameguyMeadow.sh" "$P/gameguymeadow/meadow-aarch64"
find dist -type f | sort
