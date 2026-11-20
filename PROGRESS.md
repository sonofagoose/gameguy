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
| face buttons by where they are (`game/src/plat/plat.zig`, `Faces`) | done 2026-11-20: PortMaster's mapping names SDL's face buttons after the printed letters, so the game, the room and the toys had each one a place off (the room logged Morgan's A as "no", and as JJ). Each is now found by the kernel's code for its position; `--controls` reports it: bottom 0, right 1, left 3, top 2 on the purple |
| R1 and R2 told apart (`SPEC.md` 9) | written 2026-11-20 from Morgan's word after the wheel toy; the L1/L2 proposal in `DECISIONS.md` waits on him |
| saves (`game/src/keep/save.zig`) | done: the whole world at a step, 276,656 bytes, kept at every dawn a person plays; a save loaded in the middle reaches the same end, in a test and through the game itself |
| the take written as it is played (`game/src/plat/card.zig`) | done: a thread drains it to the card five times a second and makes the card hold it once a second; after a kill or a flat battery the next start goes on from the last dawn and the take |
| the first evening as the default | done: Gameguy opens the first evening; `--scene dark` is the older proof |
| Hum's voice at once (`game/src/plat/presses.zig`, `hands.voice-in-a-buffer`) | built 2026-11-20: the sound thread reads R1 and R2 from the kernel before every buffer and starts Hum's call or hum on the buffer after the press; the world tells the same sound on the stamped sample and it is not sounded twice; takes keep the stamps (version 2). Before this a press reached the ear 33 to 50 ms late. To be measured on the handheld: the log's "the hands:" line. A let-go is still heard at the world's next step |
| stage 2's claims sized | done 2026-11-20: every sentence the stage owes has a promise (138 promises sized over the whole book; stage 2's open claims went from 544 to none), so stage 2 may begin. The guard now refuses a quote too short to say which sentence it means, and reads three more facts from the source: nothing reads FN, the world never reads a clock, and play draws one line of words |
| law 1's cascade | done: a thing that rings rings its kin, more faintly each time (`whole.law1`) |
| home on the wheel (stage 2) | built 2026-11-20: home is a value in the world, the day's seven lit wedges in the Garden's pure tuning, two moods awake (wonder and sunny home); Hum always sings home. R1 held opens the wheel on the ground with the view risen over Hum, time thickens to a quarter (Drip's ticks, the bee, rings, the water) and what rings stretches into a held chord; the right stick points; letting go moves home. R2 held is the swell: Hum takes a band each bar, two marks either side light on the downbeat, a nudge on a downbeat steps home a wedge, and letting go on the one lands the full close or the amen, which the garden answers. A fifth puddle, sized for F, stands only when home is on wonder. Five clips cut from the game's own evening wait for Morgan's ears. Owed: the turn and the slide, the threads' look, Morgan's call on L1 and L2 |
| the first knots (`game/src/world/knots.zig`, stage 2) | built 2026-11-20: three knots south of the F puddle, two strands each (C and A, over the F below), pulsing three and five to a cycle that is a bar stretched by home's pitch against their root, so they stumble unless home is on F; the left face strikes with Hum's fork and drains them by how their strands meet the strike, most on the one; grey, an amen beside their root brings them home as still loops keeping the mood. On the wheel their threads run to their root. The scripted player fights them. Lunges, the dodge and the pocket built the same day: knots lunge to arrive on their one, a dodge on that beat opens the pocket (time thickens, the next strike takes more), a lunge not dodged knocks Hum back. Then the afterimage and the clap: each bar in the pocket keeps its strikes as a layer that lands again from a small Hum of light, up to four, fading bar by bar out of the pocket; L1 and R1 together clap, found on the sound's own thread and heard within a buffer, spending the layers and setting every knot in reach to the start of its cycle. Then the timed strike: within an eighth of Hum's beat a strike is the hands' own, at once, with its octave and a quarter more; off it the game places it on the next beat, plain. The face buttons are read from the kernel with the shoulders, so a timed strike starts within a buffer. Then the four doors, the lean, and Gentle or Fierce: where home stands against a grey creature's root when the cadence lands decides whether it rings open (and greys the next), settles to sleep, turns kin for a phrase, slides home or stays grey and calmer; grey, it leans toward the wedge on its left, in the place and on the wheel; the first evening is Gentle, which widens every window by half again and leans home beside the grey knots after a bar of an unsteered swell, and the scripted player now holds R2 without steering and lets the amen settle them asleep. Owed: the clap resetting every other cycling thing, comfort by sitting, choosing Gentle or Fierce at night, the Great Knot in the Hose |
| the ears (`game/tools/ears.zig`) | built 2026-11-20: reads a sound file and reports roughness (Sethares's sum over pairs of partials, a frame rough past halfway from a whole tone to a half step), loudness, the octave bands, what sits between 400 Hz and 8 kHz and what survives summing; with the game's log, each strike's octave. The build runs it on the evening. First reading: no rough stretch reaches two seconds (the longest 1.45 s), a timed strike's octave 6 dB under its note and a placed one's 52 dB under, and only 6% of the sound between 400 Hz and 8 kHz, 91% in the octave round 250 Hz. Then the speaker's shaping, the same day: 69% of the evening in the speaker's band, the longest rough stretch 0.77 s |
| the Garden's score (`game/scores/garden.txt`, `game/tools/score.py`) | begun 2026-11-20: the land's tables are written from its score at build time (`game/src/world/land.zig`), and the field's every placement now comes from it: the land's note, where Hum wakes, the great aster, Drip's clearing, the lake, the asters' rule and what they keep clear of, the puddles and the first knots. Proven a pure move: the same-take matches the purple's last run line for line. Next in the score: the bowl, the Mirror Pool, the spigot and the hose, and the first evening laid out inside them |
| the speaker is the floor, and the jack (`game/src/sound/sound.zig`, `game/src/plat/jack.zig`) | built 2026-11-20: partials under 400 Hz softer by twelve decibels an octave, what they lose given to their own octave and twelfth with the energy kept; Hum's mm and the oo with a wide speaker resonance round 640 Hz; low held tones rebuilt from their second and third harmonics; a two-pole cut at 180 Hz before the soft limit. The game reads the codec's playback path once a second and gives headphones the full range; the kernel's own switch reads backwards (measured with Morgan's hands). Cost on the purple at the sound's fullest: 0.9 microseconds of a 926-microsecond buffer. Owed: Morgan's ears on the shaped clips, on the speaker and in headphones |
| the purple | connected again on 2026-11-20 (Morgan: it had been all along; it was not answering on USB before then). It has today's build. Its same-take file is stale: run it there when Morgan is not using it. It has a build from before the evening scene. Its same-take file no longer matches |

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
