#!/usr/bin/env bash
# Build the gameguy hardware probe.
#   ./build.sh          aarch64 device binary + x86_64 desktop binary + dist/ package
#   ./build.sh desktop  x86_64 only
# Requires: Zig at ../.tools/zig/zig (cross-compiler with bundled glibc stubs), gcc for the desktop build.
set -euo pipefail
cd "$(dirname "$0")"
ZIG=${ZIG:-../.tools/zig/zig}
CFLAGS=(-O2 -std=gnu11 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wno-sign-compare
        -Wno-format-truncation -I third_party)
SRC=(src/*.c)
mkdir -p build

[ -f src/font_atlas.h ] || python3 -I tools/mkfont.py '/usr/share/fonts/google-noto-vf/NotoSansMono[wght].ttf' src/font_atlas.h

echo "== desktop (x86_64, host glibc)"
gcc "${CFLAGS[@]}" "${SRC[@]}" -o build/probe-x86_64 -lpthread -ldl -lm
[ "${1:-}" = desktop ] && exit 0

echo "== device (aarch64, glibc 2.30 baseline = ArkOS Ubuntu 19.10; Cortex-A35 tuning)"
"$ZIG" cc -target aarch64-linux-gnu.2.30 -mcpu=cortex_a35 "${CFLAGS[@]}" "${SRC[@]}" \
    -o build/probe-aarch64 -lpthread -ldl -lm
readelf -V build/probe-aarch64 | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1 | sed 's/^/   highest glibc symbol: /'

echo "== package"
rm -rf dist
P=dist/ports
mkdir -p "$P/gameguyprobe/licenses"
cp build/probe-aarch64 "$P/gameguyprobe/"
cp port/GameguyProbe.sh port/GameguyProbe-LongStress.sh port/GameguyUSBDiskMode.sh port/GameguySetupEMMC.sh port/GameguyUSBNet.sh port/GameguyDumpEMMC.sh "$P/"
cp port/README.txt "$P/gameguyprobe/"
cp third_party/licenses/* "$P/gameguyprobe/licenses/"
chmod +x "$P"/*.sh "$P/gameguyprobe/probe-aarch64"
(cd dist && tar -czf gameguyprobe-port.tar.gz ports)
find dist -type f | sort
