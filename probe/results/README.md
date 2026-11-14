# Probe results

Every probe run on the two handhelds, as pulled off the devices. One run = one set of files
sharing a timestamp: `probe-<unit>-<time>.txt` (main log, `key = value` lines; the `SUMMARY` block
at the end), `telemetry-<unit>-<time>.csv` (clocks, temperatures, battery every 0.25 s),
`console-*.log`, `root-extras-*.txt`, `dmesg-after-*.txt`.

Timestamps come from the device clocks, which are not set (2023 on the stock firmware, April 2026
on ArkOS4Clone); the real dates are 2026-11-12. `<unit>` is a hash of the eMMC's ID (black
`8ecf62`, purple `9b4d0e`); the v1.1 purple run shows `94430f` because its eMMC was not yet
enabled and the probe fell back to the CPU serial.

| folder | unit, system | probe | runs | notes |
|---|---|---|---|---|
| `black-darkos4clone-v2/` | black, golden image v2 on eMMC | 1.3 | full (60 s stress), benchmarks without stress, **10-min stress** | current numbers |
| `purple-darkos4clone-v2/` | purple, golden image v2 on eMMC | 1.3 | full (60 s stress), **10-min stress** | current numbers |
| `purple-darkos4clone/` | purple, dArkOS4Clone from SD | 1.1 | two (the first cut short) | first corrected GPU timings (brainstorm §30); plus the firmware's first-boot logs |
| `black-stock-emuelec/` | black, stock EmuELEC (as delivered) | 1.0 | four (three cut short) | GPU timings in these are inflated 10–30× (probe bug fixed in 1.1, brainstorm §29–§30); CPU/RAM/system info valid |
| `purple-rockusb/` | purple in Rockchip USB mode | — | — | `rkdeveloptool` device and flash info |

`black-darkos4clone-v2/linktest/` holds the two-unit USB link test of 2026-11-13: `link-*.log`
(the link measured, black as host, purple as guest) and `roleswitch-*.log` (switching the port
from host mode back to device mode; the first run failed because of a DHCP service bug that was
then fixed, the second passed).

The numbers to design against are summarised in `docs/hardware-target.md`.
