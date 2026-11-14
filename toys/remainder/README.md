# remainder

A toy, not the game. It exists to answer one question before a game is designed around the
answer: **does steering by being slightly out of tune feel good in the hands, through this
speaker, on this screen?**

Each place in a pool holds a tone. You hold a tone. Where your tone agrees with a place, the
water between you stands still. Where it is a little off, the pattern turns at the rate the two
tones beat, and the turning carries you: sharp pushes you away, flat draws you in. One crest
passes you per beat, so what you hear and what you see move together.

> **2026-11-14.** The session played on the black unit on 2026-11-12 ran this toy's world at
> about a quarter speed, while its sound ran at full speed: 16,214 frames at 17.09 ms is 277
> seconds, and the log says 67.7 seconds were played. The time each frame took was measured from
> the wrong moment. It is fixed. The verdict from that session ("interesting mechanic", "not much
> feels like a game") was on the slowed toy.

## Controls

Face buttons are named by position, because the printed letters on these handhelds differ from
what SDL calls them.

| input | does |
|---|---|
| right stick up / down | lean sharp / flat: the remainder |
| left stick | a slow paddle |
| R1 / L1 | your tone a pure fifth up / down |
| R2 / L2 | your tone an octave up / down |
| D-pad up / down | the whole pool an octave up / down (find where it carries on the speaker) |
| bottom face button | home: back to the pool's first tone |
| right face button | lean mode ↔ peg mode |
| top face button | numbers on / off |
| left face button | paddle off / on |
| Select | next pool |
| Select + Start, held | leave |

- **Lean** (default): the stick bends your tone only while you hold it. Let go and you are back
  on your settled tone.
- **Peg**: the stick retunes and the tone stays where you leave it, like a tuning peg. Coming
  back to stillness has to be done by ear and eye.

Nothing needs a third thumb: the sticks own the thumbs, and everything used *while* steering is
on the four shoulder buttons.

## Pools

- **ONE**: one place. You start beside it, in agreement.
- **THREE**: three places that all agree with each other (1, 5/4, 3/2).
- **TWELVE**: twelve places on a wheel, each a pure fifth from the one before. Press R1 twelve
  times and you are back at the first tone, a comma sharp: the first place's water turns.

## Build and run

```
toys/remainder/build.sh                       # tests, laptop binary, handheld binary, dist/
probe/tools/r36s.sh push toys/remainder/dist/ports/ /roms/ports/
probe/tools/r36s.sh run /roms/ports/GameguyRemainder.sh
probe/tools/r36s.sh pull /roms/ports/gameguyremainder/results/ toys/remainder/results/
```

On the handheld it also appears under Ports as GameguyRemainder.

Laptop check, no screen or controller needed (plays a scripted demo, saves frames and sound):

```
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy toys/remainder/build/remainder-x86_64 \
    --headless --demo 0 --pool 0 --frames 720 --dump /some/folder --wav /some/folder/demo.wav
```

## What a session leaves behind

`results/remainder-<time>.txt`: the cost of the water shader on that GPU (and whether it fell
back to half resolution), the audio buffer the device gave, every 20 seconds the frame pacing
and audio gaps, and what the player did: pools, modes, fifths walked, registers, and each time a
place was brought to rest.

## Layout

- `src/tuning.zig`, `src/world.zig`, `src/synth.zig`: the rules and the sound, no platform
  code, unit-tested (`zig test`).
- `../common/`: shared by all toys. `platform.zig` loads SDL2 and OpenGL ES at run time;
  `shim.h` lists the C headers that `zig translate-c` turns into Zig declarations at build time.
- `src/gfx.zig`: the water shader, marks and labels. `src/main.zig`: controls, loop, measuring.
- Everything about how it feels is in `Feel` at the top of `src/world.zig`.

Look: Khole Caddy Style Book v1.1 (black field, chrome, one garden colour). Labels are Space
Mono (SIL Open Font License), rendered to `../common/font.alpha` by `../common/tools/mkatlas.py`.
