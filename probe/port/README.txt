gameguy hardware probe
======================

What it is: a self-contained native program that measures what this handheld can actually do,
so the game can be designed against real numbers. It changes nothing on the device: it only writes
into gameguyprobe/results/ (plus a 64 MB scratch file that it deletes again).

Install: copy the Gameguy*.sh launchers and the gameguyprobe/ folder into the "ports" folder that
EmulationStation reads (on ArkOS-family firmware: /roms/ports, i.e. the "ports" folder on the
EASYROMS partition). Restart EmulationStation (Start > Quit > Restart EmulationStation) if "Ports"
does not list them. Golden image v2 already has them; over USB: probe/tools/r36s.sh push.

Run "GameguyProbe" from Ports. About 5 minutes:
  system info -> CPU/memory/synth -> storage -> GPU -> display -> audio (soft chords) ->
  controls (interactive: follow the prompts) -> 60 s stability test -> Vulkan -> results screen.
Hold SELECT+START at any point to skip the remaining tests (the results so far are saved).

Results: gameguyprobe/results/probe-<unit>-<date>.txt (main log), telemetry-*.csv (clocks and
temperatures every 0.25 s), console-*.log, root-extras-*.txt, dmesg-after-*.txt.
The <unit> code is derived from the internal eMMC, so the two handhelds get different codes.

GameguyProbe-LongStress: same probe with a 10-minute stability phase and no controls test.
Use it after changing CPU/GPU/RAM clocks; keep a setting only if it reports PASS.

GameguyUSBNet: makes the handheld a USB network adapter for the laptop (OTG port, right side);
run once from Ports on golden image v2, afterwards it starts at boot. Laptop side:
probe/tools/r36s.sh (list / ssh / push / pull / run).

GameguyLinkTest: links two handhelds with one USB-C to USB-C data cable (right port to right port)
and measures the link. Run it on a unit whose device tree has the USB controller in dual-role mode
(the black, since 2026-11-13); the other unit needs nothing but to be switched on. The screen says
what to plug and unplug. Results: gameguylinktest/link-<time>.log. It puts the unit back into
device mode at the end.

GameguyDumpEMMC: backs up the internal eMMC to the SD card it sits on (1 GiB pieces + checksums).

GameguySetupEMMC: run from an SD-card system to set up the eMMC system: copies these Ports over and
patches its device tree so the OTG port works as a USB device (--restore puts the original back).
How golden image v2 was made; not needed on units that already run it.

GameguyUSBDiskMode (experimental, untested): asks U-Boot for USB mass-storage mode on reboot.

Licenses: Noto Sans Mono font (SIL OFL 1.1); SDL2, Khronos and Vulkan headers used at build time
(see licenses/).
