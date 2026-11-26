# The stages

> **Status, 2026-11-26.** History: the specification's stages and their proofs, retired on
> 2026-11-25. The order to build in now is `design/the-game.md`, "Where the game stands, and what I
> would build first", and `PROGRESS.md`.

_Part of the specification (`../SPEC.md`, section 20): what each stage builds, and what proves it. A
stage is done when its proof has been shown, not when its work looks finished. `../PROGRESS.md` says
which stage is live._

## Every stage begins the same way

`python3 -I spec/tools/promises.py --open N` lists every sentence of the specification that the stage
owes and that no promise speaks for. Each gets a promise before anything is built: its moment, its
cheat, its full size, its question (`promises.md`). The older design documents the stage names are
read through then, and every line of them that still stands is written into a file in `spec/`.

## Every stage ends the same way

1. `game/build.sh` from a clean checkout: tests pass, both builds are made, the port is packed.
2. The scripted player plays everything built so far, with no screen, and nothing is written to the
   error stream.
3. Frames from every place and state are dumped, looked at, and the weakest thing seen is named and
   fixed. That is repeated until the weakest thing is small.
4. `game/tools/ears` has run on every new sound, and nothing is rough outside the moments `laws.md`
   lists.
5. The same-take test gives the same fingerprints on the laptop and the purple.
6. A session on the purple has been logged: every frame on time, no gaps in the sound.
7. Everything is committed and pushed, and `PROGRESS.md` is true.
8. A reader with fresh context has graded each of the stage's promises against its words, from
   what `promises.py --packet N` writes. That reader grades and does not fix.
9. Morgan has played it, and his answers in the room have been read.
10. Every claim the stage owes is kept, and `spec/promises/BOARD.md` says so. The build refuses a
    stage called done before that.

## Stage 1: the workshop and the engine

**Builds:**

- `game/build.sh`, the launcher, the headless run, frame dumps, the pack for Ports.
- Time by the sound card's count; hands stamped in samples; takes written and replayed.
- The world's plain state, the step, the cue type that needs both a sound and a light.
- The bank, the strikes, sung voices, late arrivals, the room's tail, the end of the chain.
- Lines on the GPU in pieces, black shapes, the three passes, the hinge, the backlight.
- Pieces read from the card as Hum walks; the score tool, with one test land.
- The scripted player's first skills: walk, call, breathe with a tick.
- `ears`, `same-take`, `room`.
- The ground: one picture for each piece, drawn under the lines and loaded as Hum walks
  (`size.md`).
- Every thing its own shape, kept on the card and loaded at a run.

**Proof:**

- A test land of bells, strings and a pool, walked from end to end on the purple with every frame on
  time, at least the number of lines the atlas needs in view, and 1,000 overtones sounding. (So far:
  a field of 70 asters as tall as cathedrals, walked with none of 2,398 frames late and 18,055
  lines at most.)
- The ground's light drawn under it, with pieces loading as Hum walks, every frame on time.
- A dawn's save kept and opened again a hundred dawns later.
- Ring one bell and its kin answer, in sound and in light, late by their distance.
- A take of that walk replays to the same fingerprints on the laptop and the purple.
- A save made in the middle and loaded again reaches the same end.
- Hum's voice starts within two buffers of the button, shown by the stamps.
- The numbers `SPEC.md` section 18 lists as "to be measured" for this stage are measured and written
  into `docs/hardware-target.md`.

## Stage 2: the first evening and the Garden

**Builds:** everything in `SPEC.md` 6.1, and the whole of the Garden in `world.md` and `people.md`.

- The dark, the call, Drip, "Oh. You're in.", the page standing up.
- All seven laws, each met once in the Garden's first seven wonders; then the other five.
- The wheel with two moods awake; the swell; the full close and the amen; the first walk.
- The fork, the dodge, the pocket, the afterimage, the clap; knots; Gentle and Fierce.
- The Hose, with the Great Knot inside it.
- The Garden's eight lives, each with its three wants and its ties (`years.md`), and its morning
  song growing as they join.
- Being them: a morning as Pill, as Snail, as Moss, as the Ants.
- The Garden at its size: about three square kilometres, every thing its own shape, the ground
  keeping light.
- Dusk: the river's song, keeping takes, Repeat and Onward, the post.
- A second morning: your echo beside you, flat and blue; a gate that wants two of you.
- Sitting and listening; the fly; the songbook's first pages; the almanac.
- The book on the card: a page a day.

**Proof:**

- The scripted player plays the first evening, a Repeat and a second morning, frees the Hose, helps
  all eight lives and finds all twelve wonders.
- Each wonder's truth is a test that passes.
- Morgan plays the first evening on the black. His answers in the room on: being answered in the
  dark; the page standing up; the puddle bridge; whether a timed strike feels like power; whether
  the wheel earns its place in a fight; the river; walking beside himself.
- Every sound in the Garden has his yes.

## Stage 3: going out, mornings 2 to 7

**Builds:** the Alfalfa, the Glass Hills, the Bell Meadow, the Highway, the Chrome Nave and the
Seam, each with its tuning, its eight lives, its twelve wonders and its great instrument.

- Box Elder, Doorstop and Patio; drive, cool soul, tenderness and fierceness.
- Borrowing; the dark wedges; weather that comes with a borrowed note.
- Packs; wolves and their pups; Greys; the Great Knot's kin.
- The vine, at the Garden and at the Stage; the lean.
- The caravan, Jeanne, the white cat, the black train; trading a take for a note off the wheel.
- Echo walls; the looper outside a fight.
- The lake: the boat, the ferry, the level, the slow wave.
- Dreams; sleep; pools and what each overtone of a pool remembers.
- The Metronome. The Wolf at the Seam.
- One continuous ring from the Garden round to the Seam, with every land's lights seen across the
  water.
- Ties across the lake, and the duets of lives that meet (`years.md`).

**Proof:** the scripted player goes from the first evening to the seventh night; frames from every
land at noon and at 2am; each land's song whole; the Metronome swung; a walk from the Garden to the
Seam on the purple with every frame on time.

## Stage 4: the way home, mornings 8 to 12

**Builds:** the Aster Steps, Verbena Hollow, the Rain Steps, the Reed Mouths and the Porch, as
`design/the-way-home.md` has them and as the atlas adds.

- The garden's note returning, doubled; the two suns.
- Break; the Bell Jar.
- The close that misses; the triangle; the Music Box.
- The cloud; rain that brings back what was let go; Puffball; the Cistern.
- Being the ground; the band fighting for you; the Mouth Organ.
- The eleventh dusk, for any echo: let it go, sing it again, turn away.
- The Porch: the chair, the Guitar, the oldest echo, the night that doesn't close.

**Proof:** the scripted player reaches the twelfth night by each of three paths (keeping everything,
keeping nothing, and something between); each land's song whole; every earned moment of roughness is
brief, resolves, and has Morgan's yes.

## Stage 5: the thirteenth morning and after

**Builds:**

- The thirteenth morning: everyone at the garden, the twelve songs as one, the whole turn in one
  breath, the clap, the step and the hold, and the river's second offer.
- Your own voice: seated, the pad as an instrument.
- Each night: up a fifth, down a fifth, stay.
- The lands by thirds and sevenths, made from their three numbers; songs as places; songs as seeds.
- The long spiral's five gardens.
- The sky and the deep, with the forty octaves as places.
- The islets and the Shimmer.
- The moon, the tide, the brood and its cousins.
- Generations: lives that change into things that keep their tunes, and the lives made after them
  (`years.md`). A thousand made tunes pass `ears`, and no two are alike.
- The book opens any dawn that was kept.

**Proof:** the scripted player takes each ending and comes back by the river; then goes fifty-three
fifths out, by sums, and stands in that garden; a made land is the same on the laptop and the purple
from the same three numbers; a phrase reaches the same land on both.

## Stage 6: two consoles

**Builds:** `together.md`, with `design/together.md` wherever it is silent.

- The treaty by clap; side by side; the parts split across two speakers.
- The cable: one clock, lockstep, a visit, the standing-wave doorway, two homes in one world.
- Drip's seat. Trading fours.
- A world for two, begun apart in the same dark.
- Each other's worlds, kept on the card.
- Letters on a card; the radio that plays them.
- Lent voices.
- The water you share.

**Proof:** two units linked for an hour with no drift heard and none measured beyond a sample; the
cable pulled mid-phrase and nothing lost on either side; both saves agree; the purple hosting as
well as the black; Morgan and JJ on the couch.

## Stage 7: the book, lent voices, and release

**Builds:**

- The book read on the handheld; songs as sound, as notes and as separate tracks; a page at print
  size.
- A laptop player and a web page that play any take.
- The game on its own card, as a cartridge; the port for other handhelds of this family.
- A seeing option; Gentle's wider world; the room's results folded back in.
- Whatever the room found the handheld can do: a headset's microphone, a motor, the breathing
  backlight.

**Proof:** a fresh card, put into a unit that has never seen the game, plays from the first evening;
a take made on the purple plays on the laptop and in a browser to the same fingerprints; the final
report is written for someone who wasn't there.
