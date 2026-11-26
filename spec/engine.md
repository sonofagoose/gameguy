# The engine

> **Status, 2026-11-26.** History, from the specification of 2026-11-19: how the game is built. The
> code in `game/` follows it (Zig, one clock from the sound card, a deterministic world, lines of
> light), and those technical choices stand until a measured reason changes one. Where it describes
> the game itself, the direction wins. What the game is: `design/the-game.md`.

_Part of the specification (`../SPEC.md`, section 19): how the game is built so that everything in
the other files can be true on this handheld. The technical choices are Fable's to make and are
decided here; a build session may change one for a measured reason, and writes the reason in
`DECISIONS.md`._

## The choices

| choice | decided | why |
|---|---|---|
| language | Zig 0.17, the compiler in `.tools/zig` | the cross-build for the handheld, the headless run and the same-take proof all exist in it already; one compiler builds the laptop, the handheld, WebAssembly and C |
| libraries | SDL2 and OpenGL ES 3.0, loaded at run time | as the toys do (`toys/common/platform.zig`); the binary needs only the C library |
| where | `game/`, on a clean slate | the toys stay toys |
| who owns it | one owner | Part 0: one owner for the game, agents only for bounded side-work and for grading |

## Layout

```text
game/
  build.sh        one command: tests, laptop build, handheld build, pack
  src/
    main.zig      the loop: hands in, steps, frame out
    plat/         SDL2 and OpenGL ES at run time; the clock; files
    hands.zig     input, stamped in samples
    world/        the rules. No platform, no clock, no allocation after the start
    sound/        the bank, the voices, the room. No platform
    draw/         lines on the GPU, the beam, the page and the place
    place/        pieces of land, read from the card as you walk
    keep/         takes, saves, the book
    link/         two consoles
    bot/          the scripted player
  scores/         one text file per land and per kind of thing
  sounds/         one text file per instrument and voice
  tools/          score, modes, echoes, ears, frames, same-take, room
  bench/          the hot loops, timed
  port/           the launcher
```

## Cores and budgets

- **Core 3** takes the storage controllers' interrupts. The launcher sets that up, pins the clocks
  at full speed and allows real-time priority, as every toy's launcher does now
  (`toys/page/port/GameguyPage.sh`).
- **Cores 0 to 2:** the main thread (hands, the world's steps, building the frame), the sound thread
  at real-time priority, and a loader thread that reads from the card.
- **A frame is 16.7 ms.** The budgets, against the purple's throttled clock:

| what | budget | measured so far |
|---|---|---|
| the world's steps | 3 ms | the wheel toy's whole world: under 0.7 ms |
| building the frame | 4 ms | the page toy: 1.3 to 3.6 ms for 1,400 marks, with every point projected on the processor |
| the GPU | 11 ms, in three passes | 30,000 lines and 5,000 black triangles: 11.1 ms |
| the sound thread | half of each 2.67 ms buffer | 2,100 overtones (`game/bench/modes.zig`) |
| memory | 300 MB | |

## Time

- **The sound card's sample count is the only clock.** A step of the world is 800 samples: sixty
  steps a second.
- **Each frame** the loop asks how many samples have been played and runs the steps that are due:
  none, one or two.
- **Hands are stamped in samples.** Each change of a button or a stick is recorded with the sample
  count at the moment it was read, to the millisecond. A step is given the hands as they stood when
  it began and the stamped changes inside it, so a release can be judged against the beat far more
  finely than one step.
- **A take is those stamped changes and nothing else.** The world never reads a clock, the screen or
  the sound card.
- **Hum's own breath is faster than a step.** The sound thread reads the same stamped changes and
  starts or stops Hum's voice one buffer after the stamp, whatever the step is doing. The world
  hears of it at its next step. Both follow from the take alone, so a replay is exact.
- **The picture is drawn between steps,** eased from the last step toward the next.
- **The display** is switched to its 60.02 Hz mode where there is one, so a frame and a step nearly
  coincide. At 58.46 Hz a second step runs about once every 38 frames.

## The same on every machine

The thirteen rules in `docs/other-platforms.md` hold. In code they mean:

- 32-bit floats for sound, 64-bit for musical time and pitch.
- A multiply and an add are never fused. Vector code uses `@Vector(4, f32)`, which measured
  identical on the laptop and the purple.
- Sine, exponential and the rest come from Zig's own library, never the system's.
- A float remainder is only ever taken by a power of two.
- A resonator that falls below a floor is set to nothing, so no machine ever computes with the very
  small numbers that different processors treat differently.
- Nothing is read before it is written. Nothing is ordered by where it sits in memory.
- One thread runs the world.
- `game/tools/same-take` runs in `build.sh` on the laptop, and on the purple at the end of every
  stage. It prints the loudest sample beside each fingerprint, so silence can't pass for a match.

## The world

- **Plain state.** Fixed arrays of plain values, no allocation after the start, no pointers inside.
  A save is the state written out; the same-take fingerprint is a sum over it.
- **A body** has a place, a kind, a note (a count of fifths, an octave, and the land's tuning), a
  range of resonators, a range of pendulums, a tune and a round.
- **Near and far.**
  - Near, within the pieces of land that are loaded, bodies are stepped in full.
  - Far, a life is a sum: its round and the morning's number give its place and its phrase. It is
    drawn as a light across the water and heard late.
  - Which is which depends only on where Hum is, so a replay agrees.
- **A resonator in the world** is a loudness for each overtone. Each step it fades by its ring time
  and gains from strikes, from sympathy with louder neighbours found through a grid of 16 m cells,
  and from pushes in time. The world doesn't track 48,000 cycles a second. It tracks how loud, and
  for each bound pair how far round their slow beat has turned.
- **A step, in order:** hands; Hum; pendulums (law 3); resonators (laws 1 and 7); what moves (laws
  2, 4 and 5); what arrives late (law 6); lives; fights; then cues out to the sound, the picture and
  the book.
- **A cue** is how the world tells the player anything. It is declared once, with a sound and a
  light. The type has no way to hold one without the other.
- **Starting sizes:** 4,096 bodies near, 16,384 overtones, 2,048 pendulums, 256 cues a step.
- **Feel** lives in one table, as in the toys (`Feel` in `toys/wheel/src/world.zig`): every window
  and rate that hands will want changed.

## The sound

- **One bank of resonators renders everything.** Each overtone is one two-pole filter, four abreast.
  A rung thing is a strike into its overtones. A string is the same with whole-number overtones. A
  sung voice is a pulse through three to five vowel resonators.
- **What strikes them:** a strike (a short burst, shaped by how hard the mallet is), a pluck, a bow
  or a breath (a steady stream), a voice's pulse.
- **Which overtones are rendered.** The world's loudness list decides: the loudest at Hum's ears,
  after distance and the speaker's band, with a margin so nothing pops in or out. The rest become a
  soft bed for the land.
- **Budget on one core:** about 1,400 overtones for things, 16 sung voices, and the room. A second
  core's bank is there for crowded places if measurement asks for it.
- **Late arrivals.** A cue's sound is scheduled for when it reaches Hum's ears, softer and duller
  with distance.
- **The room.** Each place's first echoes are worked out from its shape by `game/tools/echoes` and
  kept on the card: a few delays and levels for each listening spot. One small feedback network
  makes the tail.
- **The end of the chain:** a fixed mix, a soft limit, and the speaker's shaping. With nothing in
  the jack, low voices are rebuilt from upper overtones. With headphones in, voices are placed left
  and right, and nothing depends on it.
- **It follows the world's count.** Every cue carries its sample time. The sound thread keeps no
  beat of its own.
- **Sounds are data.** `game/sounds/aster.txt` and its neighbours: the family, the overtones and how
  strong each is, how long each rings, what strikes it, and for a voice its vowel. Morgan can change
  a file and hear it without building anything.

## The picture

- **Pieces.** A land is cut into squares 64 m on a side. A piece holds its lines (two ends, a width,
  the body each belongs to), its black shapes (triangles that hide what is behind them) and its
  bodies.
- **Lines live on the GPU.** Each is one instance of a quad. The vertex shader places it, applies
  the hinge between the page and the place, and sets its brightness from its body's loudness, which
  is sent each frame as a small table.
- **Moving figures are built each frame** on the processor, as the page toy does: creatures, rings,
  the wheel, Hum. Up to about 3,000 marks.
| what moves | marks a frame, at most |
|---|---|
| the sky: the sun, flyers and the murmuration, rain rings (`sky.md`) | 1,500 |
| sounding lines bent into their overtones, nearest and loudest first (`texture.md`) | 600 |
| creatures and lives near Hum | 400 |
| rings of calls and answers | 300 |
| Hum, its echoes and the wheel | 200 |
| all of them | 3,000 (estimate, to be measured on the purple) |

- **Three passes,** because each costs this GPU a fixed amount:
  1. light from things that sound, behind the black shapes, into a full-size target;
  2. the phosphor: a half-size copy that keeps the brighter of this frame and what is left of the
     last, and bleeds a little for the halo (`toys/page/src/gfx.zig`);
  3. the screen: the two together, then the black shapes again, then crisp light and whatever
     covers.
- **The ground remembers** (`size.md`). Each piece has one picture, 256 dots on a side, of the light
  left on its ground. It is drawn in the first pass, under the lines, and where something sounds the
  world adds to it. Measured so far: a picture that size uploads in about 1.3 ms and the GPU samples
  far more dots a second than the screen needs. Drawing it with pieces loading is stage 1's to
  measure.
- **Three distances and a fourth.** A tall thing is drawn in full near, as a mast with points of
  light far off, and between; and within 85 m it also shows what is Hum's own size on it
  (`game/src/draw/aster_lines.zig`).
- **The view of a place** sits well behind Hum and low, so the horizon is low and Hum is small. At
  the foot of something tall, standing still, the gaze climbs it at the speed of sound, narrowing
  as it goes, so the ground is lost and the height is paid for in time.
- **The view goes round Hum.** The right stick turns it round Hum and moves it along one dial:
  from low at Hum's feet looking up, through the walking view, to high over Hum looking down on it.
  Distance, height and width move together on one smooth curve. The view is anchored to the
  ground under Hum, and to Hum's height only past a jump's, so a jump never moves the picture. Hum
  is drawn facing the eye, so from above it is still a figure.
- **Hum's legs.** Speed and way are apart, so a turn arcs and keeps its speed: 1.5 m round at a
  run, 5 m at a sprint. The first 6 m/s come at once and the rest climbs, to a run in another half
  second. Pulled right round at speed, Hum skids, and the ground it skids on sounds. The left
  stick's push is curved, so a small push walks. Slopes pull: uphill slower, downhill faster. The
  dodge and a knock-back are bursts through the same move, so what is solid stops them. A jump
  pressed just before landing jumps as Hum lands, and Hum squashes a little as it lands.
- **What stands between the eye and Hum.** The eye keeps over its own ground, and the line from
  Hum to it clears the ground: it rises over a slope quickly and comes down slowly, and past a
  steep rise round Hum it comes in instead. Anything thin inside a narrow cone round the line of
  sight is see-through; outside the cone, near things are drawn, because the near ground shows
  speed.
- **Far lands** are each a few hundred lines and lights, always loaded.
- **The backlight** is one number written each frame to a file the launcher opens for the game,
  moved smoothly, and put back when the game ends.
- **Measured on the purple** (`game/src/main.zig`, `--lines`): 4.4 ms for the three passes, and 0.22
  ms for each thousand lines. 30,000 lines draw in 11.1 ms and 40,000 in 13.2 ms with every frame on
  time; 60,000 miss. Black triangles are cheap: 20,000 of them add 2.2 ms. Each line is a strip of
  four corners: with six corners the same 30,000 took 15.5 ms. So a view holds about 30,000 lines.

## Places and scores

- **A score** is a text file for one land: the ground's heights as curves, the paths, what stands
  where (by rule and by hand), the lives and their rounds, the wonders, the great instrument's
  rooms, the tuning.
- **Tools turn scores into places:**
  - `game/tools/score` writes the pieces, the far piece and the land's tables;
  - `game/tools/modes` works out the overtones of plates and odd shapes;
  - `game/tools/echoes` works out each place's first echoes.
- **Looking at a land** is part of making it: the laptop build dumps it from above, as a page, and
  from inside, as a place.
- **Loading.** The pieces within three of Hum are in memory: forty-nine pieces, under 50 MB by
  estimate. The loader reads ahead along Hum's heading from the card, which costs the processor next
  to nothing (measured). With no card the game reads from where it is installed, with the storage
  interrupts on their own core.
- **Past the thirteenth morning** a land is made from its three numbers by the same tools' rules, at
  the river, before the morning starts.

## Keeping

`design/the-card.md` is the plan. In the engine:

- **The day's take** goes to a journal, 4 KB at a time, by a writer thread. A power cut loses a few
  seconds.
- **A save every dawn:** a new file, pushed out, renamed over the old. The two newest and one for
  every dawn are kept, each with a checksum.
- **Every dawn is kept for good** (`size.md`): what changed in the world since the dawn before, so
  any dawn can be opened. When a card fills, the oldest are thinned to their takes, from which each
  can be made again.
- **Nothing is a copy.** A piece on the card holds every thing in it as its own shape, and what has
  happened to each.
- **The handheld's own copy** is written at the river, when nothing is moving.
- **The book:** a page a day, with the pressed page, the river's song, the day's notes, the take and
  a line of facts.
- **Every file is documented** in `game/FORMATS.md`: little-endian, versioned, stamped with the
  version of the game that wrote it. The card keeps every version of the program that wrote a take.
- **Days are numbered, not dated.** The handheld's clock doesn't count while it is off.

## Two consoles

- **Lockstep over the cable.** Both consoles run one world from both players' stamped hands, each
  waiting for the other's before a step. The link's round trip is half a millisecond.
- **One sound clock.** The guest follows the host's, stretching its own sound by parts in a million.
- **Versions are compared first.**
- **Nothing is lost when the cable comes out** (`design/together.md`).

## The scripted player, and the tests

- **`game/src/bot/`** plays by rules, not by replaying a take: it walks to a goal, breathes with a
  tick, opens the wheel, lands a cadence. A stage gives it a route. It logs what it could not do.
- **Tests** run with no screen: the rules and the sound have no platform in them. Among them: one
  take gives one fingerprint; a save loaded in the middle of a day reaches the same fingerprint as
  the day played straight through; every wonder's truth, as a sum (a string stopped at two thirds
  sounds a fifth higher).
- **No screen needed:** `SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy`, with `--dump` for frames
  and `--wav` for sound, as the toys have.
- **`game/tools/ears`** reads a sound file and reports roughness, loudness, the balance across
  bands, what is left between 400 Hz and 8 kHz, and what is left when left and right are summed.
- **The room** (`game/src/room.zig`) runs on the handheld: it puts a person in a promise's moment,
  or plays a clip, and logs the button they answer with.
- **Witnesses** (`game/src/world/witness.zig`): the world notes when a promise's moment happens and
  how long the player stays in it. They are beside the world, not in its fingerprint, so adding a
  promise never changes a take.
- **`spec/tools/promises.py`** reads every sentence of the specification as a claim and works out
  where each stands (`promises.md`). `build.sh` runs it and fails on what it refuses.

## Reused from the toys

| what | from |
|---|---|
| SDL2 and OpenGL ES at run time, the clock, PNG dumps, the label font | `toys/common/` |
| the launcher's three fixes, and the doorway to the card | `toys/page/port/GameguyPage.sh` |
| the phosphor and the beam's weighting | `toys/page/src/gfx.zig`, `draw.zig` |
| the hinge between page and place | `toys/page/src/cam.zig`, with its test |
| the wheel's arithmetic and pure tuning | `toys/wheel/src/music.zig` |
| the opening's timings, as starting values for Feel | `toys/wheel/src/world.zig` |
| the same-take test | `toys/wheel/tools/same-take.zig` |
| the book's song and page | `toys/page/src/main.zig`, `draw.zig` |
| watching a session for stalls | `toys/page/tools/` |

The toys' own synth, their rules as written, and their projection of every point on the processor
are not reused: the game's sound is the bank, its rules are the laws, and its lines live on the GPU.
