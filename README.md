# gameguy

An original musical game for two R36S-clone handhelds (Rockchip RK3326, 640×480), designed for this
exact hardware. Its working title is "Oh. You're in." The game is specified and its build is
starting: `PROGRESS.md` says where it stands.

Start here:

| file | what |
|---|---|
| `SPEC.md` | the specification: the whole game, decided. Where it disagrees with an older document, it wins |
| `spec/` | its annexes: the laws and their numbers, the atlas of lands and wonders, the people, how big it all is and what the card is for, the years, two consoles, the sky, the shape of the lands and what their ground wears, the texture of the world, the engine, the stages and their proofs, and a ledger of every idea from every document |
| `spec/promises.md`, `spec/promises/` | the guard: every sentence of the specification read as a claim, the promises that speak for them, and `BOARD.md`, which says where each one stands today |
| `DECISIONS.md` | every question the documents left open, decided, with the reason |
| `PROGRESS.md` | which stage the build is in, what is proven, what is next |
| `CLAUDE.md` | the short standing notes for a build session |
| `game/` | the game |
| `design/` | the brainstorms the specification was made from, kept as history and for their detail. `the-whole-game.md` gathers them; the rest are three shapes for the game, the look, memory in rhythm, an imagined ultimate form with seven imagined playthroughs, the wheel in the hand, experience fixes, the way home, the page and the place, drawn in light, the card, together, and listening tests |
| `r36s-game-brainstorm.md` | the first brainstorm, Morgan's material, and Part 0: how the Fable sessions run |
| `material/` | Morgan's own writing given to the project as material, verbatim |
| `docs/hardware-target.md` | measured hardware numbers to design against |
| `docs/fable-handoff.md` | the platform, how to build for it, the laptop ↔ handheld deploy loop, verification |
| `docs/other-platforms.md` | PC, other consoles and phones: what travels, what doesn't, and the rules that keep a port possible |
| `docs/walkthrough-probe-and-flash.md` | history of how both units were set up (2026-11-11/12) |
| `probe/` | the hardware probe (a measuring instrument; `probe/results/` has every run) |
| `probe/tools/` | `r36s.sh` (talk to the handhelds over USB), `flash-emmc-usb.sh` (reflash), `set-dtb.sh` (change a unit's device tree with automatic undo), card tools |
| `toys/` | small throwaway programs that each tested one idea on the handheld. They are not the game; the game reuses what they proved |

Not in git (see `.gitignore`): `.tools/` holds the cross-compiler, the Rockchip loader, the SSH key
for the handhelds, the firmware download, the golden image and the full backups of both units'
original systems.
