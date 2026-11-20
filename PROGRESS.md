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
| the ear, before and after: a staircase between a still fifth and a turning one, in the room straight after it asks who is holding it | built and on the purple. Nobody has taken it. It should be taken before a person first plays |
| `spec/size.md`: one to a hundred, the ring's size, what the card is for | written. Its measurements are owed (its last section) |
| `spec/years.md`: three wants, ties, meetings, being them, generations | written |
| `spec/together.md`: the cable carries it; a world for two | written |
| rumble, the microphone, the comma in real air | out, on Morgan's word (`DECISIONS.md`) |

## The first evening, the sky, the shape and the texture (2026-11-19 to 20)

| piece | state |
|---|---|
| one cue mechanism (`game/src/world/cue.zig`, `World.tell`): a cue can't hold a sound without its light, and `tell` is the only way anything sounds | done; the promise `whole.twice` cites its tests, and the promise tool reads the world's source and counts any sound sent from outside `tell`: none |
| the first evening as one scene (`--scene evening`): the dark page, the drip ticking far off, the second call answered, four breaths on the tick bringing its fifth true, the lock, the third note, the page standing up | done; the scripted player plays all of it; 23 tests pass |
| ears in the take tool: Drip's pitch and the third note read back from the rendered sound | done: the two notes beat 1.79, 1.36, 0.91 and 0.46 times a second across the four breaths, then not at all; the third note is 53 dB over the quiet before |
| takes (`game/src/keep/take.zig`): a person's hands written to the card when they leave a scene, `--replay` to play one back | done; the build plays the evening's take back from its file and checks the same moment on the same step |
| the sky, first piece: the dawn at your feet, spreading at the speed of sound; the horn over the lake, each ring lit when the sun reaches it and heard when its note has crossed the water; the seventh dark; stars; the sun as a figure | done in the evening scene, every frame on time on the laptop (`spec/promises/sky.md`) |
| light as loudness (`spec/texture.md`): each body's own light spread over its lines; outside light given back by what it is made of | done in the renderer's table |
| four covers on the proof field's ground, each its own shapes; bare soil mostly bare | done for the Garden's proof; the twelve lands' covers are written in `spec/shape.md` |
| `spec/sky.md`, `spec/shape.md`, `spec/texture.md`; `docs/two-games-as-felt.md` | written, and corrected by an independent review: four readers, a skeptic for each; 100 of 127 findings confirmed and applied |
| the Garden's covers as rules (`game/src/world/ground.zig`): lawn sheds dew behind you, fallen leaves ring underfoot each in its own note, moss halves your call and dims you, clover is a roof | done, with tests and the promise `garden.ground`; sparks show where each small sound happened |
| every kept frame measured as it is kept (`spec/tools/beauty.py`) | done: at least 54% black in the place, at least 90% on the page, at most 3.3% of any frame brighter than half |
| the bee (`game/src/world/flyers.zig`): works the clover, hovers in figures of eight, its note a pure fifth from coming to going; far sounds come back softer and duller; nothing between the eye and Hum hides it | done, with a test and the promise `sky.bee` |
| the puddle bridge (`game/src/world/pools.zig`): four puddles as round skins with their real Bessel shapes; humming builds the shape whose note is among Hum's overtones; the still lines hold Hum and the bellies throw it back; still water floats Hum ashore; pollen gathers on the still lines and keeps the last figure; a call makes a puddle flash its shape; the water sings Hum's note back as a held tone; the view rises over a standing puddle and lifts behind Hum on the water | done in the evening scene, with six tests, three measured facts of its sound (no beating, nothing rough, about 4 dB of bloom) and the promise `garden.w04`; the scripted player crosses the bridge puddle. Owed: the note above (the wheel), other outlines, the water's mirror |
| the purple | **stale**: not seen on USB since 2026-11-20 03:59. It has a build from before the evening scene. Its same-take file no longer matches |

## Next

1. Morgan reads and edits `SPEC.md`, `spec/size.md`, `spec/years.md`, `spec/together.md`,
   `spec/sky.md`, `spec/shape.md` and `spec/texture.md`, and
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
