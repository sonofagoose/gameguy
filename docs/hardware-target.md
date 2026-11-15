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

**A 3D scene (meadow toy on the black unit, 2026-11-14, `toys/meadow/results/black-20261114/`):**
a patch of meadow with lit ground, stones, plants, a tree and 143,664 blades of grass.

| view | GPU time for the whole picture | triangles, draw calls |
|---|---|---|
| down in the grass | 8.2 ms | 62,848 in 68 |
| gliding above it | 11.9 ms | 93,747 in 100 |
| in play (standing still) | every frame on time: 17.09 ms each, worst 17.57, none late in 1,470 | 76,361 in 87; 2.3 ms of CPU for game and draw calls |

- Small triangles go through at about **10.9 million a second** (1.92 million took 175 ms).
- Grass twice as dense costs 13.4 ms in the grass and 19.4 ms above it; four times, 24.5 and 34.1.
- Resolution hardly matters for this scene: at 75% it costs 7.7 and 11.5 ms, at 50% 6.8 and
  10.3. The cost is in the number of triangles, not the number of pixels.
- So a 3D world of 60,000 to 90,000 triangles a frame fits at full resolution and full frame rate.

**Lines of light in 3D (page toy on the black unit, 2026-11-14,
`toys/page/results/black-20261114/`):** up to 1,406 blended quads a frame, every point projected
on the CPU, one draw call. 17.10 ms a frame, worst 20.3, none late in 4,270, with 1.3 ms of CPU
for the game, the projection and the draw call. Drawing the garden as a page (from above) or as
a place (from behind the creature) costs the same.

## Storage activity stalls frames (measured 2026-11-14)

**Reading or writing the built-in storage (the eMMC, where the system and `/roms` live) can freeze
the picture for up to a quarter of a second and drop the sound for up to 84 ms**, whoever does it:
the game, or the system in the background.

- **What happens.** The eMMC's controller (`dw-mci` at `ff390000`, interrupt 22) raises 1,100 to
  5,000 interrupts for every 256 KB it moves: about **70,000 a second** while it works, with as
  many tasklets and about 145,000 context switches a second. They land on core 0, which is also
  the core that serves the GPU's interrupts and the display's. Frames stop arriving until the
  burst ends.
- **How it was found.** Every toy had 3 to 10 late frames a session, 150 to 315 ms each. Each one
  lined up with a burst on that interrupt, to within the 50 ms the watcher sampled at. Keeping
  the toy's own logs in memory did not remove them (the system writes too), and no CPU, GPU or
  DDR clock change happened during a run.
- **The tests.** The same scripted session, with 256 KB moved every two seconds:

| every two seconds, 256 KB was | as the device comes | storage interrupts on core 3, the toy on cores 0 to 2 |
|---|---|---|
| written to the built-in storage (35 and 34 times in 4,270 frames) | 15 late frames, the worst 243 ms | **none late, the worst 18.0 ms**; one audio gap of 12 ms |
| read from the built-in storage (19 times in 2,570 frames) | 4 stalled frames, the worst 228 ms; 7 audio gaps, the worst 84 ms | none stalled, the worst 29 ms; no audio gaps |
| read from an SD card in the TF2 slot (19 times in 2,570 frames) | 1 stalled frame of 87 ms; 2 audio gaps, the worst 77 ms | none stalled, the worst 29 ms; one audio gap of 8 ms |
| written to an SD card in the TF2 slot (20 times in 2,570 frames) | one stall of two frames (86 and 162 ms); no audio gaps | none stalled, the worst 20.1 ms; one audio gap of 8 ms |

- **A card in the TF2 slot is far lighter than the built-in storage.** Its controller
  (`ff380000`, interrupt 21) raised **12 interrupts for each 256 KB read** and **410 to 460 for
  each 256 KB written and pushed out**, against 1,100 to 5,000 for the built-in storage either
  way. The card (a 32 GB SDHC, exFAT) ran in its fastest mode, SDR104.
  - The stalled frame in the card's read session fell between two reads, while the built-in
    storage raised 22,000 interrupts of its own in the background; the card raised 228 in all.
  - The stall in its write session came 0.15 s after one of the 20 writes finished; the other 19
    caused none. The built-in storage raised 16,500 interrupts in that session too, so which of
    the two caused it is not settled.
- **The cure, in every toy's launcher:** before the program starts, write `3` to
  `/proc/irq/N/smp_affinity_list` for each `dw-mci` interrupt, run the program under
  `taskset -c 0-2`, and put the interrupts back afterwards. It needs `sudo`, which a Ports
  launcher has. With it, full sessions of the wheel and page toys ran with no late frame (worst
  20.5 ms) and no audio gap.
- **What it means for the game.**
  - One core belongs to storage; the game has three.
  - The game's files are better on a card in TF2 than in `/roms` on the built-in storage.
  - Three of the four cured test sessions still had a single audio gap of 8 to 12 ms, and a
    seven-minute session played by hand from the menu had 11 (the worst 15 ms), about one every
    40 seconds, with no stalled frame. Scripted sessions started over the cable had none. So
    storage bursts on core 3 may still delay the sound a little. Not explained yet.
- **The TF2 slot only looks for a card at boot.** Its card-detect line read "present" with no
  change recorded since boot, with the slot empty and after a card went in. A card put in while
  the unit runs is not noticed until a restart, or until that slot's controller is unbound and
  bound again (`ff380000.dwmmc` under `/sys/bus/platform/drivers/dwmmc_rockchip/`; never the
  eMMC's, `ff390000`). Nothing mounts a TF2 card by itself: `/etc/fstab` has no entry for it.
- Tools and sessions: `toys/page/tools/` (the watcher, and the test launchers) and
  `toys/page/results/black-20261114/storage-stall/`.

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

## Two units on one USB-C cable (measured 2026-11-13)

Two handhelds linked right port to right port with a USB-C to USB-C data cable: the black as USB
host, the purple unchanged as a USB device (its normal laptop-link state). The purple appears on
the black as a USB network adapter, high-speed (480 Mbit/s). Log:
`probe/results/black-darkos4clone-v2/linktest/link-20260414-050731.log`.

| test | sent | lost | round trip: min / avg / max (ms) |
|---|---|---|---|
| 32-byte packets, about 83 a second for 36 s | 3,000 | 0 | 0.29 / 0.47 / 6.09 |
| 1,400-byte packets, 200 a second for 10 s | 2,000 | 0 | 0.25 / 0.49 / 3.80 |
| one packet every 0.2 s for 10 s | 50 | 0 | 0.34 / 0.47 / 0.89 |

- One frame is 17.1 ms, so a typical round trip is under 3% of a frame.
- **What the host unit needs:** the device tree's USB controller in dual-role mode
  (`dr_mode = "otg"`). Only the black has this so far (installed with `probe/tools/set-dtb.sh`;
  the golden image v2 tree is kept in its `/boot` as `...dtb.prev-9ccb50bf`). The purple still has
  golden image v2's device-only tree, which is all a guest needs.
- **Switching roles:** write `host` or `peripheral` to
  `/sys/devices/platform/ff2c0000.syscon/ff2c0000.syscon:usb2-phy@100/otg_mode`. `gameguy-usbnet`
  forces `peripheral` at boot, so the laptop link is unchanged.
- **Power for the cable:** in host mode the driver does not switch the port's 5 V on. The test
  switched it on directly (GPIO 100, the `vbus_host` regulator's pin, after unbinding that
  regulator's driver). A game hosting a link has to do the same, and must never do it while a
  computer is plugged into that port. The phy reports a powered cable as `USB=1` in
  `/sys/class/extcon/extcon0/state`; `power_supply/usb/online` reads 0 whenever a charger is on
  the left port, so it can't be used for this.
- **Battery:** the black drew about 397 mA before linking and 376–466 mA (average 413 mA) while
  linked. The purple's charge level during the test is not known.
- **Switching back** to device mode brings the laptop link back without a reboot. Checked three
  ways from host mode with nothing attached, all of which worked
  (`roleswitch-20260414-054209.log`). After the linked session itself the laptop link did not
  come back, because of a bug in the unit's DHCP service that is now fixed; the switch back after
  a linked session has not been re-run since the fix.
- **Don't re-probe or reload the `dwc2` driver** on a running unit: both left the controller
  unable to enter device mode until a reboot (`roleswitch-20260414-053225.log`).
- Not yet tried: the purple as host, a link that stays up for hours, and what happens when the
  cable is pulled mid-session.

## Not yet measured / caveats

- Overclocking (CPU to 1608, GPU to 650, DDR to 1040 MHz are offered by ArkOS4Clone's DTB tool) is
  untested; every number here is at stock clocks.
- ASTC throughput was measured with constant-colour blocks; real-content ASTC may differ.
- Battery capacity: the label says 3500 mAh; the fuel-gauge profile assumes 2808 mAh; not measured.
