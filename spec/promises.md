# The promises

_Part of the specification (`../SPEC.md`, section 21). Morgan, 2026-11-19: "would be wise to have
something in place to make sure that all these wonderful specs/claims/ideas actually get implemented
in a way that results in a human actually experiencing the claim/idea at its fantastical maximum".
This file is that thing: what a promise is, how one is sized, what proves it, and what the build
refuses. The promises themselves are in `promises/`, and where each one stands today is in
`promises/BOARD.md`, which the build writes._

## Four ways a line gets lost

A line in a specification can fail to reach a person in four ways. Each has its own guard.

| how it is lost | the guard |
|---|---|
| **dropped:** it is never built | every promise is on one list, made from the specification's own text; the build counts them |
| **shrunk:** it is built at a fraction of what the words mean | each promise has its full size written down, as measures a machine checks, and the cheat written down beside it |
| **built and not felt:** it is there at full size and the player walks past it, or it arrives with nothing leading up to it | each promise is staged from four distances, the scripted player has to reach it by playing, and a person holding the handheld is put in it and asked |
| **felt once, then broken** by a later change | every rung is worked out again on every build, and a frame that was looked at is kept and compared with today's |

## What a promise is

Every claim in `SPEC.md` and `spec/` that a player is meant to see, hear, do or feel. An entry in
`promises/` has:

- **an id** and a title;
- **Said:** the file and the words, quoted. The tool checks the words are still in the file, so a
  promise can't drift away from the text it came from;
- **Stage:** the stage that owes it;
- **The moment:** what the person does, sees, hears and feels when it is at full size, in the order
  it happens;
- **Far, at its foot, inside, after:** the same thing from four distances (below);
- **A cheat would be:** the smallest thing that could be called this and isn't;
- **Full size:** the measures, each one checked by a machine or marked as owed;
- **Scene:** where the walk puts a person, if it can yet;
- **Asks:** one question, answered yes or no by a person holding the handheld.

Wonders, lives and great instruments are read straight from the atlas (`world.md`, `people.md`), so
none can be left off. The rest of the game is listed in `promises/said.md`, one line each, until its
stage sizes it.

## Sizing a promise

Sizing is a design act, done with attention, at the start of the stage that owes the promise. Three
questions:

1. **Literally?** What is it if the words are exactly true? The world is one to a hundred
   (`size.md`): a real aster is 0.9 to 1.85 m, so an aster is 90 to 185 m, which is the height of
   the tallest cathedrals ever built.
2. **By the laws?** What do the seven laws make it do that nobody listed? A tower that tall is far
   away at its own top: a call takes two and a half seconds to climb it, and its bells are heard as
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
| said | it is in the specification and on the list | the tool, from the text |
| sized | its moment, its cheat, its full size and its question are written | the builder, before the stage begins; Morgan edits |
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

The walk is the first part of the room on the handheld (Ports, GameguyRoom). For each promise whose
scene exists:

1. it names the promise in one line;
2. it puts you in the moment with your own hands, a little before it happens;
3. when you leave, it asks the promise's one question. A is yes, B is no, Y takes you back in.

It logs the answer, who was holding the handheld, and what the hands did: whether the moment
happened, how long you stayed in it, how often you called. A person who walks past a cathedral
without stopping has answered too.

## Attention

A take is a list of hands, so any take can be replayed to see where a person went and where they
stopped. For each promise and each person, from their own takes: **met** (its witness fired),
**stayed** (for how long), **came back** (on another day), **kept** (they kept that take at the
river). This needs takes, which stage 1 builds. Until then the walk's log lines carry it.

## What every land owes, besides its own promises

- **Something calls you from everywhere.** From the middle of every piece of the land, at Hum's
  height, something not yet found is in sight or in earshot. The score tool measures it for every
  piece.
- **It is as big as a country.** A run straight across takes at least five minutes (`size.md`).
- **Every piece is seen.** Frames from every piece at noon and at 2am. A machine checks all of them
  for emptiness and for clutter; a reader looks at one in twenty, and at every one a machine flags.
- **Every sound in it has a yes** from the room.

## A stage begins and ends

- **It begins** when every promise it owes is sized.
- **It ends** when every promise it owes is kept, and the board says so. `PROGRESS.md` can't call a
  stage done before that: the build refuses it.

## What the build refuses

- An entry whose quoted words are no longer in the file it names.
- A wonder, a life or a great instrument in the atlas with no promise.
- A measure that names a test that doesn't exist.
- A stage marked done in `PROGRESS.md` while one of its promises is not kept.
- A stage marked begun while one of its promises is not sized.

## The ear, before and after

The largest promise is about the person, not the world: after the thirteenth morning they can hear
things they could not hear on the first evening. So the room measures it. Before the first evening,
and again after the thirteenth morning, it plays pairs of sounds and asks with no words which one is
home, which pair is still, which note is the same. The smallest difference a person can tell, before
and after, is two numbers. `promises/whole.md` has it as `whole.ear`.

## The fresh reader's brief

Given to a reader with no other context, at the end of a stage, with the board, the promise files,
the kept frames and the scripted take's numbers. The reader never sees the code and never fixes
anything.

```text
You are grading a game against its own promises. For each promise marked proven:
1. Read its words, its moment and its cheat.
2. Look at its frames and its numbers.
3. Answer: is this the promise at full size, or the cheat, or something between?
   What would a person holding the handheld feel here? What is the weakest thing?
4. Give one verdict: full, short (say by how much, and why), or cheat.
You are looking for shrink. The builder wants to hear "short". Do not be kind.
```

A verdict goes into `promises/graded.md`. Only "full" sets the rung.

## Commands

```
python3 -I spec/tools/promises.py            # check every promise, write the board
python3 -I spec/tools/promises.py --show ID  # one promise and each of its rungs
game/build.sh                                # runs it, and fails on anything it refuses
```
