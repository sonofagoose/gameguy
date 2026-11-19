# Progress

Where the build stands, so a new session can pick it up. Newest first. The plan is in `SPEC.md`,
section 20, and `spec/stages.md`.

## Now: the planning session's work (2026-11-19)

| piece | state |
|---|---|
| commit and push what was waiting | done (`a52be83`) |
| second probe, the parts that need no hands | done (`probe/results/purple-darkos4clone-v2/second-probe-20261119.md`) |
| `SPEC.md` | done |
| `spec/` (laws, world, people, engine, stages, ideas) | done |
| `DECISIONS.md`, `CLAUDE.md`, the index, the hardware sheet | done |
| the workshop: `game/build.sh` builds both machines, runs with no screen, dumps frames, packs | done |
| the dark and the call: the loop, two laws, the sound bank, the first playable minute | done; runs on the purple with every frame on time |
| the same-take test on the game's own world and sound | done: ten minutes identical on the laptop and the purple |
| lines-a-frame benchmark on the handheld | done: 30,000 lines in 11.1 ms (`game/results/purple-20261119/`) |
| the room: Morgan's hand checks and the 31 listening clips, on the handheld | built and installed on the purple as GameguyRoom; it opens and leaves cleanly. Nobody has answered it yet |
| second probe, the parts that need Morgan's hands | waiting for him to run the room: the tone, the rumble line, the backlight, the left stick, a headset. The clock check needs a power-off and on |

## The guard, the size, the years (2026-11-19)

Morgan asked for something that makes sure every claim is built at full size and felt by a person,
working for every claim by itself; then for the game to be maximal, to use the card, and to go far
past the deepest game he knows.

| piece | state |
|---|---|
| the guard: `spec/tools/promises.py` reads every sentence of the specification as a claim | done: 1,260 claims read; `spec/promises/BOARD.md` and `CLAIMS.md` are written on every build |
| promises that speak for claims (`spec/promises/`) | 43 sized. The first evening and the Garden's atlas are fully spoken for. Nothing is kept yet |
| `game/build.sh` runs the guard and fails on what it refuses | done |
| witnesses in the world; a proof field of asters as tall as cathedrals; the walking player | done: 12 tests pass; frames looked at and kept in `spec/promises/seen/` |
| on the purple | the asters walk: 2,398 frames, none late, 18,055 lines at most; both takes the same as the laptop |
| the walk in the room | built and on the purple (Ports, GameguyRoom): 8 promises to walk. Nobody has answered it |
| `spec/size.md`: one to a hundred, the ring's size, what the card is for | written. Its measurements are owed (its last section) |
| `spec/years.md`: three wants, ties, meetings, being them, generations | written |
| `spec/together.md`: the cable carries it; a world for two | written |
| rumble, the microphone, the comma in real air | out, on Morgan's word (`DECISIONS.md`) |

## Next

1. Morgan reads and edits `SPEC.md`, `spec/size.md`, `spec/years.md` and `spec/together.md`, and
   runs GameguyRoom on the purple (or the black, once the game is put on it).
2. Pull the room's log and read every `room:` line; fold the answers into `docs/hardware-target.md`
   and the specification.
3. The build goes on from stage 1, in a session opened with the brief in `SPEC.md`, section 22.
   Stage 2 begins by sizing a promise for each of its open claims
   (`python3 -I spec/tools/promises.py --open 2`).

## Stages

| stage | state |
|---|---|
| 1. the workshop and the engine | begun: see `game/README.md` for what is in and `spec/stages.md` for what the stage still owes |
| 2. the first evening and the Garden, finished | not started |
| 3. going out, mornings 2 to 7 | not started |
| 4. the way home, mornings 8 to 12 | not started |
| 5. the thirteenth morning and after | not started |
| 6. two consoles | not started |
| 7. the book, lent voices, and release | not started |
