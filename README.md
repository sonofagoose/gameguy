# gameguy

An original musical game for two R36S-clone handhelds (Rockchip RK3326, 640×480), designed for this
exact hardware. The circle of fifths is the world and the main tool: you are Hum, you hum one note,
and the chord you put under it changes what you are and what the world does.

On 2026-11-26 Morgan, who decides what the game is, said of its design: "this is absolutely 100% the
direction". The build is at the start of that direction: `PROGRESS.md` says what it does today.

Start here:

| file | what |
|---|---|
| `design/the-game.md` | what the game is: the world, the hands, the rules, a day, what grows, the story, what is tested and what is still a bet, and where every piece of the older design now stands |
| `design/the-depths.md` | part two: the third, what is underneath, what moves least, rhythm and the pocket, the great instruments, wonders, endless composition |
| `design/the-wormhole.md` | part three: what the teaching of Jaron Lopez adds; outside the key is a wormhole; melody is the main character |
| `PROGRESS.md` | what the build does today, what is on the handhelds, what is next |
| `CLAUDE.md` | the standing notes for a working session: which source wins, the hardware, the commands, the rules |
| `game/` | the game's code (built to the older specification; see `game/README.md`) |
| `docs/hardware-target.md` | measured hardware numbers to design against |
| `docs/fable-handoff.md` | the platform, how to build for it, the laptop ↔ handheld deploy loop |
| `docs/other-platforms.md` | PC, other consoles and phones: what travels, what doesn't |
| `material/` | Morgan's own writing given to the project as material, verbatim |
| `SCRATCH.md` | a brainstorm with Morgan's answers written inline |
| `design/` (the rest) | earlier brainstorms, kept as history and for their detail. Each says at its top what of it the direction keeps |
| `SPEC.md`, `spec/`, `DECISIONS.md` | the specification of 2026-11-19 and its annexes and decisions, retired as a frame on 2026-11-25 and kept as history. Each says at its top what of it the direction keeps |
| `r36s-game-brainstorm.md` | the first brainstorm: Morgan's favourite games, his poem (Appendix A), noodles and wasatch, the hardware investigation |
| `docs/walkthrough-probe-and-flash.md` | how both units were set up (2026-11-11/12) |
| `probe/` | the hardware probe (a measuring instrument; `probe/results/` has every run) |
| `probe/tools/` | `r36s.sh` (talk to the handhelds over USB), `flash-emmc-usb.sh` (reflash), `set-dtb.sh` (change a unit's device tree with automatic undo), card tools |
| `toys/` | small programs that each tested one idea on the handheld. They are not the game |

Not in git (see `.gitignore`): `.tools/` holds the cross-compiler, the Rockchip loader, the SSH key
for the handhelds, the firmware download, the golden image and the full backups of both units'
original systems.
