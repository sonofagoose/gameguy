# meadow

A toy, not the game. It tests two things before a 3D game is designed around them: how much world
this handheld can draw, and how moving through it feels. A seed-sized creature in a patch of meadow
can run, jump, glide, and bounce off mushroom caps, at noon or at 2am.

Status (2026-11-14): its benchmark has run on the black unit
(`results/black-20261114/meadow-20260414-160338.txt`; the unit's clock reads April). Nobody has
moved through it on the handheld yet.

| view | GPU time for the whole picture | triangles, draw calls |
|---|---|---|
| down in the grass | 8.2 ms | 62,848 in 68 |
| gliding above it | 11.9 ms | 93,747 in 100 |

- It chose full resolution. Lower resolution hardly helps (7.7 and 11.5 ms at 75%): the cost is in
  the number of triangles.
- Grass twice as dense costs 13.4 and 19.4 ms. The grass is most of the picture's cost.
- Standing still in play: 17.09 ms a frame, the worst 17.57, none late in 1,470; 76,361 triangles
  in 87 draw calls, with 2.3 ms of CPU for the game and the draw calls.
- Small triangles go through at about 10.9 million a second.

## What it does at start

It times each layer of the picture on the GPU from two places (down in the grass, and gliding above
it):

- the sky, then the ground, then the stones, plants and tree, then the grass;
- denser grass, at twice and four times as many blades;
- the whole picture at 100%, 75% and 50% resolution;
- raw triangle throughput.

It picks 75% resolution if the full picture would take more than 13 ms, writes everything to the
session log, then lets you play.

## Controls

Face buttons are named by position, because the printed letters differ from SDL's names.

| input | does |
|---|---|
| left stick | move |
| right stick | camera |
| R1 or bottom face | jump; hold while falling to glide |
| L1 or right face | dash |
| left face | noon / 2am |
| top face | numbers on / off |
| Select | next resolution (100%, 75%, 50%) |
| Start or right-stick click | camera back behind the creature |
| Select + Start, held | leave |

## Build and run

```
toys/meadow/build.sh                          # tests, laptop binary, handheld binary, dist/
probe/tools/r36s.sh push toys/meadow/dist/ports/ /roms/ports/
probe/tools/r36s.sh run /roms/ports/GameguyMeadow.sh
probe/tools/r36s.sh pull /roms/ports/gameguymeadow/results/ toys/meadow/results/
```

On the laptop, with no screen or controller (scripted demo, frame dumps):

```
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy toys/meadow/build/meadow-x86_64 \
    --headless --demo 0 --frames 600 --dump /some/folder --dump-every 60
```

Options: `--msaa N`, `--scale N` (percent), `--spacing X` (grass density), `--night`,
`--no-bench`, `--windowed`. `--help` lists them all.

## Layout

- `src/land.zig`: the place (ground shape and colour, where grass grows, stones, plants, pond,
  tree).
- `src/mesh.zig`: every shape, built from rules (no model files).
- `src/player.zig`: movement and camera, with everything about feel in `Feel`.
- `src/scene.zig`: drawing (light per vertex, haze, grass that clears a path between the camera and
  the creature).
- `src/main.zig`: controls, loop, benchmark, session log.
- `src/math.zig`, `src/noise.zig`: vectors, matrices, repeatable noise.
- Shared platform code is in `../common/`.
- Unit tests: `zig test src/player.zig` and `zig test src/mesh.zig` (run by `build.sh`).
