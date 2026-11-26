# gameguy

An original musical game for two R36S-clone handhelds. What the game is: `design/the-game.md`, then
its parts two and three, `design/the-depths.md` and `design/the-wormhole.md`. The order it gets
built in: `ROADMAP.md`. How its engine is shaped: `docs/engine.md`. What the build does today:
`PROGRESS.md`.

## The direction

On 2026-11-26 Morgan said of those three documents: "this is absolutely 100% the direction".

- Read them in order. A later part corrects an earlier one, and each correction is marked where it
  stands.
- `the-game.md`, "What is sure, and what is still a bet", says which parts his hands and ears have
  tested and which are still bets. Anything marked a candidate or a proposal is to be tried, not
  built as settled.
- `the-game.md`, "What the older notes had, and where each stands", gives the status of every piece
  of the older design: kept, changed, dropped, or open. Open means not decided: ask Morgan.
- Morgan decides what the game is. His word in a session outranks every file.

## Which source wins

1. Morgan, in the session.
2. `design/the-game.md`, `design/the-depths.md`, `design/the-wormhole.md`.
3. Measured facts: `docs/hardware-target.md`, the room's logs and takes in `game/results/`, the
   toys' measurements.
4. Morgan's own words, as material: `material/`, his answers inline in `SCRATCH.md`, the poem
   (Appendix A of `r36s-game-brainstorm.md`), his answers in the room.
5. History: `SPEC.md`, `spec/`, `DECISIONS.md`, the rest of `design/`, `r36s-game-brainstorm.md`.
   Each says at its top what of it the direction keeps. Where history disagrees with the direction,
   the direction wins. Never cite history as a decision.

## The build is not the design

- The code in `game/` was built to `SPEC.md` (2026-11-19 to 23). Its comments cite `SPEC.md`,
  `spec/` and older design documents; those are history now. Building the direction is the work
  ahead, in the order `ROADMAP.md` gives: nine legs, numbered 0 to 8, each a list of numbered
  steps. Leg 0 makes the world solid before anything is built on it.
- On 2026-11-26, after his first go on the try-out, Morgan said: "in order to fully feel what this
  game could be and feel the world... we just gotta build the damn thing eh?" So the build goes
  forward along the road without waiting for a verdict on each step. Each step still goes in alone,
  is measured, and reaches the purple playable, and what his hands and ears say can change anything
  after it. Building a thing does not make it tested: `the-game.md`, "What is sure, and what is
  still a bet", still says which parts are.
- `ROADMAP.md` gives the order and never says what the game is. Where it and the direction
  disagree, the direction wins and the roadmap is corrected. What stands in for each of Morgan's
  open calls until he makes it is in the roadmap's "Morgan's calls".
- `docs/engine.md` is the engine's shape, with the audit of 2026-11-26 it answers. Its technical
  calls are Claude's to make and explain. Measured facts outrank it, and it never says what the game
  is.
- Before saying what the game does, run it and read the path in the code. "Done" in `PROGRESS.md`'s
  older entries meant done as a work order described it, not reachable by playing.

## The hardware, measured (`docs/hardware-target.md`)

- RK3326: four Cortex-A35 cores, 918 MiB of memory, 640×480 at 58.46 or 60.02 Hz, one mono speaker.
- Three cores for the game; the fourth takes the storage interrupts.
- One core renders about 2,100 overtones in half a 2.67 ms sound buffer.
- Each render pass costs a fixed amount: three passes at most.
- Build against the purple (unit 164). It throttles harder. It is JJ's.
- Never touch the black (unit 134) while Morgan is testing on it.
- Never switch a port's 5 V on with a computer on that port.

## Commands

```
game/build.sh                                         # tests, laptop build, handheld build, pack
game/build.sh dev                                     # the laptop build only
game/build.sh handheld                                # the handheld build only, into game/dist/
probe/tools/r36s.sh list                              # which handhelds are connected
probe/tools/r36s.sh push 164 game/dist/ports/ /roms/ports/
probe/tools/r36s.sh run 164 /roms/ports/Gameguy.sh    # run it on the handheld's screen
probe/tools/r36s.sh pull 164 /roms/ports/gameguy/results/ game/results/
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy game/build/gameguy-x86_64 --headless --dump DIR
game/build/ears FILE.wav                              # roughness of a sound (48 kHz input)
python3 spec/tools/wrapmd.py FILE FILE                # wrap a document to 100 columns
```

- The try-out of the direction's first step runs with `--chords`. On the purple it is its own Ports
  entry, `GameguyChords`, with its own program and start; the game beside it is untouched.
- Zig is at `.tools/zig/zig`. `.tools/` is never committed.
- `spec/tools/promises.py` and `spec/tools/check_numbers.py` belong to the retired specification.
  The build still runs `promises.py --zig` to write the list the game's witness code reads. Don't
  extend either.

## Rules that are easy to break

- **Maximal, not minimal.** Morgan: "I don't want anything to be held back just for the sake of
  optimization". Never present smallness as a virtue.
- **Solid things hide and stop.** Morgan, 2026-11-26: "objects in the world shouldn't be
  see-through/clippy right?" A thing is a strand of light or a solid. A solid hides what is behind
  it and is never passed through, by Hum or by the eye (`docs/engine.md`, 7 to 10).
- **One way of reacting.** Morgan, the same day: the way the world's parts react must be
  "canon/shared/modular" and "established and solid". A kind of thing is data made from the shared
  reactions. No kind gets code of its own (`docs/engine.md`, 4 to 6).
- **Never start the game with a window by accident.** Every run from a session takes
  `SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy` and `--headless`. `--help` starts the game.
- **Never call a thing done, or written, that isn't.**
- **Nothing rests on rumble, a microphone, or two unlinked speakers.** There is no motor.
- **Thumbs.** Nothing may need the right stick and a face button at once. Before calling a control
  done, name the digit that performs each of any two things done together.
- **The same on every machine.** Never fuse a multiply and an add; maths from Zig's own library; a
  float remainder only by a power of two; the world never reads a clock. Run the same-take test.
- **It must sound good.** Consonant by default; roughness brief and going somewhere. Claude can't
  hear: measure with `game/build/ears`, and ask Morgan.
- **Every cue has a sound and a light.**
- **Music theory must be right,** with ratios or cents shown when it matters, and stated at exactly
  the size it is true.
- **Morgan's own layer stays his:** the name of the game; who the vine is, who sat on the pool's
  edge and in the chair; who first sings the third with Hum; the odd and even passage.
- **Never estimate how long work will take, and never trim scope to save effort.**
- **Don't stop while work is still owed.** Ordinary obstacles are yours to work through.
- **Needs his word first:** anything on the black while he is testing on it; changing the
  repository's visibility; switching a port's 5 V on; anything that would erase a card or a unit's
  storage.

## Working

- Commit and push each finished step. Keep `PROGRESS.md` true: it says which steps of the road are
  in, by number.
- Every few tool calls, one line on where things stand.
- Documents are in plain words, wrapped at 100 columns. A number is either measured, with its
  source, or marked as an estimate.
- A new idea goes into the direction marked as a proposal until Morgan says yes; his yes is quoted
  where it lands. A correction to the direction is marked where it stands, as the three parts do.
