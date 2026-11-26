# wheel

> **Status, 2026-11-26.** A toy of the older design's wheel (`design/the-wheel.md`, history now).
> What it measured stands. What the game is: `design/the-game.md`.

A toy, not the game. It exists to answer one question before a game is designed around the
answer: **does the wheel earn a place in a fight, in the hands, through this speaker, on this
screen?** The idea it tests is in `design/the-wheel.md`.

You are a small bone-coloured creature that can hum one note. Everything else has a note of its
own. The wheel decides where home is, and what each thing is to you is how far round the wheel it
sits from home.

## What happens

1. **The dark.** Call (tap R1). A ring of light runs out. Call again, and something far off
   answers in teal. Walk to it and stand still.
2. **Drip.** Hold R2 to hum, and let go on its tick. Four breaths together and you are in. A
   lower note comes in under you both, and Drip rides on your head and keeps time from then on.
3. **Morning, and three knots.** Each knot is two strands, and they stumble. Hold R1: time
   thickens, and on the wheel each strand's thread runs to the same wedge on the left. Point
   there and let go. Now they meet on the one. Strike on the one until a knot goes grey, then
   hold R2 and let go on the one.
4. **Three creatures on a run of fifths.** Orange, yellow, yellow-green. Wear the orange one grey,
   put home beside it, hold R2, and nudge the right stick left on each one. Each nudge brings
   one home and turns the next grey. Let go on the one after the last.
5. **The garden.** Packs, for as long as you like. All seven moods are awake.

## Controls

Face buttons are named by position, because the printed letters differ from SDL's names.

| input | does |
|---|---|
| left stick | move |
| R1, tapped | call: a ring of light; it rings every creature it reaches in its own note |
| R1, held | the wheel: time thickens; point the right stick at a wedge; let go to put home there |
| R2, held | sing: the swell. Let go on the one |
| right stick, while R2 is held | a nudge left or right moves home one wedge |
| left face | strike with the fork; the game places it on the beat |
| right face | dodge; on the beat a lunge lands on, it opens the pocket |
| top face | numbers on / off |
| Select | gentle / plain (gentle: wider timing, and the wheel leans for you) |
| Start, held one second | skip the scene |
| Select + Start, held | leave |

The prompts name two buttons by the letters this handheld prints on them: Y is the left face
button (strike) and A is the right face button (dodge).

In a window on the laptop (`--windowed`): W A S D move, arrow keys are the right stick, U is R1,
I is R2, J strikes, K dodges, G is gentle, N skips, Tab shows numbers, Esc leaves.

## What to look and listen for

- **A creature's body is its interval to home.** Kin is a hoop, a neighbour a pretzel (three
  against two), a third a rosette. Move home and every shape on the screen changes.
- **How near a creature keeps is the same thing.** What leans in comes close. What is straight
  across keeps away.
- **Its pulse is the same thing again.** With the wheel open each creature's pulse is a note you
  can count. Near on the wheel is simple: kin meets you on every beat, a neighbour on every
  second one, a third once a bar. A strike only drains a creature when it lands on a meeting.
- **A grey creature shows a thread to you** when letting go would bring it home (bright) or sing
  it to sleep (soft). No thread means home is in the wrong place.
- **A strike you time yourself rings fuller** than one the game placed.
- **Near creatures hold still while you sing.** Far ones don't.
- **The ring that runs out from you** marks the one. Drip's tick is lower and louder there.

The questions, from `design/the-wheel.md`:

- Does standing where they meet feel like finding something?
- Does a nudge on the one feel like power?
- Can thirty-degree wedges be hit on these sticks without looking?
- Does the picture stay readable when every creature's shape and rhythm change as home moves?

## Not in it

Borrowed chords and the dark wedges, the turn and the slide (only the full close and the amen),
what a creature leaves behind in each mood, voices, the guard, echoes, any 3D (`../page/` shows this
same garden as a place, with these rules).

## Build and run

```
toys/wheel/build.sh                           # tests, laptop binary, handheld binary, dist/
probe/tools/r36s.sh push toys/wheel/dist/ports/ /roms/ports/
probe/tools/r36s.sh run /roms/ports/GameguyWheel.sh
probe/tools/r36s.sh pull /roms/ports/gameguywheel/results/ toys/wheel/results/
```

On the handheld it also appears under Ports as GameguyWheel.

Laptop check, no screen or controller needed (a scripted player plays it through; saves frames
and sound):

```
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy toys/wheel/build/wheel-x86_64 \
    --headless --frames 4200 --dump /some/folder --dump-every 30 --wav /some/folder/run.wav
```

`--bot` runs the same scripted player in real time with real sound, for measuring on the
handheld. `--skip N` starts N scenes in. `--help` lists the rest.

`tools/same-take.zig` checks that one take plays out the same everywhere. It runs the rules and
sound for twenty minutes with no picture and prints a fingerprint of the world and of the sound
each minute, with the loudest sample so far. Its header has the build lines. Its first version
(2026-11-17, morning) never built the wavetables, so it compared silence; the results of the fixed
version, on the laptop, the purple, WebAssembly and C, are in `docs/hardware-target.md`.

## Measured on the black unit, 2026-11-14

The scripted player, 4,270 frames (`results/black-20261114/wheel-20260414-140213.txt`; the
unit's clock reads April):

- Mali-G31, OpenGL ES 3.2, 640×480; sound through ALSA at 48,000 Hz in 128-frame buffers.
- 17.27 ms a frame on average, 5 late frames in the session; the game's own work 0.70 ms a frame.
- 27,884 audio callbacks, no gaps; the longest wait between two was 4.55 ms.
- The scripted player got in with Drip, opened the three knots and landed a walk of three, with
  each release 19 to 96 ms from the one.

A later run through the launcher as it is now (`wheel-20260414-160205.txt`): 17.09 ms a frame,
the worst 20.5 ms, none late, no audio gaps, 0.68 ms of work a frame. The five late frames above
were stalls of about a quarter of a second, caused by activity on the built-in storage. The
launcher now gives the storage controllers' interrupts a core of their own
(`docs/hardware-target.md`).

Nobody has played it by hand yet.

The first run that day (`wheel-20260414-135653.txt`) shows a bug that all three toys shared: the
time each frame took was measured from the wrong moment, so on the handheld the world ran at about
a quarter speed while the sound ran at full speed. It is fixed in all three.

## What a session leaves behind

`results/console-<time>.log` starts with the clocks the toy was started on and the priority it
got. `results/wheel-<time>.txt`: whether the sound thread got real-time priority, every gap in
the sound with its time, every call, every time the wheel opened and where home went, every
strike (how many creatures it rang, how many on a meeting, whether it was timed true), every
release and nudge with its distance from the one in milliseconds, every walk landed and its
length, every lash, and every 20 seconds the frame pacing and audio gaps.

## Layout

- `src/music.zig`: the wheel's arithmetic (wedges, what two notes are to each other, pure
  tuning). `src/synth.zig`: the sound and the beat clock. `src/world.zig`: the rules. None of the
  three has platform code; all are unit-tested (`zig test src/world.zig` runs every test).
- `src/gfx.zig`: one batch of lines, discs, glows and label type. `src/draw.zig`: the picture.
- `src/main.zig`: controls, the scripted player, the loop, the session log.
- Everything about how it feels is in `Feel` at the top of `src/world.zig`.
- `src/rules.zig` hands the three rule files to another toy as they are (`../page/` uses it).
- Shared platform code is in `../common/`.
