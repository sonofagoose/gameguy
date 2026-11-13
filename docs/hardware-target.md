# Hardware target sheet (measured)

Both handhelds, 2026-11-12, golden image v2 (dArkOS4Clone 20261008 on eMMC). All numbers come from
`probe` runs launched the way the Ports menu launches a game (performance governors, direct ALSA).
Raw logs: `probe/results/black-darkos4clone-v2/`, `probe/results/purple-darkos4clone(-v2)/`.
The two units measure within ~3% of each other on every benchmark below; only sustained full load
separates them (the purple throttles its CPU harder, see Thermal).

## System

| | |
|---|---|
| Board | R36S-V12 2023-08-18 clone (×2, identical) |
| SoC | Rockchip RK3326: 4× Cortex-A35 (NEON), Mali-G31 MP2 |
| Clocks (stock profile) | CPU up to 1296 MHz (1248 typical under load), GPU 520 MHz, DDR 666 MHz |
| RAM visible to Linux | 918 MiB (`MemTotal` 940,428 kB), about 815 MiB available when a game starts (LPDDR3 in a Samsung eMCP) |
| Storage | 7456 MB eMMC; read ~46 MB/s, write ~14–28 MB/s (game data lives in `/roms`, 1 GB exFAT, or on an SD card in TF2) |
| OS | Debian 13, kernel 4.4.189, glibc 2.41, SDL 2.32.10 (KMSDRM), libmali r13p0 |
| Radios | none (no Wi-Fi/Bluetooth) |

## Display

- 3.5" IPS, **640×480**, 4:3, 24-bit colour (RGB888 over 4-lane DSI), ~229 ppi.
- Two modes: **58.46 Hz** (default) and **60.02 Hz**, selectable at runtime
  (`SDL_SetWindowDisplayMode` + `SDL_WINDOW_FULLSCREEN`; measured on both units).
- Vsync-locked and double-buffered: `SDL_GL_SwapWindow` blocks until vsync (~16.8 ms per frame);
  swap interval 0 is ignored. Missing a vsync drops that frame to the next refresh (29.2/30 Hz).

## GPU (OpenGL ES 3.2, GLSL ES 3.20)

| measure | value |
|---|---|
| Blended fill (full-screen layers) | ~925–950 Mpix/s ≈ **50 full-screen layers per 60 Hz frame** |
| Opaque fill (hidden-surface removal) | ~1.55–1.6 Gpix/s |
| Shader ALU | fp32 **7.2 GFLOPS** (~390 flops/pixel/frame at full screen), fp16 **15.8 GFLOPS** (~800) |
| `mediump` | real fp16 (10-bit mantissa, range ±2^15) |
| Texture sampling | RGBA8 1:1 ~530 Mtexel/s; RGBA8 minified ~380; ETC2 ~440; ASTC 4×4 ~180 (test used constant-colour blocks) |
| One full-screen textured layer | ~0.55 ms (same whether it stays in tile memory or round-trips through DRAM) |
| 16 lights, full screen | **single pass with a light loop 7.3 ms**; G-buffer (MRT) deferred 15.7 ms; pixel-local-storage deferred 55.9 ms |
| Framebuffer fetch (ARM) | works, 4× slower than fixed-function blending |
| Draw call (CPU side) | ~12.4 µs plain, ~24 µs with `glBufferSubData`, ~0.7 µs per instance when instanced → ~1300 plain draws per 16.7 ms |
| Texture upload | ~200 MB/s (a 2048² RGBA8 texture takes ~85 ms) |
| Limits | max texture 8192, MSAA up to 16×, 4 draw buffers, 1024 fragment uniform vectors, 15 varyings |
| Extensions of note | ASTC LDR/HDR, ETC2, `EXT_disjoint_timer_query`, `EXT_shader_pixel_local_storage` (16 B), `ARM_shader_framebuffer_fetch`, multisampled-render-to-texture |
| Vulkan | no GPU driver (only Mesa software/other-vendor ICDs) |

**A real shader, not a benchmark (remainder toy on the black unit, 2026-11-12,
`toys/remainder/results/black-20261112/`):** one full-screen fragment shader summing four wave
sources (per source: an inverse square root, a short dynamic loop, two polynomial sines, with the
phase in `highp`) plus shading and grain cost **24.5 ms at 640×480 and 7.3 ms at 320×240**. The
ALU figure above is a ceiling for straight-line `mediump` arithmetic; `highp`, loops and
per-pixel distance math land far below it. Plan full-screen procedural effects at half
resolution or cheaper, and spend the full-resolution budget on textured layers.

## CPU and memory

| measure | value |
|---|---|
| NEON fp32 FMA | ~1.5 GFLOPS per core, ~5.8 across 4 cores |
| Synth voices per core @48 kHz (plain C, scalar) | sine ~1080, Karplus-Strong ~1030, polyBLEP saw + SVF ~800 |
| RAM bandwidth | read 2.3 GB/s (1 core), 3.4–3.8 GB/s (all cores); write ~4.8 GB/s |
| Latency | L1 2.4 ns; ≤128 KB 13.5 ns; DRAM ~155–195 ns (the L2 is small: keep hot data compact) |

## Audio

- RK817 codec, ALSA, 48 kHz. Under the Ports launch environment the default device runs steady
  **128-frame buffers (2.67 ms)**, F32 stereo; `hw:0,0` directly also 128 frames (S32).
  (Outside that environment `~/.asoundrc` routes through dmix with 1024-frame periods ≈ 23 ms; the
  menu's `perfmax`, and `r36s.sh run`, move it aside.)
- Under a real load (the remainder toy: 13 wavetable voices, a 7 ms GPU frame, 58.5 Hz), the
  128-frame buffer held: 1 late callback in 104,129 (worst gap 5.7 ms) over 68 s.
- One mono speaker (works on the "Type 1 Panel 1" profile) and a stereo 3.5 mm headphone jack with
  plug detection.

## Controls

- SDL sees one joystick, **"GO-Super Gamepad"**: **4 analog axes** (full range ±32767, zero
  resting noise thanks to a driver deadzone, SDL-normal directions on both sticks) and
  **17 buttons**: D-pad, A/B/X/Y, L1/R1, **L2/R2 (digital buttons, mapped to the trigger axes)**,
  Select, Start, **FN** (mapped as `guide`), **L3/R3 (stick clicks)**. Volume up/down are separate
  and handled by the system.
- The `SDL_GameController` mapping comes from PortMaster's controller database: a Ports launcher
  that sources `control.txt` and runs `get_controls` gets it in `SDL_GAMECONTROLLERCONFIG`
  (see `probe/port/GameguyProbe.sh`). SDL's controller buttons are *positional* (`A` = bottom face
  button), while the handheld's printed labels follow the Nintendo layout; check which physical
  button a prompt refers to.
- Stick values change at most ~56–58 times per second (the driver polls the ADC at ~60 Hz);
  buttons are GPIO-driven.

## Thermal and power (10 min, all cores + RAM + GPU at full load, unplugged)

Both units: **zero** CPU, RAM or GPU errors (`GameguyProbe-LongStress`, 2026-11-12).

| | black | purple |
|---|---|---|
| peak SoC temperature | 81.5 °C | 83.5 °C (reached within the first minute) |
| settles at | ~78 °C | ~78 °C |
| CPU clock after 2 min | 1248 MHz 50% of the time, 1200 30%, 1008 19% (average ~1190) | **1008 MHz 82%** of the time, briefly 816 (average ~1010 in the last 3 min) |
| GPU clock after 2 min | 520 MHz 65%, 480 25%, 400 9% (average ~495) | 520 MHz 86% (average ~505) |
| DDR | 666 MHz throughout | 666 MHz throughout |
| work done in 10 min | reference | CPU −10%, GPU −5% |
| battery current | ~770–820 mA | ~770–850 mA |
| battery used | 5% (70 → 65) | 5% (94 → 89) |

- The kernel's thermal governor holds the SoC near 78 °C by trading CPU against GPU clocks; the
  purple gives up more CPU. **Design against the purple:** under sustained full load of every
  core plus the GPU, plan on CPU ~1000 MHz (20% below peak) and GPU mostly at 520 MHz. A game that
  leaves cores idle runs cooler and keeps higher clocks (not measured separately).
- ~800 mA at full load is about 5% battery per 10 min (~3 h from full at maximum load); lighter
  loads last longer.

### Charging

- Charging only through the **left** (DC) USB-C port; the data cable on the right port does not
  charge.
- Charger settings in the device tree (RK817 charger, golden image v2): input limit **1.5 A**,
  minimum input voltage 4.5 V, charge to **4.2 V** at up to 2 A, stops at 300 mA. The handheld
  takes only 5 V: the device tree has no USB-C/PD controller, so it cannot ask for more, and a
  "fast" (PD/Quick Charge) charger stays at its 5 V default; the handheld draws at most 1.5 A.
- Observed: some chargers charge the units and others don't. Likely cause (not verified on the
  board): the DC port lacks the 5.1 kΩ CC pull-down resistors, and USB-C-to-C chargers only switch
  on 5 V when they see them. A USB-A charger with an A-to-C cable always supplies 5 V.

## Not yet measured / caveats

- Overclocking (CPU to 1608, GPU to 650, DDR to 1040 MHz are offered by ArkOS4Clone's DTB tool) is
  untested; every number here is at stock clocks.
- ASTC throughput was measured with constant-colour blocks; real-content ASTC may differ.
- Battery capacity: the label says 3500 mAh; the fuel-gauge profile assumes 2808 mAh; not measured.
