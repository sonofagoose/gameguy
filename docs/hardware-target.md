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
| SoC | Rockchip RK3326: 4× Cortex-A35 (NEON), Mali-G31 (Rockchip's sheet says MP2; the driver reports `Mali-G31 1 cores` on every run) |
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
    40 seconds, with no stalled frame. The next section is what was found about those.
- **The TF2 slot only looks for a card at boot.** Its card-detect line read "present" with no
  change recorded since boot, with the slot empty and after a card went in. A card put in while
  the unit runs is not noticed until a restart, or until that slot's controller is unbound and
  bound again (`ff380000.dwmmc` under `/sys/bus/platform/drivers/dwmmc_rockchip/`; never the
  eMMC's, `ff390000`). Nothing mounts a TF2 card by itself: `/etc/fstab` has no entry for it.
- Tools and sessions: `toys/page/tools/` (the watcher, and the test launchers) and
  `toys/page/results/black-20261114/storage-stall/`.

## Clocks left to scale, and the sound thread's priority (measured 2026-11-15)

The menu starts a port through `perfmax` with a governor setting. If that is "ondemand", the CPU,
GPU and memory clocks scale themselves; `r36s.sh run` always pins all three at full speed. Which
one the menu passes on this image is recorded from now on at the top of each toy's console log.

| the page toy, scripted, in the place view | frames | sound |
|---|---|---|
| clocks at full speed, sound thread at ordinary priority (nice -19), 427 s | 17.10 ms each, 3 late in 24,970 | no gaps (longest wait 3.1 ms) |
| clocks scaling, ordinary priority, 290 s | 22 to 30 ms each: about two thirds of the frame rate | **10 gaps of 7 to 15 ms**, about one every 32 s |
| clocks scaling, sound thread at real-time priority, 158 s | 28.3 ms each | **no gaps** (longest wait 3.4 ms) |
| the launcher as it is now, started on scaling clocks, 73 s | 17.10 ms each, 2 late in 4,270 | no gaps (longest wait 3.0 ms) |

- **Scaling clocks starve this kind of program.** The GPU sat at its slowest (200 MHz) for the
  whole session and the CPU at 600 to 816 MHz. The scaling never saw enough load to speed up, and
  the toy missed about every other frame.
- **The gaps come at a steady 30 seconds or so.** They were not memory-clock changes (there were
  none), and only some lined up with a storage burst. What they are is not settled. Real-time
  priority removes them.
- **The synth is not the cause.** Its slowest fill of a 2.67 ms buffer was 0.87 ms at full speed
  and 1.9 ms on scaling clocks.
- **In every launcher now:** the three clocks are pinned at full speed (`performance`), and the
  real-time limit is raised (`prlimit --rtprio=40:40`) so that the toy's sound thread can ask for
  real-time priority (`SCHED_FIFO`, 30). The wheel and page toys ask.
- **Still to confirm by hand.** The session played from the menu on 2026-11-14, before these
  changes, had 11 gaps of up to 15 ms at the same rhythm, with its frames on time. Each gap is now
  logged with its time, so the next session played from the menu will show whether they are gone.
- Sessions: `toys/page/results/black-20261115/sound-gaps/`. Tools: `toys/page/tools/`.

## The game card in the TF2 slot (measured 2026-11-17)

Both units now have a 32 GB SDHC card (`SD32G`) in TF2, erased, with one exFAT partition named
GAMEGUY. Measured on the purple with the card fresh:

| | |
|---|---|
| the card's mode | SDR104, the fastest SD mode; the controller is `ff380000.dwmmc`, interrupt 21 |
| finding it again (unbind and bind that controller only) | 0.93 s |
| checking it (`fsck.exfat -n`) | 0.26 s |
| mounting it, unmounting it | 0.40 s, 0.25 s |
| writing 64 MB and pushing it out | 31.1 MB/s, 52 interrupts per 256 KB |
| reading 64 MB, past the cache | 42.7 MB/s, under one interrupt per 256 KB |
| 4 KB appended and pushed out (`fsync`), 200 times | 1.6 ms typical, 4.4 ms for nine in ten, 48.5 ms for one in a hundred |
| a 64 KB save: new file, pushed out, renamed over the old, folder pushed out | 9.5 ms typical, 13.3 ms worst |

- **The slot only looks for a card at start-up.** A card put in later is not seen until a restart,
  or until the slot's controller is unbound and bound again. The page toy's launcher does that
  when it finds no card, and only if nothing in the slot is mounted and the system does not live
  on it.
- **Nothing mounts the card by itself.** `/etc/fstab` has no entry for it. ArkOS's own "Switch to
  SD2 for Roms" would add one and move the whole menu to the card; it is not used.
- The page toy's book wrote a 76.5 s recording (7.3 MB) to the card during a session with no sound
  gaps and 2 frames one frame late (`design/the-card.md`).

## Render passes cost a fixed amount (measured 2026-11-17)

The page toy's beam light keeps a fading copy of the picture (a phosphor). Its first version
(full-size copy in half floats, then three blur passes on a sixteenth-size copy for a halo) took
the toy's work from 1.46 ms to 7.31 ms a frame on the purple, with 216 frames late in 4,270.

- Moving the copy to half size brought it to 4.64 ms and 11 late.
- Dropping only the three small blur passes brought it to 2.83 ms and 1 late. They cover a
  sixteenth of the screen, but each pass costs this GPU a fixed amount.
- As built (half-size copy that bleeds a little each frame for the halo, three passes in all): 3.57
  ms, none late, worst frame 20.4 ms.
- So: keep passes few. A pass is worth its pixels only when there are many of them.

## One take plays out the same on every machine tried (measured 2026-11-17)

`toys/wheel/tools/same-take.zig` runs the wheel toy's rules and sound with no picture. It plays
twenty minutes at a fixed 60 steps a second: the scripted player, plus a seeded scatter of extra
walks, calls and dodges. After every minute it prints a fingerprint of the world, a fingerprint of
the sound, and the loudest sample so far.

- **A correction.** The first version, run in the morning, never built the synth's wavetables: the
  toy calls `engine.init()` and the test didn't. So the sound it fingerprinted was silence, and the
  laptop and the purple agreed on twenty minutes of nothing. The world's fingerprints from that run
  stand, because the world never reads the tables. The fixed version prints the loudest sample on
  every line, so silence can't pass for a match again.
- **The result** of the fixed version, against the laptop's own build:

| build | where it ran | world | sound |
|---|---|---|---|
| Zig, x86_64 Linux | laptop | the reference | the reference |
| Zig, aarch64 Linux | the purple | identical | identical |
| Zig, WebAssembly | laptop, in Node 24 (V8) | identical | identical |
| Zig's C output, compiled by Clang, x86_64 | laptop | identical | identical |
| the same C, Clang, aarch64 | laptop, emulated (qemu) | identical | identical |
| the same C with multiply-add fusion allowed, x86_64 (this laptop's own instructions) | laptop | differs from the first minute | differs |
| the same, aarch64 | laptop, emulated | differs from the first minute, and from the x86_64 build with fusion | differs |
| the same C, GCC 16 | | doesn't compile | |

- **What it covers.** 2,515 events and 57.6 million samples, with the sound reaching 0.946 of full
  scale.
- **Why it holds.** The maths the rules call (`sinf`, `expf`; the page toy also `fmodf` and `tanf`)
  is compiled into the program from Zig's own library: the symbols are local, not glibc's. And Zig
  never fuses a multiply and an add unless asked. Keep both. With fusion allowed (the C builds
  above), the world changes from the first minute, though after twenty minutes it still has the same
  2,515 events: small differences in where things are, which a longer take would grow.
- **Through C.** Zig's C output, compiled by Clang, gives the same world and sound. GCC 16 rejects
  it (it declares thread-local variables twice). Zig's C output also computes a float `@mod` as a -
  floor(a/b) * b, which rounds twice, so it differs from Zig's own `@mod` unless the divisor is a
  power of two. A separate check of two million values found sine, cosine, exp, tanh and atan2
  identical, and float `@mod` not. In the toys' rules float `@mod` only ever divides by a power of
  two (the beat modulo 4), which is exact either way. The one other use, a grain seed modulo 997 in
  the page toy's drawing (`toys/page/src/gfx.zig`), would differ only in the picture.
- **Speed.** With real sound the purple did the twenty minutes in about 3 min 38 s on one core, just
  after booting: about five and a half times faster than real time. The morning's 3 min 16 s was the
  silent run.
- **A trap for tests over ssh.** logind's default `RemoveIPC=yes` deletes the `ark` user's files in
  `/dev/shm` when its last session ends. Keep a test and its output there within one ssh session, or
  put them somewhere else.
- **Not covered.** On the handheld the toys take their time from the display and the sound card:
  `world.step(hands, frame time, sound clock)`. Replaying a toy session would need those two clocks
  for every frame as well. A game that steps at a fixed rate needs only the hands.
  - A simulated twenty-minute day of hands packs to about 0.1 MB, or 0.25 MB with the clocks
    (`design/the-card.md`).
  - The sticks rest at exactly zero (see Controls), so real hands should pack smaller still.

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
- One probe log from the purple (2026-11-12, `probe-9b4d0e-20260413-163420.txt`) recorded its left
  stick turned a quarter: up on the first axis and right on the second. The black's was normal. It
  has not been rechecked by hand; the room (`SPEC.md`, section 21) asks for it.

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

## What else the handheld has (second probe, measured 2026-11-19)

On the purple, over ssh, with the menu running. Raw readings:
`probe/results/purple-darkos4clone-v2/second-probe-20261119.md`.

**The backlight is more than half of the idle draw, and a program can set it.**
`/sys/class/backlight/backlight/brightness`, 0 to 255, PWM at 40 kHz, writable by root.

| level | battery current, menu idle |
|---|---|
| 255 | 388 mA |
| 200 (as found) | 350 mA |
| 120 | 275 mA |
| 60 | 226 mA |
| 20 | 195 mA |
| 1 | 180 mA |

**One core renders about 2,100 overtones.** `game/bench/modes.zig`: two-pole resonators, 128 frames
at a time, pinned to one core. "Fit" is how many render in half a 2.67 ms buffer, 99 buffers in 100.

| clock | how | each overtone-sample | fit |
|---|---|---|---|
| 1248 MHz | one at a time | 12.1 ns | about 840 |
| 1248 MHz | four abreast (NEON) | 3.8 ns | 2,530 to 2,690 |
| 1008 MHz, the purple's clock under sustained load | four abreast | 4.7 ns | 2,100 to 2,180 |

- The slowest buffer was within 20% of the mean.
- The sound is the same to the last bit on the laptop and the purple, four abreast or one at a
  time, with multiplies and adds kept separate.

**A frame holds about 30,000 lines of light.** `game/src/main.zig --lines`: each line one instance
of a four-cornered strip placed by the vertex shader, black triangles hiding what is behind them,
three passes with the phosphor.

| lines | black triangles | drawn | frames |
|---|---|---|---|
| 19,960 | 5,000 | 8.8 ms | all on time |
| 29,996 | 5,000 | 11.1 ms | all on time |
| 39,932 | 5,000 | 13.2 ms | all on time |
| 59,992 | 5,000 | 18.5 ms | late |
| 29,996 | 20,000 | 13.3 ms | all on time |

- About 4.4 ms for the three passes and 0.22 ms for each thousand lines.
- Six corners to a line instead of four cost 40% more.

**The rest:**

- **There is no rumble motor** (Morgan, 2026-11-19). The line can be driven: GPIO 102, through the
  gamepad's force-feedback interface, once the gain is set to full. Nothing is on it.
- **There is no microphone on the board.** The recording path opens (`hw:0,0`, 48,000 Hz) and one
  channel is a live input with nothing on it. Whether the jack carries a headset's microphone to it
  is not known.
- **The clock does not count while the unit is off.** The system clock was 38.8 hours behind after
  being off; the clock chip had gained 26 hours in a week. The chip accepts a new time, and was set.
- **A unit acting as USB host has drivers for** USB sound, USB MIDI, keyboards and gamepads
  (built into the kernel). Nothing was plugged in.
- **The two lights on the case ignore writes** on this system.
- **The battery gauge's current reading moves in steps a few seconds apart.**

## Not yet measured / caveats

- From the second probe, each needing a person: how the backlight looks when it follows the music;
  the speaker's loudness; the
  purple's left stick; whether the set clock counts while off. Also: button to sound and button to
  picture.

- Overclocking (CPU to 1608, GPU to 650, DDR to 1040 MHz are offered by ArkOS4Clone's DTB tool) is
  untested; every number here is at stock clocks.
- ASTC throughput was measured with constant-colour blocks; real-content ASTC may differ.
- Battery capacity: the label says 3500 mAh; the fuel-gauge profile assumes 2808 mAh; not measured.
