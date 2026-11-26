# game

The game's code.

- **What the game is to become:** `../design/the-game.md`, with its parts two and three,
  `../design/the-depths.md` and `../design/the-wormhole.md`. Morgan, 2026-11-26: "this is
  absolutely 100% the direction".
- **What this code is:** it was built to `../SPEC.md` between 2026-11-19 and 23, and that
  specification is history now. Its comments cite `SPEC.md`, `spec/` and older design documents for
  where an idea came from, not for what the game is. Names in it come from the older design: the
  wheel's `Mood` values (lift, bind, drive, flow, remember, strike, darkest) are the old mood
  wheel's seven powers.
- **What it does today:** `../PROGRESS.md`, "Now". **What is built next, and in what order:**
  `../ROADMAP.md`. **The shape this code is being moved to,** with an audit of how it is laid out
  now: `../docs/engine.md`.

## What is here so far

The workshop, and the first evening as it was built to the specification. The code also holds
knots, a fight, the hose opening and the four ways home, but knots are switched off, so none of
that can be reached by playing (`../PROGRESS.md`, "Now").

- **The chords try-out** (`--chords`, `chordStep` and `wakeKin` in `src/world/world.zig`): the
  direction's first step. L1 and L2 step the chord among the lift, home and the lean wherever Hum
  is, and Hum's body follows. Off unless asked for. On the purple it has its own launcher,
  `port/GameguyChords.sh`.

- **The first evening** (`src/dark.zig`, `--scene evening`, the default). It opens as a page in the
  dark. R1 calls: a ring of light runs out and lights what it passes, and kin answer late by their
  distance. Drip ticks far off and answers the second call. Hold R2 to hum beside it and let go on
  its tick: four breaths bring its fifth true, and the two lock. The dawn rises at your feet and
  runs out over the ground at the speed of sound, the page stands up ("Oh. You're in."), and the
The left stick walks, the right stick looks, and Select and Start together leave. Once the day has
  come up, R1 held opens the wheel: the view rises over Hum and the wheel lies on the ground; point
  with the right stick and let go to move home (two moods are awake: sunny home, at the top, and
  wonder, a twelfth of a turn left), and Hum's note moves with it. `--scene dark` is the older proof
  of the dark alone, and `--scene asters` starts at dawn.
- **The asters** (`src/world/asters.zig`, `src/draw/aster_lines.zig`): a field of 67 asters as tall
  as cathedrals, one to a hundred. A call climbs every stalk, and the bells of a crown are heard
  late by their height. Stand still at a foot and the view leans back.
- **The sky** (`spec/sky.md`): the dawn at your feet; the horn over the lake, each ring lit when the
  sun reaches it and heard when its note has crossed the water; stars; the sun as a figure.
- **The Garden's ground** (`src/world/ground.zig`): lawn sheds dew behind you, fallen leaves ring
  underfoot each in its own note, moss halves your call and dims you, clover is a roof.
- **The bee** (`src/world/flyers.zig`): it works the clover and hovers in figures of eight, and its
  note falls a fifth as it passes.
- **The puddles** (`src/world/pools.zig`): four, south of where Hum wakes. Hum at one and the shape
  your note stands in comes up on the water as lines of light; walk across on them. Pollen
  gathers on the still lines and keeps the last figure; a call makes a puddle flash its shape.
- **The seven laws, so far** (`src/world/world.zig`): sympathy, travel, standing waves, building
  up, and the beating of the breaths.
- **One cue for every sound** (`src/world/cue.zig`): a sound can't be made without its light, and
  `World.tell` is the only way anything sounds.
- **The sound** (`src/sound/sound.zig`): one bank of resonators. A rung thing is a short burst into
  its overtones; voices are pulses through vowels; standing water is a held pure tone.
- **Lines of light kept on the GPU** (`src/draw/lines.zig`): black shapes that hide, the phosphor,
  light as loudness, the sky's glow, the ground's light, in three passes.
- **Takes and saves** (`src/keep/`): a take is the hands, ten bytes a change, kept in
  `keep/takes/` when a person leaves; a save is the whole world at a step, kept in `keep/dawns/`
  at every dawn. `--replay TAKE` plays a take back, `--load SAVE` opens a save.
- **The controls** (`src/plat/plat.zig`): face buttons are found by where they are, from the
  kernel's codes, never from a controller database's names. `--controls` reports what was found
  without opening a window.
- **Witnesses** (`src/world/witness.zig`): the world notes when a promise's moment happens
  (`../spec/promises.md`).
- **The room** (`src/room.zig`): where a person's ears, eyes and hands answer and every answer is
  logged. It asks who is holding the handheld (A Morgan, B JJ, Y someone else); then the ear
  check; then the walk puts them in each promise that has a scene and asks its one question; then
  three checks (a tone, the backlight following a swell, the left stick); then the 31 listening
  clips from `design/listen/`. A is yes, B is no, Y again, R1 and L1 move on and back.
- **The loop** the specification asks for: the sound card's sample count is the only clock, and a
  step of the world is 800 samples.

## Build and run

```
game/build.sh                        # tests, laptop build, two runs with no screen, the same-take
                                     # check, handheld build, the pack
game/build.sh laptop                 # everything up to the handheld build
probe/tools/r36s.sh push 164 game/dist/ports/ /roms/ports/
probe/tools/r36s.sh run 164 /roms/ports/Gameguy.sh            # play the first evening on the handheld
probe/tools/r36s.sh run 164 /roms/ports/Gameguy.sh --scene dark   # the dark alone
probe/tools/r36s.sh run 164 /roms/ports/Gameguy.sh --bot --frames 1800   # scripted hands, real sound
probe/tools/r36s.sh run 164 /roms/ports/Gameguy.sh --scene asters        # the asters, in the hand
probe/tools/r36s.sh run 164 /roms/ports/Gameguy.sh --scene asters --bot  # walked by the scripted player
probe/tools/r36s.sh run 164 /roms/ports/Gameguy.sh --lines    # how many lines a frame holds
probe/tools/r36s.sh run 164 /roms/ports/GameguyRoom.sh        # the room
probe/tools/r36s.sh pull 164 /roms/ports/gameguy/results/ game/results/purple-DATE/
```

On the handheld the game appears under Ports as Gameguy, and the room as GameguyRoom. The room's
answers are in the session log: `results/gameguy-DATE.txt`, the lines that start `room:`.

With no screen, on the laptop:

```
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy game/build/gameguy-x86_64 --headless --frames 1200 \
    --dump DIR --dump-every 150 --wav FILE.wav
```

## What the build proves each time

1. The rules, the sound and the arithmetic pass their tests with no screen.
2. Both programs run with no screen and write nothing to the error stream.
3. Ten minutes of the dark and the walk to the great aster give the same fingerprints as the
   handheld's last run (`results/same-take-aarch64.txt`). After a change to the rules or the sound,
   run `same-take-aarch64 10` on the handheld again and keep its lines there.
4. The promise book (`../spec/promises.md`) was retired as a frame on 2026-11-25. The build still
   runs `promises.py --zig` to write `src/world/promise_list.zig`, the list the world's witness code
   reads.

## Measured on the purple, 2026-11-19

| what | measured |
|---|---|
| lines a frame | 30,000 in 11.1 ms and 40,000 in 13.2 ms, every frame on time, with 5,000 black triangles and all three passes |
| overtones a core | about 2,100 in half a buffer at the throttled clock (`bench/modes.zig`) |
| one take, two machines | ten minutes of world and sound identical on the laptop and the purple |
| the dark, thirty seconds, real sound, scripted hands | 1,800 frames, none late; 2.0 ms of work a frame; the slowest sound buffer 0.26 ms of 2.67 |
| the asters, walked by the scripted player, real sound | 2,398 frames, none late; 2.7 ms of work a frame (6.2 at worst); 18,055 lines at most; the slowest sound buffer 0.76 ms; one cue late |

## Layout

- `src/main.zig`: arguments, the window, and which thing runs.
- `src/dark.zig`: the scenes: the dark and the call, and the asters: the loop, the pad, the picture,
  the backlight.
- `src/room.zig`: the room.
- `src/world/`: the rules. No platform, no clock, no allocation.
- `src/sound/`: the bank. No platform.
- `src/draw/lines.zig`: the line renderer.
- `src/plat/`: SDL2 and OpenGL ES loaded at run time, from `toys/common/`.
- `src/bot/script.zig`: scripted hands. `src/bot/walker.zig`: a player that plays by rules.
- `src/rules.zig`: where tests and tools that need no screen start.
- `tools/same_take.zig`: one take on every machine.
- `bench/modes.zig`: how many overtones a core renders.
- `port/Gameguy.sh`: the launcher. `port/GameguyRoom.sh`: the same, into the room.
  `port/GameguyChords.sh`: the chords try-out, with its own program and start.
- `results/`: what the handheld's runs left.
