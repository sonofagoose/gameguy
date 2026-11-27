# Progress

Where the build stands, so a new session can pick it up. Newest first.

## Now (2026-11-27)

### The direction

- **What the game is:** `design/the-game.md`, `design/the-depths.md`, `design/the-wormhole.md`.
  Morgan, 2026-11-26: "this is absolutely 100% the direction".
- **The order to build in:** `ROADMAP.md`, written 2026-11-26 at Morgan's asking: "we just gotta
  build the damn thing eh? let's build out an exhaustive development roadmap". Nine legs, numbered
  0 to 8, and 122 numbered steps, from the build as it stands to the whole game. The build goes
  forward along it without waiting for a verdict on each step; each step still goes in alone and is
  measured.
- **How the engine is shaped:** `docs/engine.md`, written the same day at his asking ("audit and
  design the ultimate engine shape for this endeavor"). Leg 0 of the road builds it.
- **Steps of the road that are in:**
  - **0.1, the music as its own module** (2026-11-26): `game/src/music/`. The note as fifths,
    thirds, sevenths and octaves; the wheel's twenty-four cells; the day, its ring of seven chords,
    the faces of places and every cell's chord tuned against Hum's note; what stays and what moves
    in a change of chord; the four ways home. `direction.zig` is the arithmetic of the three design
    documents as 26 tests. 52 new tests, 159 in all. Nothing in the game uses it yet.
  - **0.2 and 0.4, begun** (2026-11-26): shapes, and the first things that hide.
    `game/src/form/shape.zig` is one description of a solid thing (a stalk, a plate, a ball), and
    `game/src/draw/black.zig` makes the triangles that hide from it. The hose, the reeds and the
    spigot each say their shapes once, in their own rules files, and now hide what is behind them;
    the reeds' stems are drawn along the edges of those same shapes. Hum's figure hides too, from
    the outline its lines are drawn on (`draw/hum_figure.zig`), through a second list for what
    moves. Depth is 24 bits. On the scripted run the garden draws 22,633 lines and 6,496 black
    triangles at most, where it drew 22,063 and under 4,000 (laptop). 168 tests. Not yet: Drip, the
    bee, the fallen flower head and the knots; the asters' shapes still come from their own code;
    the rule that fades what is near the eye is still on (it goes with step 0.7); nothing is
    measured on the purple.
  - **0.5, everything solid stops** (2026-11-26): `game/src/body/` (a solid has sides, a top and
    an underside; a grid finds the ones near), `game/src/place/garden.zig` (the Garden's 1,900 or so
    solids, made once from each kind's own shapes) and `game/src/world/footing.zig` (the one routine
    that stops a step, finds what Hum stands on and what is over its head, and the one table of what
    each kind sounds like when touched). The seven functions that each stopped Hum at one kind of
    thing are gone from the rules. New: Hum lands on the hose and stands a bore above the ground,
    jumps from there, and falls off its side; a crumb is a drum to step or jump onto; a cushion of
    moss is walked over; a head meets the underside of what is above it. Hum now comes a few
    centimetres nearer to round things than before, because it is a round body against round
    things and no longer a circle against circles. 178 tests. The scripted run costs the same on
    the laptop (0.87 ms of work a frame).
  - **0.8 and 0.9, the world answering the chord** (2026-11-26 to 2026-11-27): the law, the
    shaders, the Garden's tags, and risen-leaf footing are all in and measured. In:
    `game/src/feel.zig` (first-guess measures); `game/src/law/standing.zig` (what each of the twelve
    colours is to the chord); `game/src/law/react.zig` (wake and rest, rise, tilt and wind, land,
    settle, and `moved`); `game/src/music/key.zig` (`cellOf`, `cellFromHz`);
    `game/src/world/harmony.zig` (`step`, `home`, `moved`); `World.react` stepped each step in
    `world/world.zig` (and mixed into `World.fingerprint`); `.leaf` plates lifted into
    `world/footing.zig` when awake fallen leaves rise (supporting Hum on top, bumping Hum's head
    underneath, settling on an amen); `draw/lines.zig` and `draw/black.zig` carrying per-thing
    colour, reaction measures and height through both vertex shaders; `draw/aster_lines.zig` and
    `draw/garden_lines.zig` tagging asters by degree and bell note, fallen flower head by note,
    reeds (`reed_tilts`), grass blades (`blade_tilts`), fallen leaves (`leaf_rises`), and
    clover/moss/crumbs via `covers.cellOf` (pebbles, stopped hose and spigot left untagged);
    `dark.zig` calling `renderer.setReact` each frame; and `--lines` (`main.zig`) tagging all lines
    and black triangles and calling `setReact` each frame. Changed from `docs/engine.md`: the mass
    of things is moved by colour from twelve numbers, not by a row for each body; a row for each
    body is still to come for single movers. **Verified (laptop):** 188 rules tests and 3 ears tests
    pass; full `game/build.sh` passes (100/100 kill tests, `beauty.py`, `ears` rough_share 0.0481 /
    longest 1.88 s, replay and save round-trips; scripted `--scene evening` 1.20 ms/frame work,
    29,023 max lines, 7,951 max black triangles). Frame dumps of `chords-check-0.9.take` (Home ->
    Lift -> Home -> Lean -> Full Close from `stood.save`) visually checked: risen C-leaf and tilted
    G/D blades and reeds move in lockstep with their black shapes.
  - **0.6 and 0.7, parting blades, solid eye, no fade cone, and Mali-G31 60 fps recovery**
    (2026-11-27): `game/src/body/eye.zig` keeps the camera eye as a 0.6 m solid sphere clear of
    Garden solids (in along its line first, then up), wired into `World.clearance` via
    `footing.gatherForEye` (no save-format change; `eye_pull` now interpolated in `dark.zig`
    `Pose`). `game/src/draw/lines.zig` drops the near-eye fade cone (`inCone`, `u_cone`, `v_rel`,
    and `occ_fs` `discard`, restoring hardware Early-Z on both depth-only occlusion passes), trims
    vertex shader work on `measures == 0`, and adds GPU parting (`setParting`, measures in
    `feel.zig`) so thin grass blades (`tilt >= 8`) and their black shapes bend smoothly in lockstep
    around Hum and out of the line of sight while roots stay planted. `--lines` (`main.zig`) calls
    `setParting` every frame. `game/build.sh` gains `test`, `check`, `clips`, `release`
    (`KILLS=100`, routine full builds `KILLS=10`), keeps tracked `design/listen/*.wav` clean unless
    `CLIPS=1`, and pins `push` to unit 164 (syncing `gameguy-aarch64`, `gameguy-chords-aarch64`,
    `same-take-aarch64`, and `room/build.txt`). **Verified:** 194 rules tests (+6 eye tests) and 3
    ears tests pass; laptop `game/build.sh laptop` drops `--scene evening` to 1.03 ms/frame (from
    1.20 ms) and `--lines` 29,996+20,000 tris to 2.94 ms (from 4.67 ms).
  - **Rock impact jolt & step-up polish** (2026-11-27, commit `0a86b51`, from Morgan's hands on
    `4195628`): eliminated four interlocking causes of the Hum/camera jolt and bounce-back on soil
    crumbs ("rocks"): (1) added eased `World.view_run` (`view_run_ease = 0.08`) so `orbitView()`
    no longer snaps `run_back` (3–5 m) and `run_wider` (3–5 deg) in one frame when velocity drops
    on contact; (2) added `solid.steppable()` in `body/solid.zig` so low crumbs/plates (`<=
    step_up`, 0.30 m) let Hum walk smoothly onto their edge instead of acting as brick walls; (3)
    switched `Pose.between()` in `dark.zig` from forward extrapolation to strict convex
    interpolation (`a in [-1, 0]`) so neither Hum nor `eye_pull`/`eye_lift`/`view_run` ever
    overshoots into a rock and snaps back; (4) softened `eye_pull` solid ease (`0.65 -> 0.35`) and
    stopped ankle-high crumbs (`< 1.2 m`) and moss from yanking the sight ray (eye ball still keeps
    0.6 m clear of every solid). 196 rules tests (+2 new rock tests) and 3 ears tests pass;
    `game/build.sh laptop` passes (`1.04 ms/frame` evening, `stood.save` now 389,512 bytes);
    `aarch64` built into `dist/ports/gameguy/`, ready to push to unit 164 and re-verify
    `same-take-aarch64` once back on USB.
  - **Compact Cohesive Whole roadmap & Start/Pause Workbench (steps 1.2 & 1.38 foundation)**
    (2026-11-27): formalized Principle 11 in `ROADMAP.md` (Full-Depth Engine in legs 0–1 -> Compact
    Cohesive 12-Land Whole at Essence Density through leg 6 -> Parametric Scale-Up in Stage C) plus
    the four force-multiplier workbench pillars. Built: (1) `game/src/feel.zig` live runtime bench
    table (`feel.now` with exact current defaults, `reset`, `diffCount`, `formatDiff`) wired into
    `law/react.zig` and `world/world.zig`, plus dev arena helpers (`warpTo`, `setDaylight`,
    `setChordDirect`, `resetCamera`); (2) `game/src/keep/progress.zig` (`v1` plain-text cross-build
    durable progress and bench overrides file `keep/progress.txt`, surviving `World` layout changes
    and never written during active frames); (3) `game/src/draw/pause_menu.zig` + `dark.zig` +
    `main.zig` 4-tab Start/Pause Menu (`SONGBOOK`, `STATUS` with Mali-G31 frame/line/tri/audio
    budgets & live 12-cell Circle-of-Fifths awake strip, `BENCH` with live sliders and 1.8 A/B
    snaps + Corner Telemetry HUD toggle, and `ARENA` with 8 landmark warps, chord/daylight
    switches, trail/ground toggles, and PNG frame snap; opens on `SONGBOOK` first and remembers the
    last active tab; menu D-pad/stick/face inputs read outside `Hands` so `.take` stays unchanged;
    added `--pause-dump DIR` and `--hud`); (4) `game/tools/score.py` upgraded with `--inspect`
    (scale, travel-time, and Mali-G31 line/tri budget report) and `--map OUT.png` (pure stdlib
    top-down map exporter) while keeping `land.zig` output byte-identical. **Verified (laptop):**
    199/199 rules tests (+3 new: `feel.zig`, `keep/progress.zig`, `world.zig` arena/bench) and 3/3
    ears tests pass; full `game/build.sh laptop` passes (`--scene evening` 0.90 ms/frame, `ears`
    0.0481 rough / 1.88 s longest, `beauty.py`, exact replay & 389,512-byte save round-trips, and
    bit-identical `same-take-x86_64` fingerprints `2f2f29db6dcc4db9` / `ce641ebfbf6e128d`); all 5
    headless 640x480 Pause/HUD dumps and Garden map PNG visually verified; `game/build.sh handheld`
    built `aarch64` cleanly (55 s). **Verified & deployed on purple unit 164 (build `7c85272`,
    2026-11-27):** synced `gameguy-aarch64`, `gameguy-chords-aarch64`, `same-take-aarch64`,
    `room/build.txt`, and refreshed `389,512`-byte `tryout/stood.save`. Live `GameguyChords`
    replay (`game/results/gameguy-chords-20261127-104114.txt`): **400 frames, 0 late, locked 60.02
    Hz (16.66 ms cadence), 6.58 ms avg / 8.56 ms worst work, 0.20 ms slowest sound buffer, 0
    refused cues**, 21,747 max lines, 6,940 max black triangles. `same-take-aarch64 10`
    (`game/results/same-take-aarch64.txt`): **77/77 lines bit-identical** to `same-take-x86_64.txt`
    (`minute 10: 2f2f29db6dcc4db9 / 62c4bef2bf9441eb`; `evening end: ce641ebfbf6e128d /
    06edc2cab21434e4`).
  - **1.1, read Morgan's pulled try-out takes** (2026-11-27): decoded `chords-tryout-001.take`
    (136.0 s, 1,392 changes) and `chords-tryout-002.take` (707.5 s / 11.8 min, 12,592 changes) with
    their logs. Key findings for step 1.2 (the bench) and leg 1: in take 2 Morgan split his time
    evenly across all three chords (Lift 31.4%, Home 41.7%, Lean 26.9%), stepped the chord roughly
    every two beats (median gap 1.83 s, 48/113 steps on Drip's tick, 31 throws home off the lean,
    14.5 m peak height, 26.0 m/s peak speed), and knocked past the try-out's Lift/Lean boundaries
    24 times across the two sessions (9 past Lift on L1, 15 past Lean on L2 — his thumb naturally
    reaches for step 1.4's full ring of seven). He used dash/sprint heavily (161 A-taps in take 2,
    median 83 ms), played 139 strikes across chords, studied the R1 wheel (up to 33.5 s held), and
    pressed X (`grab`) and `clap` 0 times. Removing L2's legacy camera-recentre swing in step 1.3
    will clean up all 69 L2 lean presses.
  - **Measured and deployed on the purple (unit 164, 2026-11-27, build `4195628`):**
    - `same-take-aarch64 10` (`game/results/same-take-aarch64.txt`) matches `same-take-x86_64`
      line-for-line across all 10 dark minutes (`world 5c549a2dcf9310f9 sound 62c4bef2bf9441eb`) and
      all 15 evening minutes (`world 6fa6473c453f6da3 sound 06edc2cab21434e4`).
    - `--lines` with all lines/triangles tagged, chord reactions and parting active
      (`game/results/gameguy-20261127-082520.txt`, Mali-G31 at 60 Hz): 9,924 lines + 5,000 black
      tris drawn in 7.44 ms (0/240 late, was 13.17 ms); 19,960 + 5,000 in 10.66 ms (0/240 late, was
      17.76 ms); 29,996 + 5,000 in 13.64 ms (0/240 late, frame 16.66 ms, vs 22.04 ms / 111 late
      earlier today); 29,996 + 0 black tris in 13.36 ms (5,000 black tris now add +0.28 ms vs +4.10
      ms with `occ_fs` `discard`); 29,996 + 20,000 black tris in 16.17 ms (0/240 late, was 25.20 ms
      / 240 late).
    - `GameguyChords` scripted replay (`tryout/chords-check-0.9.take`,
      `game/results/gameguy-chords-20261127-082611.txt`): **399 frames, 0 late, locked 16.66 ms
      (60.02 Hz)** average screen cadence (down from 118/267 late and 24.99 ms earlier today, and
      better than pre-leg-0's 39/1,330 late and 18.57 ms on 2026-11-23), 6.42 ms CPU work/frame
      (worst 7.32 ms; 0 frames over 8 ms), 0.18 ms worst sound buffer (real-time sound yes), 21,747
      max lines, 6,940 max black triangles.
    - **Pulled & backed up from unit 164:** `/roms/ports/gameguy/results/` pulled into
      `game/results/`; `/roms/ports/gameguy/keep/` backed up locally to
      `game/results/purple-keep-20261127/` (untracked). Both `Gameguy` and `GameguyChords` on unit
      164 run clean build `4195628` with refreshed `tryout/stood.save` (previous save preserved on
      unit 164 as `tryout/stood.save.20261123`).
  - **The full build runs to its end again** (`game/build.sh`). It had been stopping since the
    knots were switched off, at a room walk whose start can no longer be reached; such walks are
    now left out of the built room and named (four of them, all among the knots). The retired
    promise guard no longer runs at the end of it.
- **Everything below this section** was built to `SPEC.md` (2026-11-19 to 23), which is history
  now. "Done" in those entries meant done as a work order described it, not reachable by playing.

### What the game does when a person starts it

Looked at on 2026-11-25 by running the laptop build headless and reading the code (part four of
`design/brainstorm-2026-11-25.md`). The game's rules have not changed since `1b576b6` except for
the try-out below, which is off unless asked for.

- **In it:** the opening as a page in the dark (two drops, the call, Drip answering, four breaths,
  "Oh. You're in.", the page standing up); Drip riding on Hum's head, asleep after two quiet bars,
  leading over the hose's coil to the great aster and then to the first puddle, and then nowhere;
  running, sprinting, skidding, a 3 m jump with a short hop on a tap, the dash; the garden (asters,
  reeds, covers, the stopped hose with its held tone, the spigot, the bee, four puddles you can
  walk across, the sky); the strike, which plays home's chord a note at a time, fuller on the tick;
  the swell on R2, a voice a bar, with L1 and L2 stepping home in it; the wheel on R1, drawn on top,
  where only two cells can be chosen (C, and the F to its left); the clap; the songbook; the view
  all the way up to the page; takes and saves.
- **Not in it:** any knot (`initEvening` sets `knot_count = 0`, since `81d9b1e` on 2026-11-22), so
  no fight, no dodge and nothing to bring home; the hose can never open, because it needs every
  knot home; dusk, the river and night; anything pulled by home; the wheel's other cells;
  underneath; the island.
- **Tests:** 107 pass (`game/build.sh`), two of them for the try-out. Seven older tests switch knots
  or cells on by hand, so they test a game that can't be reached by playing.

### What the audit of the engine found (2026-11-26)

Run with no screen on the laptop and read in the code; the whole of it is in `docs/engine.md`.

- **See-through:** only asters nearer than 230 m and the ground's covers have black shapes. The
  hose, the spigot, the reeds, Hum, Drip, the bee and the knots have none, and nothing that moves
  can hide anything. On a scripted run the garden picks about 20,000 lines and under 4,000 black
  triangles, with 2 or 3 of its 68 asters near enough to hide. A rule also makes whatever is near
  the eye see-through on purpose: switched off, it changes up to 5.2% of a frame. The 16-bit depth
  buffer is a small part: 0.3% to 0.4% of a frame.
- **Walked through:** solid means a circle on the ground, written once for each kind. Nothing has a
  top or an underside, blades are let through by rule, and the eye is kept clear of the ground only.
- **Reacting:** things answer sound in one shared way (sympathy, kin, the ring of a call), and that
  stays. Nothing answers the chord in a shared way: the chord is one frequency, and each kind of
  thing is its own code.
- **Sound, the clock, takes, the lines themselves:** right, and staying.

### The try-out of the direction's first step

- **What:** L1 and L2 step the chord among the lift (F), home (C) and the lean (G) wherever Hum is.
  On the lift Hum is light (a held jump reaches 5.2 m), on the lean he runs 1.3 times as fast, and
  stepping home off the lean throws him forward. What is kin to the chord near Hum lights and the
  nearest four answer. Commit `90458c2`; `chordStep` and `wakeKin` in `game/src/world/world.zig`,
  behind `--chords`. Its numbers are first guesses for Morgan's hands.
- **Where:** on the purple as its own Ports entry, GameguyChords (`game/port/GameguyChords.sh`,
  `gameguy/gameguy-chords-aarch64`, its start in `gameguy/tryout/stood.save`). It keeps a take in
  `results/walks/` named `chords-tryout`. Select and Start together leave.
- **Measured:** on the laptop, a scripted run is rough 16% of the time against 12% with the try-out
  off; on the purple 39 of 1,330 frames late with 6.04 ms of work a frame
  (`game/results/gameguy-chords-20261123-225843.txt`; the unit's clock is wrong).
- **Played:** by Morgan on 2026-11-26: "played GameguyChords for a minute... kinda see what you're
  saying about how the lift/lean can be used as actual player
  mechanic/movement/interaction/physics". His two takes and session logs were pulled from unit 164
  on 2026-11-27 (`game/results/walks/chords-tryout-001.take` + `gameguy-chords-20261124-062745.txt`,
  6,576 frames; and `chords-tryout-002.take` + `gameguy-chords-20261124-154946.txt`, 34,202 frames,
  113 chord steps, highest 14.5 m, fastest 26.0 m/s): reading them is step 1.1 of the road.
- **Not yet:** as the direction now has it, L2 past the lean walks on into the caves and L1 past
  the lift crosses the seam (`the-depths.md`); the try-out stops at the lean and the lift.

### On the handhelds

- **The purple (unit 164):** updated 2026-11-27 with build `4195628` (leg 0 through steps 0.6, 0.7,
  0.8 and 0.9) for both `Gameguy` (`gameguy-aarch64`) and `GameguyChords`
  (`gameguy-chords-aarch64` with refreshed `tryout/stood.save`; previous `stood.save` preserved as
  `stood.save.20261123`). Clock synced, `same-take-aarch64` matched line-for-line, `--lines` and
  scripted `--chords` verified at locked 60.02 Hz (0 late frames). The page, wheel and remainder
  toys remain untouched.
- **The black (unit 134):** not looked at since 2026-11-21. Never touched while Morgan is testing
  on it.

### Waiting on Morgan

- His ears on sketches j, k, l and m (`design/listen/sketches/`).
- His hands on the updated 60 fps `GameguyChords` on unit 164 (solid eye, parting grass blades,
  risen leaves, tilting blades/reeds and chord-lit asters/covers).
- The calls the direction leaves to him. `ROADMAP.md`, "Morgan's calls", lists each with the step
  that reaches it and what stands in until he says. None of them stops the road.

### Next

Step 1.2 (the pause-menu bench for `feel.zig` numbers, informed by step 1.1's try-out analysis) and
step 1.3 (making `--chords` the default game and removing L2's legacy camera-recentre swing), along
with the remaining leg 0 cleanup steps (0.2/0.4 black shapes for Drip/bee/fallen head, 0.10 touches
& mix, 0.11 split).

## Piece 5 — Drip's Metronome Balance, Bar-Centric Timing & Procedural Animations (2026-11-23)

Work order Piece 5: Metronome Auditory Balance, Bar-Centric Timing, Sleep/Wake Cycle, Procedural
Droplet Animations, and Separation of Concerns Architecture.

| piece | state |
|---|---|
| Separation of Concerns | done: extracted Drip domain logic into `game/src/world/drip.zig` and drawing into `game/src/draw/drip_lines.zig`; removed 104 lines of embedded drawing out of `game/src/dark.zig` |
| Bar-Centric Timing | done: all timers/cooldowns expressed in musical Bars and Beats (1 Beat = 50 steps $\approx 72\text{ BPM}$, 1 Bar = 4 Beats = 200 steps); timing is tempo-invariant |
| Auditory Balance & Sleep Cycle | done: Drip sleeps and silences metronome audio after 2 bars of peaceful exploration (`sleep_after_bars = 2`); wakes immediately on R2 swell, R1 wheel, or knot threat |
| Procedural Animations | done: 16-segment living droplet contour, launch stretch ($1.35\times$), landing squash ($1.28\times$), sleeping nightcap slump, inner liquid glint, and directional guidance lean |
| Verification | done: all 105 unit tests pass, including 3 dedicated Drip state & bar-centric timing unit tests |
| Handheld build | done: built `gameguy-aarch64` into `dist/ports/gameguy/gameguy-aarch64`, ready for push to purple R36S unit 164 |

## Piece 4 — The Wheel as the True Circle of Fifths (2026-11-23)

Work order Piece 4: Concentric Circle of Fifths with Outer Major & Inner Relative Minor Rings,
Deflection Cursor, Audio Preview, and 68% Background Dim.

| piece | state |
|---|---|
| Outer Major Ring | done: 12 Major keys (F, C, G, D, A, E, B, F#, Db, Ab, Eb, Bb) displayed around circumference at outer radius |
| Inner Relative Minor Ring | done: 12 Relative Minor keys (Dm, Am, Em, Bm, F#m, C#m, G#m, D#m, Bbm, Fm, Cm, Gm) at $k+3$ displayed on inner concentric ring |
| Stick Deflection Cursor | done: half deflection ($0.55 \le r < 0.72$) selects inner relative minor ring; full deflection ($r \ge 0.72$) selects outer major ring |
| Home Commit | done: releasing R1 commits home to relative minor root wedge $eff\_k = foldWedge(k + 3)$ when inner ring selected, or major root $k$ on outer ring; updates home pitch and triad quality (subsequent strikes cycle minor vs major triad) |
| Audio Preview & Clicks | done: entering awake wedge gives pitch click at `wedgeHz(day_hz, eff_k) * 2.0` (dull skin knock if asleep); resting on awake wedge hums preview pitch under Hum's breath |
| 68% Background Dim | done: `wheel_dim = 0.68` dims sky, things, and ground cover while wheel is open |
| Draw on Top | done: wheel lines rendered in top pass (`renderer.setTop`) over all terrain and geometry |
| Verification | done: all 102 unit tests pass, including dedicated Piece 4 circle of fifths deflection cursor & minor/major commit test |
| Handheld build & push | built `aarch64` binary and deployed to purple R36S unit 164 (`10.36.164.1`) |

## Piece 3 — The Strike (2026-11-23)

Work order Piece 3: Wholesale port of GameguyPage strike (`toys/page/src/main.zig` and
`toys/wheel/src/world.zig`).

| piece | state |
|---|---|
| Open-world availability | done: strike active anytime standing in world (`stand >= 1.0`), never gated behind threats or combat |
| Cycling triad chord progression | done: strikes cycle musically through home's triad (Root 1.0 -> Third 1.25/1.2 -> Fifth 1.5 -> Root) |
| Timed & untimed strikes | done: zero input delay; both timed strikes (near beat, fork_octave overtone, brighter glow, 1.25× damage) and untimed strikes (plain fork, 1.0× damage) fire instantly on Y press with ~2 ms kernel latency on the sound thread; no delayed queuing to next beat |
| Removed call circle on strike | done: 360° call circle and ground band illumination suppressed on strike; visual response is strictly the forward ground arc sweep (`strikeLines`) |
| Auto-aim & forward cone | done: auto-faces nearest target within 1.5× reach; forward cone (138° arc, cos(69°) ~ 0.36) hits only targets in front |
| Ground arc sweep animation | done: GameguyPage `groundArc` (16 segments, 126° arc, 3.5 px width, bone + home hue) sweeps 4.95m to 9.0m over 0.2s in place & page views |
| Verification | done: all 8 strike unit tests pass (open-world strike, triad cycling, forward cone filtering, instant timed/untimed strikes, shockwave carries, pocket looper) |
| Handheld build & push | built and pushed to purple unit 164 |

## Piece 2 — The Jump (2026-11-23)

Work order Piece 2: SM64 by way of TotK standard jump (3.0 m height, snappy air time, variable
height, coyote time, landing buffer).

| piece | state |
|---|---|
| Target jump height & timing | done: `jump_height = 3.0 m`, `jump_air_s = 0.68 s` (gravity `fall_pull = 51.9 m/s²`, initial velocity `jump_speed = 17.65 m/s`) |
| Variable jump height | done: target-based early release clamp (`jump_tap_height = 1.55 m`), giving a natural ~100 ms release window where any natural tap reliably produces the ~1.5 m low hop without superhuman timing, while holding scales up to the full 3.0 m leap (Morgan: "amount of time before button release that dictates the shortest hop extended just a tiny bit") |
| Coyote time | done: 6 steps (100 ms) window after walking off an edge (`stood_ago <= jump_late`) allowing a jump press to take flight |
| Buffered landing jump | done: pressing jump while descending near the ground (`hum_y < 1.0 m`) buffers to `jump_wanted` and fires immediately on the touchdown frame |
| Air steering | done: `air_ease = 0.20` generous TotK style air control |
| Verification | done: tests verify held 3m jump, tap 2m hop, edge coyote jump, obstacle clearance over 1.8m hose |
| Purple handheld push | ready for push to purple unit 164 |

## Piece 1 — The page at the top of the dial (2026-11-22)

Work order Piece 1: Continuous fold from 3D place into 2D top-down page at dial top (`orbit ==
1.0`).

| piece | state |
|---|---|
| Continuous dial fold | done: right stick down transitions world continuously from place to page (Paper Mario / GameguyPage style) |
| Camera distance tightened | done: walking distance pulled in to 11m sweet spot (was 15m, originally 22m) for character-centered immersion, scaling out to 52m at dial top |
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

## Morgan's first room session, synthesis and actionable vision (2026-11-21)

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

## The specification's plan, retired on 2026-11-25

Kept as it stood on 2026-11-21. It is not the plan: the plan is under "Now" at the top.

### Its next steps

1. Morgan reads and edits `SPEC.md`, `spec/size.md`, `spec/years.md`, `spec/together.md`,
   `spec/sky.md`, `spec/shape.md` and `spec/texture.md`, and
   runs GameguyRoom on the purple (or the black, once the game is put on it).
2. Pull the room's log and read every `room:` line; fold the answers into `docs/hardware-target.md`
   and the specification.
3. The build goes on from stage 1, in a session opened with the brief in `SPEC.md`, section 22.
   Stage 2 begins by sizing a promise for each of its open claims
   (`python3 -I spec/tools/promises.py --open 2`).

### Its stages

| stage | state |
|---|---|
| 1. the workshop and the engine | begun: see `game/README.md` for what is in and `spec/stages.md` for what the stage still owes |
| 2. the first evening and the Garden, finished | begun: the rows above marked stage 2 |
| 3. going out, mornings 2 to 7 | not started |
| 4. the way home, mornings 8 to 12 | not started |
| 5. the thirteenth morning and after | not started |
| 6. two consoles | not started |
| 7. the book, lent voices, and release | not started |
