# Walkthrough: probe both handhelds, move them to ArkOS4Clone on eMMC, open the OTG port

> **Status 2026-11-12: done.** Both units run golden image v2 from eMMC with USB networking. The
> procedures below are the historical plan; the current processes are:
> - back up a unit: Ports → GameguyDumpEMMC (to an SD card), then copy the pieces to the laptop;
> - reflash a unit: off → hold VOL+ → power on (good USB-C data cable, right port), then
>   `probe/tools/flash-emmc-usb.sh .tools/images/r36s-arkos4clone-gameguy-v2.img [--parts 1,3]`;
> - talk to a unit: `probe/tools/r36s.sh list | ssh | push | pull | run | run-detached`.
> See `docs/fable-handoff.md` and brainstorm §28–§31.

Written 2026-11-12. Each part says what you do and what Claude does, then lists the things that can
go wrong and what to do about each. Parts A–D are the plan; Part E is optional tuning.

**Ground rules (apply throughout)**
- Original cards (black's 58 GB game card, purple's 115 GB card, JJ's 119 GB backup) never get
  flashed. Part A only *adds* a folder to the black's game card.
- Only the two spare **32 GB** cards get flashed. The flash script refuses anything that isn't 28–34 GB.
- Pull power the safe way: if a unit is frozen, hold the power button ~10 s; if that fails, use the
  board's battery connector (both units are already open-able). A dead power button is a state, not a
  diagnosis (§20 lesson).
- OTG cable = **USB-A on the laptop → USB-C on the handheld's RIGHT port (OTG)**. The left port (DC)
  is charge-only. Optional insurance for the OTG steps: an inline USB power meter (watch that current
  only flows *into* the handheld) or a VBUS-blocker adapter — the handheld's OTG 5 V is always on.

---

## Part A — Baseline probe on the black unit's stock firmware (no flashing, zero risk)

Why first: proves the probe runs on real hardware before anything changes, and records the stock
clocks (DDR 528 MHz) to compare against ArkOS4Clone later.

1. **You:** put the black unit's game card (58 GB, from TF2-GAME) into the laptop reader; tell Claude.
2. **Claude:** mounts it and copies `GameguyProbe.sh`, `GameguyProbe-LongStress.sh`,
   `GameguyUSBDiskMode.sh` and `gameguyprobe/` into its `ports/` folder (next to `ecwolf`), then unmounts.
3. **You:** card back into the black's **TF2-GAME** slot (left). Power on → EmulationStation →
   **Ports** → **GameguyProbe**. About 5 minutes:
   - soft chords during the audio test (that's intended),
   - the **controls test** asks you to keep hands off for 2 s, then push LEFT stick up, LEFT right,
     RIGHT up, RIGHT right, then press every button and click both sticks (hold any 3 buttons for
     2 s to finish early),
   - a 60 s stability test (all cores + RAM + GPU flat out),
   - ends on a green "PROBE COMPLETE" screen; take a photo of it, then press any button.
4. **You:** power off, card back into the laptop; tell Claude. **Claude** reads `gameguyprobe/results/`.

What may happen:
- *GameguyProbe isn't listed under Ports* → Start → Quit → Restart EmulationStation. Still missing:
  the stock firmware may read ports from a different place; Claude checks the card's layout.
- *Screen flickers back to the menu within seconds* → the probe didn't start; the reason is in
  `results/console-*.log` — Claude reads it and rebuilds.
- *It freezes mid-test* → wait 60 s (a watchdog exits hung tests), else hold power 10 s. The log is
  written line by line, so everything up to the freeze is kept; the last `# begin` line names the culprit.
- *No sound* → fine for now; the log records which audio paths opened.

## Part B — Make the ArkOS4Clone install card (laptop)

Firmware is already downloaded and verified: `.tools/firmware/dArkOS4Clone-20261008.img` (12.4 GB).
dArkOS4Clone (Debian) is the variant with "Install to eMMC".

1. **You:** put spare 32 GB card #1 in the reader. Tell Claude; **Claude** confirms its device name
   (e.g. `/dev/mmcblk0`) from `lsblk`.
2. **You (in your own terminal, needs your sudo password):**
   `~/Projects/gameguy/probe/tools/flash-card.sh /dev/mmcblk0` — type the device name to confirm.
   It writes (~5–10 min), then reads the card back to verify (`VERIFY OK`).
3. **Claude:** mounts the card's BOOT partition and runs `probe/tools/select-console.sh` →
   profile **Clone R36S › Type 1 Panel 1 With Amplifier**, battery driver **arkos4clone_fix**, no
   overclock (defaults CPU 1296 / GPU 520 / DDR 666). Unmounts.

Why that profile: its panel init sequence is byte-identical to the stock DTB's, and it is the only
candidate driving the speaker amplifier on the same pin (GPIO3_A7) as the stock firmware (§28.2).

What may happen:
- *VERIFY FAILED* → bad/fake card; use card #2 (and tell Claude, it'll test card #1's real capacity).
- *Card shows a different size / device name* → stop; Claude re-checks before anything is written.

## Part C — Purple unit (JJ's): boot, check, probe, install to eMMC, try the OTG port

1. **First boot:** card into the purple's **TF1-OS** (right) slot, power on. The first boot expands the
   card and unpacks files; it shows progress text and **reboots by itself**. Give it up to ~15 min.
   Don't power off during this.
2. **Check:** image is correct (not shifted/garbled), buttons work in menus, sound from the speaker
   (Start → Sound settings, or any menu sound), volume buttons work.
3. **Power off → card into laptop → Claude copies the probe into `EASYROMS/ports` → card back → run
   GameguyProbe** (same as Part A, step 3). Then card back to Claude for results.
   This run answers: GPU driver features (pixel local storage, framebuffer fetch), DDR 666 vs 528 gain,
   whether either stick is inverted, audio latency, stability at default clocks.
4. **Install to eMMC:** Options/Settings → **Advanced** (or Tools) → **Install to eMMC**.
   - The first time it may say the eMMC isn't enabled and offer to **enable it and reboot** → press A.
     After the reboot, run Install to eMMC again.
   - When it asks to copy, press **X** to back up the eMMC first (stored on the card as
     `/roms/backup/emmc-backup.img`), then it continues. Press A only if you're declining the backup.
   - Ends with "Done. Power off now?" → A. Remove the card. Power on: it now boots from eMMC.
5. **OTG test (the USB dream, first attempt):** plug the OTG cable laptop ↔ purple's right port.
   On the purple: Ports → **GameguyUSBDiskMode**. Tell Claude; within ~20 s the eMMC should appear
   on the laptop as a USB disk. Claude copies results/probe in or out, ejects, and you unplug → the
   unit continues booting normally.

What may happen:
- *Black or garbled screen at first boot* → wrong panel profile (unexpected given the identical init
  sequence). Power off; Claude switches the card to plain "Type 1 Panel 1" or another candidate.
- *No speaker sound, headphones fine* → Claude switches to the non-amp profile.
- *Probe says a stick is INVERTED* → Claude switches to the matching "invert" profile.
- *"Install to eMMC" says the eMMC is too small* → it refuses safely; nothing was changed. We keep
  booting from SD on that unit (purple's TF1 works).
- *"U-Boot on this card cannot boot from eMMC"* → the card needs the online/offline update first;
  Claude prepares the offline update files (ArkOS4Clone-updates, 20261005+).
- *After install, unit doesn't boot without the card* → put the install card back (it still boots
  from SD) → Advanced → **Restore eMMC** puts the backup back; then we investigate.
- *USB disk never appears* → unplug; the unit boots normally. Claude checks `lsusb`/`dmesg` on the
  laptop for a 2207:xxxx device; fallback for file transfer stays the card reader.

## Part D — Black unit (yours): one taped session, then never TF1 again

1. **Optional zero-risk OTG experiment first:** with the black powered off and plugged into the laptop
   by the OTG cable, hold **VOL+** and power on. If its stock bootloader has rockusb, a Rockchip
   device (2207:xxxx) appears on the laptop — Claude checks. Either way, unplug and power off.
2. **Flash spare card #2** exactly like Part B (or reuse card #1 after Part C — Claude will say which).
3. **Tape:** insert card #2 into the black's TF1-OS slot and hold it fully in with a strip of painter's
   tape (or kapton) across the slot so the spring can't push it out. Check it's seated: it should sit
   as deep as a latched card.
4. **First boot** as in Part C step 1 (self-reboot, up to ~15 min). If it boots the *old* stock system
   instead, the card isn't seated or the stock bootloader wins — see below.
5. **Install to eMMC** as in Part C step 4 — **press X for the backup** (the black's stock eMMC
   system goes to the card; Claude then copies it to the laptop for safekeeping).
6. Power off, remove the tape and card. Power on: ArkOS4Clone from eMMC; the TF2 game card keeps
   working for games.
7. Probe the black: via GameguyUSBDiskMode (OTG) if Part C step 5 worked, otherwise via its TF2 card.

What may happen:
- *Card pops out mid-boot or mid-install* → power off, re-tape, start that step again. An interrupted
  install leaves the eMMC unbootable but the card still boots; rerun Install, or Restore eMMC.
- *It boots the stock system even with the card taped in* → the stock eMMC bootloader is taking
  priority on this unit. Stop; don't force anything. Options then: rockusb/maskrom flashing over OTG
  (Claude prepares `rkdeveloptool` + the RK3326 loader), or repairing the slot.

## Part E — Optional: clock tuning (only after both units run ArkOS4Clone)

The profile already raises DDR from 528 to 666 MHz. Higher CPU/GPU/DDR settings exist (up to
1608 / 650 / 1040 MHz) and are written into `boot.ini` (Claude edits it over USB disk mode or the
card). Procedure per step: change one clock → run **GameguyProbe-LongStress** (10 min) → keep it only
on **PASS** with no freeze → repeat on the other unit (they may differ). Revert = restore the previous
`boot.ini` line. The probe's telemetry CSV shows temperatures and whether clocks throttle.
