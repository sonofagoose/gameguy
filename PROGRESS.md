# Progress

Where the build stands, so a new session can pick it up. Newest first. The plan is in `SPEC.md`,
section 20, and `spec/stages.md`.

## Now: Piece 1 — The page at the top of the dial (2026-11-22)

Work order Piece 1: Continuous fold from 3D place into 2D top-down page at dial top (`orbit == 1.0`).

| piece | state |
|---|---|
| Continuous dial fold | done: right stick down transitions world continuously from place to page (Paper Mario / GameguyPage style) |
| Camera distance tightened | done: walking distance pulled in to 15m (was 22m) for deeper immersion, scaling out to 52m at dial top |
| Orthonormal camera up | done: `cam_up = { -fx * sp, cp, -fz * sp }`, `{fx, 0, fz}` at 90° down; zero singularity, zero NaN |
| Shader dawn & sky clamp | done: `@tan(pitch)` clamped for 90° look; `renderer.sky` disabled when looking down |
| Hum on page | done: flat circular mark with heading tick on XZ ground plane when `cam.stand < 0.5` |
| View base anchoring | done: `eye[1]` and `at[1]` keep ground elevation across fold |
| Headless frame dumps | done: verified with offscreen GL renderer at `stand == 1.0, orbit == 1.0`; visual artifact captured |
| Purple handheld push | done: built aarch64 binary and pushed to purple unit 164 |

## Gate 0 audit and first touch spec implementation (2026-11-22)

Work order: `gameguy-work-order-20261122.md`.

| piece | state |
|---|---|
| Gate 0: audit of uncommitted diff | done: 200+ lines across 13 files; see `design/keep-revert-table-20261122.md` |
| Piece 1: page at top of dial | done: full-range camera (0° to 90°) with smooth transition, true top-down page view |
| Piece 2: jump designed fresh | done: SM64×TotK standard, 2.8 m max height, variable height (tap=1.8m, hold=2.8m), coyote time 6 steps, air steering 0.20 |
| Piece 3: strike ported | done: GameguyPage groundArc animation, 16-part sweep arc |
| Piece 4: wheel as circle of fifths | done: both outer (major) and inner (relative minor) rings, key letters, 68% background dim when open |
| Piece 7: calls/rings ride air | done: Ring.y field stores airborne height |
| Piece 8: no knots before peace | done: knots off by default until Piece 8 designs gate |
| fast build targets | done: `./build.sh push`, `./build.sh handheld`, `./build.sh dev` targets |
| kill test runs (KILLS=100) | done: gate runs, skip only with `KILLS=0` env var |
| Bee timbre | done: warm owl character (Kaepora Gaebora, DECISIONS.md row 148) |
| pool resonance | done: smoothed onset, 0.62 voice level (Clip 32, whats-next.md) |
| Drip metronome | done: audible when needed, silent when exploring (works-next.md) |
| spec/doc files | done: BOARD.md, hands.md kept at HEAD, regenerated in gate run |
| PROGRESS.md updated | done |

## Now: Morgan's first room session, synthesis and actionable vision (2026-11-21)

Morgan played GameguyRoom on the purple (unit 164), answering all 59 items (the ear check, 13
walks, 3 hand checks, 41 listening clips).

| piece | state |
|---|---|
| Morgan's Room results pulled and analyzed (`design/morgans-room-session.md`) | done: 48 yes / 26 no (64.9%); 17 yes / 13 no on walks; ear threshold 1.2 cents |
| True Actionable Vision synthesized from all 87 md docs (`design/true-actionable-vision.md`) | done: approved by Morgan |
| Claude's status report reviewed (`design/review-plan.md`) | done: approved by Morgan |
| Build plan for next session (`design/whats-next.md`) | done: approved by Morgan; incorporates Safe Haven topology, SM64×TotK movement, kill drone, river loop |
| Open decisions decided (`DECISIONS.md` rows 146-148) | glide cut, D-pad open, creatures unique per land |

## The planning session's work (2026-11-19)

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
| the Garden's score (`game/scores/garden.txt`, `game/tools/score.py`) | begun 2026-11-20: the land's tables are written from its score at build time (`game/src/world/land.zig`). First proven a pure move (the same-take matched the purple's last run line for line); then the Garden laid out round the first evening (`SPEC.md` 6.1), on flat ground for now: the Mirror Pool, 300 m across, with reeds as tall as towers round it; Hum waking in the reeds on its north shore; the spigot, ten metres of brass on the back rise; the hose, a green tube 1.8 m across and 1,519 m long, from the spigot down the east of the garden and back along the shore to its coiled end 70 m east of where Hum wakes, Drip hanging at its mouth; the knot 300 m back along it, where the first knots wait; the puddles moved clear of hose and pool (at a hundred to one they are 50 to 110 m in radius); the asters by rule over the bowl, clear of pool, hose and spigot. Hum stops at the pool's shore. The scripted walk never crosses the hose. Then the hose as an instrument: stopped by its knot it hums from anywhere in the garden, a pipe two octaves under the garden's note sounding its odd overtones only, glowing along its nearest stretch at its note brought down eight octaves; every knot home, it springs open an octave up with every overtone, the water runs from the knot to its mouth and pours into the pool in rings, and for a second a blue figure sits on the pool's edge, at the garden's size, lines only. Next: the bowl's heights |
| the speaker is the floor, and the jack (`game/src/sound/sound.zig`, `game/src/plat/jack.zig`) | built 2026-11-20: partials under 400 Hz softer by twelve decibels an octave, what they lose given to their own octave and twelfth with the energy kept; Hum's mm and the oo with a wide speaker resonance round 640 Hz; low held tones rebuilt from their second and third harmonics; a two-pole cut at 180 Hz before the soft limit. The game reads the codec's playback path once a second and gives headphones the full range; the kernel's own switch reads backwards (measured with Morgan's hands). Cost on the purple at the sound's fullest: 0.9 microseconds of a 926-microsecond buffer. Owed: Morgan's ears on the shaped clips, on the speaker and in headphones |
| the Garden's ground (`game/src/world/ground.zig`, stage 2) | built 2026-11-20: a bowl from the score, the Mirror Pool's water its lowest point, rising 50 m to the rim's wall with the beds 10 m above and the spigot's rise 40 m higher at the back, each puddle level; a thing's y is its height above its own ground, and every line is lifted by the ground under it when it is made. Hum stops at the rim's wall. Sound's distances count the height between. A test holds the shape |
| how walking feels (stage 2) | begun 2026-11-20, from Morgan's first walk ("movement feels... stale. and collisions with the world... also stale"; "probably faster movement overall"). His two takes: the stick pushed all the way 95 to 100 % of the time, nothing ever touched. Done: the screen asks for its 60.02 Hz mode and the picture is drawn between steps by the sound's clock (travel from frame to frame varies by 0.8 cm against 2.4 to 2.9 by whole steps); measured in `docs/hardware-target.md`. Then Hum's body: a run of 9 m/s, reached in a sixth of a second, a short skid, turns at a rate, a view that swings in behind once the right stick rests and pulls back at a run, a stride's bob and a lean into turns; walls take the speed that goes into them (`DECISIONS.md`). The same take on the purple is identical. Then things to touch: aster stalks are solid, and a brush at a run knocks once and rings the aster's open fifth on its bells (clip 39). Then one breath (`breath.one`): homes of breath, three at first, spent by singing past two bars, steps home, the wheels and the sprint, refilled by silence, growing when a walk that took it all is landed, shown on Hum as its lines; and the sprint, the right face held while walking with nothing threatening, 15 m/s, breathing on the half beats (clip 40). The speaker's shaping no longer turns the hose's C into a D (`DECISIONS.md`). Then the bottom face: a jump of 2.5 m in three quarters of a second, and in the air the glide, sinking 2 m/s at 12 m/s for a home of breath a bar, with a ring on the ground under Hum and its sail of light (clip 41); the hose is solid, jumped or gone round, and its upper stretch now lies inside the rim's wall. Then, at Morgan's asking whether laws or lists drive it: touch became one law through law 1, and the glide became the specification's sail on the wind. The purple's late frames were the moving lines' CPU work, not the GPU (taking the trail, the ground's light or half the land away changed nothing); the puddles' heaving net worked out by ring and by angle and a skip of far puddles in the ground's sum took Morgan's take from 7,080 frames with 1,472 late to 7,748 with 546 late. The hose's drone moved up for the speaker is ten decibels softer, as it was heard down low. Then the ears again, by the laws: a bee hovering at a flower is in step with it (law 3) and its buzz holds still; each fallen leaf, a raft six metres square, rings once as it is stepped onto, so a sprint across the leaf fall plays a tune and not a cluster; the sprint's breath sits an octave over home. Checkpoints in the room: moving, and one breath. The spigot is a thing: solid, and it rings when touched, a brass bell two octaves over the garden's note. Every kept frame looked at again (two faults found and fixed: the page turned under Hum as the view followed, and the view over a still pool hid the wheel). Owed: the evening's longest rough stretch is 2.65 s, the bee flying off with its buzz falling through the hose's G and C (law 6), as long as where the scripted player stands when it leaves allows: Morgan's ear on clip 33 decides whether a flyer passing joins the laws' brief rough moments or its buzz must change; the rest of the late frames (on the purple, with half the land's lines 546 late against 982 whole, but two whole runs gave 546 and 982: the GPU may now be the limit for the land's lines, and repeated pairs must settle it before anything drawn changes), the leaves that tip and the blades that bend, the hose's low places, teaching sprint, jump and glide by need, slopes that pull, the ferry's eighth home, Morgan's hands on it; then the GPU's last tenth of late frames, and every kept frame looked at again |
| the game teaches itself (stage 2) | begun 2026-11-21, from Morgan's first evening (lost beside Drip; knocked back by the knots in the dark; his take replayed: 38 s beside Drip without humming, let-gos 220 to 360 ms after the tick). Done: the knots lie still until the place stands; Drip shows its breath; its upbeat; the figure only while both sound; a late let-go forgiven more with each miss; presses answered in the dark; teaching facts in every session's log. Then the songbook (Start: the world waits; wordless pages drawn in light, the handheld by its layout with the control's place lit in its rhythm; the page the moment asks for on top; `--songbook DIR` draws them all) and the hose's coil round Drip's clearing (a drawn line on the page, a tube once the place stands: the first walk out asks for a jump; in the air it is round, so a jump from beside it clears it). Checkpoint A in the room. Owed: sprint and glide by need, the evening's later beats, the frames the figure's change touches looked at again, checkpoint A for Morgan and a first play by JJ |
| playing on the laptop | built 2026-11-21, asked by Morgan ("some easy way for me to play the game on my laptop, either with a controller plugged in or just testing by playing with the keyboard... be ambitious"). `game/play.sh` builds the game if its sources changed and plays it in a window twice the handheld's screen; `game/play.sh room` plays the room. Any SDL game controller plays with its face buttons by position (SDL's button labels turned off), and one plugged in while playing is taken up. The keyboard is laid out like the handheld (the keys are listed at the top of play.sh). Saves, takes and session logs go to game/laptop/, apart from the handheld's. Owed: the songbook drawing the keys when played on keys; the room's own controller check on the laptop |
| after the first plays: the view, the touch, the wheels, the room (stage 2) | planned 2026-11-21 from four research strands (`design/after-the-first-plays.md`) and built the same day. Part 1, the view: the dial round Hum, the eye over the ground, the cone, straight runs, the follow, L2's swing, the fight's lift, Hum facing the eye. Part 2, the legs: arcs, the two-stage start, the skid-turn, the curved stick, slopes, bursts, the early jump, the squash. Part 3, what is solid: one rule for the covers and the reeds shared by the world and the picture; reeds, clover stalks, crumbs, the flower head, the rim and Drip answer a touch; never ending a step inside a solid; leaves ring where they are drawn. Part 4, the wheels: home's ring, home's move sung, the wheel at 0.4 s, Hum slowed, the view nearer, asleep wedges a hairline, a snap-and-hold, a click, the preview hummed under Hum's breath, twelve threads, the swell's chord bands and the one coming, the knots coming to a call and turning by their beat. Part 5, the room: one walks file, 13 walks from saves of this build's own evening, plain words, X for "didn't happen", the player's memory left alone, the build named, clips cut every build, presses cleared when the songbook closes, a hum the world never took up ended within 0.1 s. Part 6 begun: one recipe for the call and the hum, col8 and the named colours once, Hum's shape once. Also: the hum 3 dB quieter, the tick mellow with a deeper one. Measured on the purple, Morgan's evening replayed on its screen: before the view, from 53 °C, 2,985 of 23,347 frames late and 7.29 ms of work a frame; after the solids and the wheels, from a hotter start, 3,433 of 22,663 late and 6.89 ms: less work, more frames missing the screen (the GPU, with the cone in the line's fragment shader the likeliest cost). Owed: a fair pair of that, and the cone made cheaper if it is the cause; lock-on, the lean in two phases, the hose's rail; blades bending and wearing paths, moss and low crumbs to stand on, leaves tipping, the step-up and coyote jump with them; every thing's shape against home and the preview re-forming shapes; the swell's steps (Morgan's call); the ground's light fading while the lake is low; fact lines in the log; one hands reader; the ground picture's extent worked out with a header |
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
| 2. the first evening and the Garden, finished | begun: the rows above marked stage 2 |
| 3. going out, mornings 2 to 7 | not started |
| 4. the way home, mornings 8 to 12 | not started |
| 5. the thirteenth morning and after | not started |
| 6. two consoles | not started |
| 7. the book, lent voices, and release | not started |
