# game

The game. Its specification is `../SPEC.md`; where the build stands is `../PROGRESS.md`.

## What is here so far

The workshop, and the first minute of the first evening.

- **The dark and the call** (`src/dark.zig`). Black. R1 calls: a ring of light runs out over the
  ground and lights what it passes. Whatever is kin to Hum's note answers, late by its distance
  there and back. R2 hums. The left stick walks. Select and Start together leave.
- **Two of the seven laws** (`src/world/world.zig`): travel, and sympathy.
- **The sound** (`src/sound/sound.zig`): one bank of resonators. A rung thing is a short burst into
  its overtones; Hum's voice is pulses through a closed-mouth vowel.
- **Lines of light kept on the GPU** (`src/draw/lines.zig`): black shapes that hide, and the
  phosphor, in three passes.
- **The asters** (`src/world/asters.zig`, `src/draw/aster_lines.zig`): a proof field of 70 asters
  as tall as cathedrals, one to a hundred. A call runs over the ground and climbs every stalk; the
  bells of a crown are heard late by their height. Stand still at a foot and the view leans back.
- **Witnesses** (`src/world/witness.zig`): the world notes when a promise's moment happens
  (`../spec/promises.md`).
- **The room** (`src/room.zig`): where a person's ears, eyes and hands answer and every answer is
  logged. It asks who is holding the handheld; then the walk puts them in each promise that has a
  scene and asks its one question; then three checks (a tone, the backlight following a swell, the
  left stick); then the 31 listening clips from `design/listen/`. A is yes, B is no, Y again, R1
  and L1 move on and back.
- **The loop** the specification asks for: the sound card's sample count is the only clock, and a
  step of the world is 800 samples.

## Build and run

```
game/build.sh                        # tests, laptop build, two runs with no screen, the same-take
                                     # check, handheld build, the pack
game/build.sh laptop                 # everything up to the handheld build
probe/tools/r36s.sh push 164 game/dist/ports/ /roms/ports/
probe/tools/r36s.sh run 164 /roms/ports/Gameguy.sh            # play it on the handheld
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
4. The promise book (`../spec/promises.md`): every sentence of the specification is read as a claim,
   every promise's rungs are worked out from this build, and the build fails on anything refused.

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
- `results/`: what the handheld's runs left.
