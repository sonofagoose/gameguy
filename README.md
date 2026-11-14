# gameguy

An original game for two R36S-clone handhelds (Rockchip RK3326, 640×480), designed for this exact
hardware. The game itself does not exist yet; this repository holds what it will be built on.

Start here:

| file | what |
|---|---|
| `r36s-game-brainstorm.md` | the creative brainstorm, Morgan's material, and Part 0: how the Fable sessions run |
| `docs/hardware-target.md` | measured hardware numbers to design against |
| `docs/fable-handoff.md` | the platform, how to build for it, the laptop ↔ handheld deploy loop, verification |
| `docs/walkthrough-probe-and-flash.md` | history of how both units were set up (2026-11-11/12) |
| `probe/` | the hardware probe (a measuring instrument; `probe/results/` has every run) |
| `probe/tools/` | `r36s.sh` (talk to the handhelds over USB), `flash-emmc-usb.sh` (reflash), `set-dtb.sh` (change a unit's device tree with automatic undo), card tools |
| `design/` | game design brainstorms (nothing decided): three shapes for the game, the look, memory in rhythm, an imagined ultimate form with seven imagined playthroughs, and listening tests |
| `material/` | Morgan's own writing given to the project as material, verbatim |
| `toys/` | small throwaway programs that test one mechanic on the handheld before the game is designed around it |

Not in git (see `.gitignore`): `.tools/` holds the cross-compiler, the Rockchip loader, the SSH key
for the handhelds, the firmware download, the golden image and the full backups of both units'
original systems.
