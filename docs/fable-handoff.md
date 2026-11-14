# Fable handoff: the platform, the tools, the loop

Status 2026-11-12. This document gives you what has been **measured** and what has been
**proven to work**. It deliberately contains no game design and no game code: the game, its
architecture and its engine choice are yours (with Morgan) to decide. The creative brief and the
session protocol live in `r36s-game-brainstorm.md`, Part 0. Hardware numbers are in
`docs/hardware-target.md`.

## The two devices

Two R36S clones (board R36S-V12 2023-08-18), hardware-identical, both running the **same system
image** ("golden v2"): dArkOS4Clone 20261008 (Debian 13, kernel 4.4.189, Mali-G31 libmali r13p0,
SDL 2.32.10 KMSDRM) installed on the internal eMMC. No SD card is needed to run.

| unit | owner | USB network address |
|---|---|---|
| black | Morgan | unit 134 → 10.36.134.1 |
| purple | JJ | unit 164 → 10.36.164.1 |

Games launch from EmulationStation's **Ports** menu: a `.sh` launcher in `/roms/ports/` plus a
folder of files next to it. That is the delivery format.

## The loop (laptop ↔ handheld over the USB-C data cable)

Cable: the **good** USB-C data cable, laptop USB-A → handheld **right** port (OTG). A bad cable was
the cause of every USB failure on 2026-11-11; if nothing enumerates, suspect the cable first.

The handheld appears as a USB Ethernet adapter as soon as it boots (`gameguy-usbnet` and
`gameguy-dhcp` system services, installed by running Ports → GameguyUSBNet once). The laptop gets
10.36.N.2 by DHCP; if DHCP ever fails, `r36s.sh` falls back to the unit's IPv6 link-local address.
The same port can also link the two handhelds to each other with a USB-C to USB-C data cable
(tested 2026-11-13; see "Two units on one USB-C cable" in the hardware sheet, and Ports →
GameguyLinkTest). For that the black's device tree was changed with `probe/tools/set-dtb.sh`,
which undoes a device-tree change by itself if the unit doesn't come back on this link.
The data cable does **not** charge the handheld: for long sessions also plug a charger into the
**left** (DC) port (a USB-A charger with an A-to-C cable is the dependable choice; some USB-C
chargers don't power these units, see the hardware sheet). From the repo root:

```
probe/tools/r36s.sh list                          # connected units
probe/tools/r36s.sh ssh [N] [cmd]                 # shell/command (user ark, passwordless sudo)
probe/tools/r36s.sh push [N] LOCAL /roms/ports/   # deploy files (rsync)
probe/tools/r36s.sh pull [N] REMOTE LOCAL         # fetch logs, screenshots, results
probe/tools/r36s.sh run [N] /roms/ports/X.sh [args]   # stop EmulationStation, run X on the
                                                  # handheld's screen, restart EmulationStation
probe/tools/r36s.sh run-detached [N] /roms/ports/X.sh  # same, keeps running if the cable is pulled
```

`run` reproduces the Ports menu's launch environment exactly (`sudo perfmax …; nice -n -19 %ROM%;
sudo perfnorm`): CPU/GPU/DDR governors set to `performance` and `~/.asoundrc` (dmix, ~23 ms
periods) moved aside so ALSA runs 128-frame buffers; both restored afterwards, also on failure.
Measurements taken without this environment run ~2.5× slower and with 23 ms audio.

A program started this way owns the display (KMSDRM), audio (ALSA) and controls exactly as when
launched from the menu. Anything it prints or writes can be pulled back. `ark` has passwordless
sudo.

The units' clocks are not set (no network time; they read April 2026, which is why the probe
results carry that date). Don't trust device timestamps; `r36s.sh ssh N 'sudo date -s @'$(date +%s)`
sets the clock from the laptop.

## Building for the device (what is set up and proven)

- **Cross-compiler:** Zig 0.17.1 at `.tools/zig/zig` (git-ignored; re-download from ziglang.org if
  missing). Proven invocation for this target:
  `zig cc -target aarch64-linux-gnu.2.30 -mcpu=cortex_a35 …` (glibc ≥2.30 floor covers both
  ArkOS-Ubuntu and dArkOS-Debian userlands; the device has glibc 2.41).
- **Libraries on the device** (link dynamically or `dlopen`): SDL2 2.32.10 (KMSDRM video,
  ALSA/Pulse audio, game controller DB), libmali (EGL 1.4, OpenGL ES 3.2, OpenCL 2.0; no Mali
  Vulkan driver: only Mesa's software/other-vendor ICDs are installed), libasound, glibc 2.41.
  PortMaster 2026.09.13 is installed, but its runtimes (Godot FRT, LÖVE, Mono…) are **not** on the
  eMMC (the eMMC install skipped the `.squashfs` runtimes); a runtime would have to be copied over
  USB first.
- **Reference implementation:** `probe/` is a complete native program built this way
  (C11, SDL2 + GLES3 loaded at runtime with `dlopen`, so the binary needs only glibc). It is a
  measuring instrument, not a template; read it for "how do I get a GL context / audio callback /
  controller on this box", ignore its structure. Build: `probe/build.sh`.
- **Desktop runs:** the same C code builds natively on the laptop (gcc) and runs headless with
  `SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy` (Mesa GLES 3.2 on Intel). Good for logic
  tests, screenshots and smoke runs; not for performance (the laptop GPU is ~10× faster).
- **Static shader cost** (optional): Arm Mali Offline Compiler supports Mali-G31 if installed.

Other engines (Godot 3 FRT, LÖVE, raylib) run through PortMaster runtimes (copy the runtime over
first, see above); their reported trade-offs are in brainstorm §27.5/§30. Godot 4 runs only under Weston and
is not recommended on RK3326.

## Verifying a build

1. Desktop: builds and runs headless; unit tests pass; frame dumps look right.
2. Device: `r36s.sh push` + `r36s.sh run`; the program logs frame times, audio underruns and
   errors to a file; `r36s.sh pull` brings logs (and any frames the program saved) back.
3. Human: Morgan plays it. Things only a person can judge (feel, sound through the speaker,
   readability on a 3.5" screen) are judged on the device, not on the laptop.

## Safety net (already in place)

- Full verified images of both units' original systems and of the golden image live in
  `.tools/backups/` and `.tools/images/`.
- Back up a unit on-device: Ports → `GameguyDumpEMMC` (writes to an SD card).
- Reflash a unit over USB: off → hold VOL+ → power on, then
  `probe/tools/flash-emmc-usb.sh .tools/images/r36s-arkos4clone-gameguy-v2.img`
  (whole image, ~21 min) or add `--parts 1,3` (boot + ROMS partitions only, ~4 min).
- Rockchip's USB download mode only allows **reading** the first 32 MiB; reads of the whole
  storage are done on-device (above).
- Avoid hard power-offs (holding power) while a unit is booting or writing; use the menu.

## Open questions for Morgan (spec interview)

- Engine/language: native C (or Zig/Rust) on SDL2+GLES vs. a PortMaster runtime (Godot 3, LÖVE).
- Target frame rate: 58.5 Hz native vs. 29.25 Hz with more per-frame budget (see hardware sheet).
- Speaker vs. headphones as the primary audio target.
- Whether the game should use FN (works on this firmware) and the stick clicks (L3/R3 exist).
- Two-player: both units together over one laptop, or a direct link (unexplored).
