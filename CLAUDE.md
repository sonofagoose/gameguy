# gameguy

An original musical game for two R36S-clone handhelds. What the game is: `design/the-game.md`, then
its parts two and three, `design/the-depths.md` and `design/the-wormhole.md`. What the build does
today: `PROGRESS.md`.

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
  ahead, in the order `the-game.md` gives under "Where the game stands, and what I would build
  first".
- Nothing past the first evening is built until the first evening is whole and Morgan likes playing
  it. Each piece goes in alone, answers one row of the "What is sure" table, and goes to his hands
  or ears before the next.
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

- Commit and push each finished piece. Keep `PROGRESS.md` true.
- Every few tool calls, one line on where things stand.
- Documents are in plain words, wrapped at 100 columns. A number is either measured, with its
  source, or marked as an estimate.
- A new idea goes into the direction marked as a proposal until Morgan says yes; his yes is quoted
  where it lands. A correction to the direction is marked where it stands, as the three parts do.
