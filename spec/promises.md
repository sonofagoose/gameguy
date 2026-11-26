# The promises

> **Status, 2026-11-26.** History: part of the promise book, retired as a frame on 2026-11-25
> (Morgan: other models "treated the experiments as settled commitments and built process machinery
> on top of them"). The build still runs `spec/tools/promises.py --zig` to write the list the game's
> witness code reads; nothing else uses it. Don't extend it. What the game is: `design/the-game.md`.

_Part of the specification (`../SPEC.md`, section 21). Morgan, 2026-11-19: "would be wise to have
something in place to make sure that all these wonderful specs/claims/ideas actually get implemented
in a way that results in a human actually experiencing the claim/idea at its fantastical maximum",
and then: "a promise tracking guard that dynamically works for every claim/description/design". This
file is that guard: how every sentence of the specification becomes a claim without anyone listing
it, how a claim is sized, what proves it, and what the build refuses. Where everything stands today
is in `promises/BOARD.md` and `promises/CLAIMS.md`, which the build writes._

## Four ways a line gets lost

A line in a specification can fail to reach a person in four ways. Each has its own guard.

| how it is lost | the guard |
|---|---|
| **dropped:** it is never built | a tool reads every sentence of the specification as a claim. Nobody lists them, so nobody can leave one off |
| **shrunk:** it is built at a fraction of what the words mean | a promise speaks for each claim, with its full size written as measures a machine checks, and the cheat written down beside it |
| **built and not felt:** it is there at full size and the player walks past it, or it arrives with nothing leading up to it | each promise is staged from four distances, the scripted player has to reach it by playing, and a person holding the handheld is put in it and asked |
| **felt once, then broken** by a later change | every rung is worked out again on every build, and a frame that was looked at is kept and compared with today's |

## Every sentence is a claim

`spec/tools/promises.py` reads the game's own documents: `SPEC.md` sections 4 to 15, and `laws.md`,
`world.md`, `people.md`, `size.md`, `years.md` and `together.md`. Every sentence, every row of a
table and every item of a list in them is a claim.

- **Nothing is listed by hand.** Write a new line in any of those files and it is a claim on the
  next build, open until a promise speaks for it. Change a line and the old claim is gone and a new
  one is open. Add a document to the tool's list and all of it is read.
- **A claim is in one of three states.** **Open:** no promise speaks for it. **Spoken for:** a
  promise quotes it. **Kept:** every promise that quotes it is kept.
- **A claim belongs to a stage** by the section it is in, until a promise that quotes it says
  otherwise.
- **`promises/CLAIMS.md`** has every one of them, by document and section, with its state.

The older design documents that the specification says still stand (`design/the-wheel.md`,
`design/together.md` and the rest) are not read sentence by sentence, because parts of them were
replaced. When a stage begins, each one it names is read through, and every line that still stands
is written into a file in `spec/`, where the tool then tracks it.

## A promise speaks for claims

An entry in `promises/` has:

- **an id** and a title;
- **Said:** the file, and the words it speaks for, each in quotes. One promise can quote many
  sentences. The tool finds each quote in a sentence of that file and refuses the entry if it can't,
  so a promise can't drift away from the text;
- **Stage:** the stage that owes it;
- **The moment:** what the person does, sees, hears and feels when it is at full size, in the order
  it happens;
- **Far, at its foot, inside, after:** the same thing from four distances (below);
- **A cheat would be:** the smallest thing that could be called this and isn't;
- **Full size:** the measures, each one checked by a machine or marked as owed;
- **Scene:** where the walk puts a person, if it can yet;
- **Asks:** one question, answered yes or no by a person holding the handheld.

## Sizing: be maximal

Sizing is a design act, done with attention, at the start of the stage that owes the claim. The full
size is not what would be reasonable. It is what the words mean. Three questions:

1. **Literally?** What is it if the words are exactly true? The world is one to a hundred
   (`size.md`): a real aster is 0.9 to 1.85 m, so an aster is 90 to 185 m, which is the height of
   the tallest cathedrals ever built.
2. **By the laws?** What do the seven laws make it do that nobody listed? A tower that tall is far
   away at its own top: a call takes almost three seconds to climb it, and its bells are heard as
   late again.
3. **In time?** How long does it take to reach, to cross, to climb, to hear? Size on a small screen
   is felt as time.

Then four distances, because a thing is met as an approach:

- **Far:** what calls you to it from across the land, in light and in sound.
- **At its foot:** its size against yours.
- **Inside:** what it is when you use it: climb it, enter it, play it.
- **After:** what it changed, in the world and in you.

Then the cheat is written down on purpose, so the build can be held against it.

## The rungs

| rung | what it means | who or what sets it |
|---|---|---|
| sized | its moment, its cheat, its full size and its question are written, and its quotes are found | the builder, before the stage begins; Morgan edits |
| proven | every measure passes in today's build, and nothing is owed | the build |
| reached | the scripted player gets there by playing, and it happens | the build |
| felt | a person holding the handheld was put in the moment and answered yes | Morgan, JJ, anyone: the walk |
| graded | a reader with fresh context held the frames, the numbers and the take against the words and found no shrink | a fresh reader, at the stage's end |
| **kept** | all of them, today | the tool |

Only kept counts. A promise with no question for a person says why, and then needs no hand.

## The measures

Each line under **Full size** starts with one of these:

| measure | what it checks |
|---|---|
| `fact KEY >= N` | a number the game reports about itself in the scripted take (`game/tools/same_take.zig` prints them), or that a handheld's log reports |
| `test NAME` | a test of that exact name exists in `game/src/`; the build fails if any test fails |
| `take` | the scripted player met this moment by playing: the world itself records a witness when its conditions hold (`game/src/world/witness.zig`) |
| `frame NAME` | today's build dumped that frame, and it matches the copy in `promises/seen/` that was looked at, with the weakest thing seen written beside it in `promises/seen.md` |
| `owed` | something the full size needs that isn't built. While one stands, the promise is not proven |

## Frames are looked at, and kept

A frame only counts when someone has looked at it with the promise's words beside it and written
down the weakest thing in it. The copy that was looked at is kept in `promises/seen/`. If today's
build draws something else, the rung falls until the new frame is looked at. Morgan can open that
folder and see what each promise looked like on the day it was judged.

## The walk

The walk is the first part of the room on the handheld (Ports, GameguyRoom). It asks who is holding
the handheld, and then, for each promise whose scene exists:

1. it names the promise in one line;
2. it puts you in the moment with your own hands;
3. when you come back, it asks the promise's one question. A is yes, B is no, Y takes you back in.

It logs the answer, who was holding the handheld, and what the hands did: whether the moment
happened, how long you stayed in it, how often you called. A person who walks past a cathedral
without stopping has answered too.

## Attention

A take is a list of hands, so any take can be replayed to see where a person went and where they
stopped. For each promise and each person, from their own takes: **met** (its witness fired),
**stayed** (for how long), **came back** (on another day), **kept** (they kept that take at the
river). This needs takes, which stage 1 builds. Until then the walk's log lines carry it.

## What every land owes, besides its own claims

- **Something calls you from everywhere.** From the middle of every piece of the land, at Hum's
  height, something not yet found is in sight or in earshot. The score tool measures it for every
  piece.
- **It is as big as a country.** A run straight across takes at least five minutes (`size.md`).
- **Every piece is seen.** Frames from every piece at noon and at 2am. A machine checks all of them
  for emptiness and for clutter; a reader looks at one in twenty, and at every one a machine flags.
- **Every sound in it has a yes** from the room.

## A stage begins and ends

- **It begins** when every claim it owes is spoken for by a sized promise. `--open N` lists the ones
  that aren't.
- **It ends** when every claim it owes is kept. `PROGRESS.md` can't call a stage done before that:
  the build refuses it.

## What the build refuses

- A promise that quotes words no sentence of the file holds.
- A promise without its moment, its cheat, its full size or its question.
- A measure that names a test that doesn't exist.
- A section of the specification that no stage owes.
- A stage marked begun in `PROGRESS.md` while one of its claims is open.
- A stage marked done while one of its claims is not kept.
- An atlas that no longer counts twelve lands, twelve great instruments, 144 wonders and 96 lives.

## The ear, before and after

The largest claim is about the person, not the world: after the thirteenth morning they can hear
things they could not hear on the first evening. So the room measures it. Before the first evening,
and again after the thirteenth morning, it plays pairs of sounds and asks with no words which one is
home, which pair is still, which note is the same. The smallest difference a person can tell, before
and after, is two numbers. `promises/whole.md` has it as `whole.ear`.

## The fresh reader

A reader with no other context grades each stage's promises: its words, its moment, its cheat, its
frames and its numbers. `--packet N` writes all of that into one file. The reader never sees the
code and never fixes anything.

```text
You are grading a game against its own promises. For each promise:
1. Read what the specification says, the moment, and the cheat.
2. Look at its frames and its numbers.
3. Answer: is this the promise at full size, or the cheat, or something between?
   What would a person holding the handheld feel here? What is the weakest thing?
4. Give one verdict: full, short (say by how much, and why), or cheat.
You are looking for shrink. The builder wants to hear "short". Do not be kind.
```

A verdict goes into `promises/graded.md`. Only "full" sets the rung.

## Commands

```
python3 -I spec/tools/promises.py            # read every claim, check every promise, write the board
python3 -I spec/tools/promises.py --open 2   # the claims of stage 2 that no promise speaks for yet
python3 -I spec/tools/promises.py --show ID  # one promise, the sentences it speaks for, each rung
python3 -I spec/tools/promises.py --packet 2 # what a fresh reader needs to grade stage 2
game/build.sh                                # runs it, and fails on anything it refuses
```
