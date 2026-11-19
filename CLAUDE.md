# gameguy

An original musical game for two R36S-clone handhelds. Read `SPEC.md` first, then `PROGRESS.md`.

## Which source wins

Morgan in the session, then `SPEC.md` and `spec/`, then `DECISIONS.md`, then `design/`, then the
brainstorm. The toys are not the game.

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
probe/tools/r36s.sh list                              # which handhelds are connected
probe/tools/r36s.sh push 164 game/dist/ports/ /roms/ports/
probe/tools/r36s.sh run 164 /roms/ports/Gameguy.sh    # run it on the handheld's screen
probe/tools/r36s.sh pull 164 /roms/ports/gameguy/results/ game/results/
SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy game/build/gameguy-x86_64 --headless --dump DIR
python3 -I spec/tools/check_numbers.py                # recompute the specification's numbers
python3 -I spec/tools/promises.py                     # read every claim, check every promise
python3 -I spec/tools/promises.py --open 2            # stage 2's claims that no promise speaks for
python3 spec/tools/wrapmd.py FILE FILE                # wrap a document to 100 columns
```

Zig is at `.tools/zig/zig`. `.tools/` is never committed.

## Rules that are easy to break

- **Maximal, not minimal.** Morgan: "I don't want anything to be held back just for the sake of
  optimization". Build what the words mean at one to a hundred and by the laws (`spec/size.md`).
  Never present smallness as a virtue.
- **Every sentence of the specification is a claim** (`spec/promises.md`). Size a promise for each
  before its stage: the moment, the cheat, the full size, the question. A stage is done when its
  claims are kept, and the build refuses it sooner. Never call a thing done, or written, that isn't.
- **Nothing rests on rumble, a microphone, or two unlinked speakers.** There is no motor.
- **Thumbs.** Nothing may need the right stick and a face button at once. Before calling a control
  done, name the digit that performs each of any two things done together.
- **The same on every machine.** Never fuse a multiply and an add; maths from Zig's own library; a
  float remainder only by a power of two; the world never reads a clock. Run the same-take test.
- **It must sound good.** Consonant by default; roughness brief and going somewhere. Claude can't
  hear: measure with `game/tools/ears`, and ask Morgan through the room.
- **Every cue has a sound and a light.**
- **Morgan's own layer stays his:** who the vine is, who sat on the pool's edge and in the chair,
  the odd and even passage.
- **Never estimate how long work will take, and never trim scope to save effort.**
- **Don't stop while work from the stage is still owed.** Ordinary obstacles are yours to work
  through. A boundary in `SPEC.md` section 17 is left alone and reported.

## Working

- Commit and push each finished piece (the push command is in memory). Keep `PROGRESS.md` true.
- Every few tool calls, one line on where things stand.
- Documents are in plain words, wrapped at 100 columns. A number is either measured, with its
  source, or marked as an estimate.
