# page

A toy, not the game. It exists to answer one question before a game is designed around the answer:
**should the game be flat or deep, and can it be both?** The idea it tests is in
`design/the-page-and-the-place.md`.

It is the wheel toy's garden with the wheel toy's rules, which it uses as they are (`../wheel/src`).
What it adds is one camera. From straight above, with everything lying flat, the garden is a page.
From low behind Hum, with everything standing, it is a place.

## What happens

1. **The dark, on the page.** Call (tap R1). A ring of light runs out. Something answers in teal.
   Walk to it.
2. **Drip.** Hold R2 to hum and let go on its tick. Between your two voices a figure turns: three
   lobes by two, flat.
3. **"Oh. You're in."** A lower note comes in under you both, one that neither of you is singing.
   The page tilts back and everything on it stands up. The far edge of the ground appears, with the
   day coming up over it and asters as tall as cathedrals.
4. **Knots, three creatures, the garden.** As in the wheel toy, now in the place. Each creature's
   body has depth, from the note between its own note and home. Kin have no note between, and stay
   flat.
5. **Hold the wheel (R1), or sing (R2),** and the place folds back onto the page so that it can be
   read. Let go and it stands again.

## Controls

Everything in `../wheel/README.md`, and:

| input | does |
|---|---|
| D-pad left / right | change the look: page and place, place only, page only. Its name shows at the top right |
| right stick, with R1 and R2 up | turn the view (once the world is standing). The left stick moves Hum by what is on the screen |
| top face | numbers on / off; they now show how deep the view is and how many marks were drawn |

In a window on the laptop (`--windowed`): V changes the look. The arrow keys are the right stick.

The three looks:

- **Page and place** (the default). A page until the third note, a place after, a page again while
  the wheel is held.
- **Place only.** A place from the first call. The wheel stands round Hum as an arch, and its five
  dark wedges go under the ground.
- **Page only.** The wheel toy's picture.

## What to look for

- Does the garden standing up at "Oh. You're in." give you anything?
- In a fight, does folding to the page when you hold the wheel help you read it, or does it throw
  you out of it? Try the same fight in "place only".
- Is a fight easier on the page or in the place?
- Does "page only" feel like its own game?
- Can you tell kin (a flat hoop) from a fifth (a solid knot) at a glance?
- Does the fold make you queasy on this screen?
- When creatures are near, the camera rises a little and pulls back. Does that help, or would you
  rather keep the sky?

## How it works

- `deep` runs from 0 (page) to 1 (place) and moves two things at once: the eye comes down from
  overhead to behind Hum, and everything that can stand turns up on a hinge at its foot. On the page
  it lies pointing away from you.
- From straight above with nothing standing, every point is the same distance from the eye, so the
  page is exactly the flat picture. A test checks it to a hundredth of a pixel.
- The wheel is hinged along its line from nine o'clock to three, through Hum.
- A body is drawn by three pulses: home's, its own, and their difference. The third only counts once
  the body stands.
- Every point is worked out on the processor and sent as one batch of quads in one draw call. There
  is no depth buffer: only Hum and Drip cover anything, so things are drawn in two passes, beyond
  Hum and nearer than Hum.
- Everything about how the view moves is in `Feel` at the top of `src/draw.zig`, and the two camera
  positions are at the top of `src/cam.zig`.

## Not in it

Height in the rules (no jumping and no hills: the rules are on a plane). Solid surfaces: everything
is lines of light, as in the wheel toy, and `../meadow/` is the test of solid ground. A first-person
focus. Lock-on. Cuts on the beat.

## Build and run

```
toys/page/build.sh                            # tests, laptop binary, handheld binary, dist/
probe/tools/r36s.sh push toys/page/dist/ports/ /roms/ports/
probe/tools/r36s.sh run /roms/ports/GameguyPage.sh
probe/tools/r36s.sh pull /roms/ports/gameguypage/results/ toys/page/results/
```

On the handheld it also appears under Ports as GameguyPage.

Laptop check, with no screen or controller (a scripted player plays it through and saves frames):

```
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy toys/page/build/page-x86_64 \
    --headless --frames 4300 --dump /some/folder --dump-every 25
```

`--look both|place|page` picks the look to start in. `--yaw DEGREES` starts with the view turned.
`--bot` runs the scripted player in real time with real sound, for measuring on the handheld.
`--skip N` starts N scenes in. `--help` lists the rest.

## Measured on the black unit, 2026-11-14

The scripted player, 4,270 frames a session, through the launcher (`results/black-20261114/`; the
unit's clock reads April):

| | page and place | page only | place only |
|---|---|---|---|
| a frame, on average | 17.10 ms | 17.09 ms | 17.10 ms |
| the worst frame | 20.3 ms | 20.1 ms | 26.1 ms |
| late frames | none | none | 2 |
| the toy's own work in a frame | 1.31 ms | 1.29 ms | 1.44 ms |
| the busiest frame, in marks | 1,406 | 1,170 | 1,445 |
| gaps in the sound | none | none | none |

- The display shows a frame every 17.09 ms, so all three keep up with it.
- In the first look the scripted player spent 21.1 s on the page, 43.8 s in the place and 8.6 s
  between, opened the wheel 7 times, and landed a walk of three 30 ms before the one.
- The wheel toy's own renderer does the page in 0.68 ms of work a frame. Seeing it through the
  camera costs about 0.6 ms more.

## Played by hand, 2026-11-14

Morgan played it twice on the black unit (`results/black-20261114/by-hand/`), in the default look.
His first words, with a fuller report to come:

- "there were some moments where it really click"
- "the moments in the music and everything ... and the beat ... it was all feeling really good"
- "I do love the ... aesthetic and ... visual aspects of the thing I was playing"
- "really liked the little 'oh' moment"

What the two logs show:

| | first session | second session |
|---|---|---|
| length | 2 min 29 s | 7 min 25 s |
| in with Drip | after 50 s, the last breath 8 ms from its tick | after 62 s, the last breath 9 ms from its tick |
| the wheel | opened 10 times, held up to 23 s | opened 11 times, held 6 s in the middle, up to 16 s |
| strikes | none | 155: 17 on a meeting, 43 timed by hand |
| lashed | 10 times, shaken apart twice | 36 times, shaken apart 9 times; 2 pockets |
| let go when nothing could come home | 3 times (nothing was grey) | 15 times, 12 of them with a grey knot or creature waiting |
| the knots | none went grey | first one grey after 115 s of the fight, all three home after 293 s |
| got as far as | the knots | the three creatures; one walked home, 102 ms from the one |
| on the page, in the place | 104 s, 37 s | 178 s, 249 s |
| late frames, sound gaps | 2 (worst 28 ms), none | 3 (worst 27 ms), 11 (worst 15 ms) |

- The look was never changed with the D-pad, so only "page and place" has been seen by hand.
- **The toy never said which button strikes,** and in the first session nothing was struck.
- **It gave no hint when home was in the wrong place.** With home off the meeting place, strikes
  do not drain and letting go brings nothing home, and the screen said nothing.
- **It never said how to dodge.** 46 lashes, 2 pockets.

Changed because of that, in the rules both toys share (`../wheel/src/world.zig`), prompts only:

- "Y: STRIKE ON THE ONE" (the left face button, which this handheld prints as Y).
- "R1: POINT WHERE THEY MEET" whenever home is not where the knots' strands meet, with the wheel
  open or shut.
- "A: DODGE ON ITS BEAT" for six beats after a lash, until a dodge has opened the pocket once (the
  right face button, printed A).

## What it found on the way: storage activity stalls frames

The first runs here, and every earlier run of the wheel toy, had 3 to 10 frames a session that took
150 to 315 ms. The cause is the built-in storage (the eMMC): while it is read or written, its
controller raises about 70,000 interrupts a second on the core that also serves the GPU and the
display. The cure is in every toy's launcher now (the storage controllers' interrupts get core 3,
the toy keeps to cores 0 to 2), and with it the sessions above have no stalled frame.

An SD card in the TF2 slot turned out to be far lighter: 12 interrupts for each 256 KB read and
about 440 for each 256 KB written, against 1,100 to 5,000 for the built-in storage.

The measurements are in `docs/hardware-target.md`. What was used to find it is here:

- `tools/watch-device.py`: samples interrupts, soft interrupts, disk activity and clock speeds 20
  times a second.
- `tools/run-with-watcher.sh`: runs the toy with its logs in memory and the watcher beside it.
- `tools/storage-stall-test.sh default|moved write-builtin|read-builtin|read-card|write-card`:
  the same session with 256 KB written or read every two seconds, as the device comes or with
  the cure. `read-card` reads straight from the card in TF2: nothing is mounted and nothing is
  written.
- `results/black-20261114/storage-stall/`: the eight test sessions, and one watched session.
- The session log now says when any frame takes more than two and a half frames' time, by the
  wall clock, so it can be matched against the watcher.

## What a session leaves behind

`results/page-<time>.txt`: everything the wheel toy logs, and also each change of look, any stalled
frame, and at the end how long was spent on the page, in the place and between, and the busiest
frame.

## Layout

- `src/cam.zig`: the camera and the hinge, with its tests (`zig test src/cam.zig`).
- `src/gfx.zig`: one batch of lines, discs, glows and label type, each placed in the world and seen
  through the camera. Curves are drawn as one joined ribbon.
- `src/draw.zig`: the garden, and how the view moves.
- `src/main.zig`: controls, the scripted player, the loop, the session log.
- The rules, the sound and the wheel's arithmetic are `../wheel/src/world.zig`, `synth.zig` and
  `music.zig`, reached through `../wheel/src/rules.zig`.
- Shared platform code is in `../common/`.
