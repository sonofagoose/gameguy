# The road

> **Status, 2026-11-26.** The order the game gets built in, from the build as it stands to the whole
> game. (Corrected the same day: leg 0 was added. Its first lines say why.) Morgan, that day: "we
> just gotta build the damn thing eh? let's build out an exhaustive development roadmap in whichever
> way you deem most impactful and fun and musical!" This is that roadmap. What the game is stays in
> `design/the-game.md`, `design/the-depths.md` and `design/the-wormhole.md`: where this file and
> they disagree, they win and this file is corrected. What the build does today, and which steps of
> this road are in, stays in `PROGRESS.md`. The order was my call, made at his asking, and it is his
> to change.

_Written by Claude. Before writing it I reread the three parts of the direction in full and read how
the code is laid out and what it holds (`game/`, about 22,000 lines with its tools and tests). I did
not run the game again for it: what the build does when a person starts it is as `PROGRESS.md` found
it on 2026-11-25. The purple was not on the cable, so what Morgan's hands did on the try-out is
still on the unit, unread._

## What this is

- **A road, in order.** Nine legs, numbered 0 to 8. Each ends with something Morgan can pick up and
  play, with more in it than the leg before.
- **Each leg is a list of steps.** A step goes in alone, is measured, and reaches the purple
  playable. Steps are numbered by leg: 1.6 is the sixth step of the first leg.
- **It is not a promise book.** Nothing here is a gate and no tool enforces it. It will be wrong in
  places, and it gets corrected where it stands, as the direction does.
- **It has no dates.** It gives order, and what depends on what. It never says how long.
- **Nothing is cut to fit.** It covers everything the direction holds. "Nothing left out", near the
  end, lists every section of the three documents with the leg that builds it.
- **It does not say what the game is.** Where the road needs something the direction has not
  decided, it says whose call it is and what stands in until then ("Morgan's calls"), and anything
  new of mine is marked as a proposal ("Proposals this road makes").

## What changed on 2026-11-26

Morgan, after his first go on the try-out: "played GameguyChords for a minute... kinda see what
you're saying about how the lift/lean can be used as actual player
mechanic/movement/interaction/physics... it seems after reading the-game.md that I really think in
order to fully feel what this game could be and feel the world... we just gotta build the damn thing
eh?"

- **Until now the rule was mine:** nothing past the first evening would be built until the first
  evening was whole and he liked playing it (`the-game.md`, "What is sure, and what is still a
  bet").
- **His word changes it.** A world can't be felt on paper, or in a try-out of three chords. So the
  build goes forward along this road without stopping for a verdict on each step.
- **What stays.** Each step still goes in alone and is measured. Each leg still lands whole on the
  purple. What his hands and ears say about any of it can change everything after it. And the table
  of what is tested stays honest: building a thing does not make it proven.
- **How I read "kinda see".** It is a first look after a short go, at a try-out where nothing in the
  garden yet needs a chord. I take it to mean the idea shows and is still faint. So the first steps
  of the road are the ones that make it unmistakable. That reading is mine, not his words.

## How the road is laid

1. **The hands come first.** Whatever the two triggers, the fork and the breath are, every land
   multiplies it. So the instrument is made good in the one place that exists before places are
   added.
2. **Every leg ends in a song.** A leg is whole when there is a loop to play with a beginning and an
   ending, and it sounds like music all the way round.
3. **The build grows in the order the game does.** Hum's voice opens 1, 3, 5, 2, 7. The game's first
   hour is built first and its last river last, so playing from the start is always the test.
4. **A rule comes in with a wonder that needs it.** A wonder is a small place where one rule is the
   whole puzzle. So each rule lands together with a wonder that can only be solved with it, and
   playing the wonder is how the rule is judged. (Proposal.)
5. **The whole wheel early, bare.** In leg 2 all twelve lands and twelve caves exist as bare places:
   ground, shapes, notes and colours, and nothing else. The rest of the road makes them whole. That
   shows Morgan the whole world, and shows what the whole world costs the purple, before any land is
   finished. (Proposal. "Bare" and "whole" are this file's words for how far a place is built.
   "Asleep" and "awake" keep the direction's meaning: whether the day's key lights a place.)
6. **One of everything before twelve of anything.** Three lands are made whole in leg 3, and what
   one land cost is counted there, before the other nine are begun.
7. **A sound is measured before it is kept and heard before it is trusted.** Claude can't hear. Each
   new sound is measured with `game/build/ears` against the same hands without it, and then goes to
   Morgan's ears.
8. **Every step is measured on the purple:** late frames, the work in a frame, the slowest sound
   buffer.
9. **What is his stays his, and never stops the road.** Where a step reaches something that is
   Morgan's to decide, it says so and says what stands in until he does.
10. **Maximal.** Where there are two ways to build a thing, the fuller one.
11. **Compact cohesive whole before maximal scale-up** (settled 2026-11-27). Never shrink the
    systemic depth (harmony, reactions, forms, sound mix, local-origin places, deterministic
    keeping): build those at 100% in legs 0 and 1. Keep spatial and content scale tight and
    parametric first: stand up all twelve lands, twelve caves, the lake, the ice, the Wolf and the
    Comma ending at **Essence Density** (each land big enough to house its three above/below faces,
    three cave links, Great Instrument, 1–2 signature wonders placing all 18 core theory wonders
    across the wheel, 1–2 land-native creatures, metre/timbre/weather, and island voice — starting
    around a 400–600 m lake and 150–250 m per land, validated by legs in 2.1). Once the entire
    12-land game plays cohesively from the first drop to the ending, scale up parametrically:
    stretch any land that asks for more room, fill out the remaining ~120 wonders and 96 lives /
    multi-year arcs, and spend the 32/64 GB TF2 card on zero-stall between-day artifacts (dawn
    archives, WAV night albums/stems, printable pages, friend worlds, baked echoes).

### How one step is done

1. Read what the direction says of it, in all three parts.
2. Build it alone.
3. The tests pass, and the scripted player (`game/src/bot/`) reaches it by playing, with no screen.
4. The ears measure it against the same hands without it.
5. The purple measures it. After any change to the rules or the sound, the same-take check is run
   again on the handheld.
6. It is committed and pushed, and `PROGRESS.md` says it is in. When the purple is on the cable it
   goes onto it as `Gameguy`.
7. When Morgan has played it, his take and his session's log are pulled and read, and his words go
   where they land.

## Where it starts

What the build does when a person starts it was looked at on 2026-11-25 (`PROGRESS.md`, "Now"). This
is what the code holds, read for this file on 2026-11-26, and what the road does with each part.
Paths are under `game/`.

| what the build has | where | what the road does with it |
|---|---|---|
| the opening, and the call on a tapped R1: two drops, the call, Drip answering, four breaths, "Oh. You're in.", the page standing up | `src/dark.zig`, `src/world/world.zig` | kept as it is: Morgan's hands said yes to it |
| Hum's legs: a run of 12 m/s, a sprint of 20, the skid, a 3 m jump that lasts 0.68 s with a short hop on a tap, the dash | `world.zig` | kept; every number goes on the bench (1.2); the sprint is open |
| the Garden: 67 asters as tall as cathedrals, reeds, its ground covers, the puddles, the stopped hose and its spigot, the bee, the sky | `scores/garden.txt`, `src/world/` | kept, and laid out again so that it asks for chords |
| the day's note, and the chord's place in the day, as two numbers (`day_hz`, `home_k`) | `world.zig` | they are already the direction's day and chord; they take its names |
| the chords try-out: L1 and L2 among the lift, home and the lean; Hum light, drawn forward, thrown | `chordStep`, `wakeKin` | becomes the game's rule, round the whole ring of seven |
| the wheel on a held R1: twenty-four letters, half a push and a full push, a soft preview, time at a quarter of its pace, drawn on top; two cells can be chosen | `wheelStep`, `src/draw/wheel_lines.zig` | all twenty-four cells can be gone to |
| the swell on R2, a voice a bar, with L1 and L2 stepping inside it and four endings told apart | `swellStep`, `landCadence` | kept |
| the strike: home's chord a note at a time, fuller on the tick | `strike` | becomes the fork as the tune |
| knots, the dodge, the pocket, layers of strikes, the clap | `src/world/knots.zig`, `knotStep` | in the code and switched off (`knot_count = 0`); rebuilt as things that lean with nothing under them |
| the hose as a stopped pipe that can spring open | `src/world/hose.zig`, `openHose` | kept; it can be reached once the knots can |
| colour by fifths round the wheel | `src/draw/colour.zig` | kept: it is rule 1 |
| the sound: one bank of resonators; 192 sounding things of 8 overtones each, 4 held voices that are pulses through a vowel, 16 held tones | `src/sound/sound.zig` | kept and grown: six voices for the band, the ground, the lands' instruments |
| lines of light kept on the GPU, in three passes | `src/draw/lines.zig` | kept |
| a take (the hands, 12 bytes a change) and a save (the whole world, 389,376 bytes, which opens only in a build laid out the same) | `src/keep/` | kept; a file that lasts across builds is added beside them (1.38) |
| one place, compiled into the rules from one score | `tools/score.py`, `src/world/land.zig` | a place becomes data, so that there can be as many as the world needs |
| a scripted player that plays by rules; the room, which logs a person's answers; the ears; the same-take check | `src/bot/`, `src/room.zig`, `tools/` | kept, and used at every step |
| every press of the four triggers and the four face buttons stamped to the sample it fell on | `src/plat/presses.zig` | what the pocket is built on (1.22) |
| 107 tests, seven of which switch knots or cells on by hand | `src/` | the seven are replaced by tests of what can be reached by playing (1.3) |
| the D-pad and the two stick clicks: on the handheld, and not read by the game | `docs/hardware-target.md`, "Controls" | who sings; going under; leaning in |

### The machine, measured

From `docs/hardware-target.md` and `game/README.md`. Every leg is sized against these.

- Four Cortex-A35 cores, three of them for the game. 918 MiB of memory. 640×480 at 58.46 or 60.02
  Hz. One mono speaker.
- One core renders about 2,100 overtones in half a 2.67 ms sound buffer.
- At its fullest so far, with all 192 things ringing, 4 voices and 8 held tones, the sound took 926
  microseconds of a 2,667 microsecond buffer at the median (2026-11-20).
- A frame holds 30,000 lines in 11.1 ms and 40,000 in 13.2 ms with all three passes (2026-11-19).
  The asters, walked by the scripted player, drew 18,055 at most. Three passes is the most there can
  be.
- The triggers are on or off. The sticks change at most 56 to 58 times a second.
- One take plays out the same on the laptop and the purple.
- Two units on one cable: a round trip of 0.47 ms on average, against a frame of 17.1 ms
  (2026-11-13).
- Build against the purple. Never touch the black while Morgan is testing on it.

## The road on one page

| leg | at its end you can | the music it puts in your hands | what it settles |
|---|---|---|---|
| **0. Solid ground** | play the try-out's three chords in a Garden where nothing is see-through, nothing is walked through, and every thing answers the chord by one law | what is in the chord is awake; lift, lean and home as things you can see move | whether the purple can draw a world that hides |
| **1. An evening** | play the first evening from the first drop to waking on the island, and then play it again | the pulse; call and answer; the three chords and the two closes; open fifths, and then the third; the three chords underneath; the turn and the long way home; three against five; your own place against the beat; eight bars | the first eleven rows of "What is sure, and what is still a bet", and the two about the speaker and the purple |
| **2. A morning** | wake on the island, choose the day, and walk the whole world: twelve lands and twelve caves, six awake and eighteen asleep, the low lake, the ice, the gap | a key as a place, and a border as one colour changing; the order of sharps and flats as a walk; the modes as six places; chords from outside the key as weather; the treaty heard on the ice; the comma seen as a ledge | whether a day with a key is a good shape for a world; the world's size; whether the purple can hold all of it |
| **3. Three days** | free two more rivers, wake in three keys, find the Garden floating and leaning, sing with a second voice, and read your verses back | what is underneath: a chord standing, sliding, hanging; what moves least; register and the bass; the ladder of overtones; three, and a slow two; laying back | what one land costs to build; underneath; the wonders; lives |
| **4. Two consoles** | play all of that with JJ, two consoles on one cable | harmony between two people: each the third the other can't make | whether two Hums in one world is a duet |
| **5. Round the lake** | free the other nine rivers, in whatever order you walk to them | every feel in the table of lands; the seventh; carrying the day; changing key by a shared chord; the twin across the lake; writing with pins; a voice built from stops | the whole wheel |
| **6. The gap** | cross the ice, meet the wolf, and, when the twelfth river runs, choose what to do with the remainder | temperament: pure, the treaty, the wolf; the comma as the end of a story; the pocket as the same thing in time | the ending |
| **7. Past the lake** | go on: by thirds, to lands no one has seen; write songs, carry them, send them | composition; a phrase as a walk; loops that miss | that it does not end |
| **8. Out of the house** | hand it to someone who has never seen it | all of it, from nothing | that a newcomer needs no name and a master is rewarded |

## Leg 0. Solid ground

_Nothing in the Garden is see-through. The hose is a dark tube with light along its edges, and what
is behind it is behind it. Hum can't walk through a blade of grass: it bends out of his way. He can
stand on a leaf and bump his head on one. And when he changes the chord, every thing in the Garden
answers by one law._

- **Added on 2026-11-26,** the day this road was written, after Morgan read it and said: "the world
  itself... the (ideally canon/shared/modular) way the world and it's parts react to changes and the
  player and each other and different harmonic relationships... must be established and solid - ya?
  and like... objects in the world shouldn't be see-through/clippy right?" The road as first written
  had no step for either. This leg comes before the evening because every later step stands on it.
- **In the engine's design:** `docs/engine.md`, which holds the audit this leg answers and the shape
  these steps build.
- **It is whole when** the try-out's three chords can be played in a Garden where nothing is
  see-through, nothing is walked through, the eye is never inside anything, and every kind of thing
  is data made from shared reactions; and the measures hold on the purple.
- **It settles:** whether the purple can draw a world that hides; and, as far as an engine can,
  whether a change of chord can be seen and understood.

- **0.1 The music, as its own module.** The note as fifths, thirds, sevenths and octaves. The day,
  the chord, the ground and the change. Every table of the three documents' arithmetic as a test:
  the script that checked them comes into the repository here. Nothing in the game changes yet.
- **0.2 Forms.** One description of a shape that gives its solid, its black shape and its lines:
  stalk, plate, ball, block, shell, ground, strand.
- **0.3 The Garden's kinds, as data.** Aster, bell, reed, blade, clover, crumb, leaf, puddle, hose,
  spigot, drop: each a form, a material, its reactions and its voice. As each is written, its own
  code leaves the rules file.
- **0.4 Everything solid hides.** A black shape for every form. A second list for what moves, with
  Hum and Drip in it. 24 bits of depth. Lines that stand proud of their own solids.
- **0.5 Everything solid stops.** Solids with tops, undersides and sides, found through a grid. Hum
  moved by one routine: he can stand on a leaf and hit his head on one. He can also walk along the
  top of the hose, which is new, and for his feet to judge.
- **0.6 Soft things part.** Blades and reeds bend round Hum. Nothing is walked through.
- **0.7 The eye.** Never inside anything. When something big is in the way it moves in, then up.
  When something thin is in the way, the thing parts. Then the rule that makes near things
  see-through is taken out.
- **0.8 The world moves by table.** A second table beside the one that says how bright each body is:
  how each is lifted, tilted or slid. Lines, black shapes and solids all follow it.
- **0.9 The standing, and the first reactions.** What each note is to the chord, worked out once for
  each note in the place. Then wake and rest, rise, tilt and wind, land, settle and ring, on the
  try-out's three chords, for every kind in the Garden. This is rules 2 and 3 as one law. Steps 1.6
  and 1.7 then lay the Garden out to use it.
- **0.10 Touches, the table of meaning, streams and the mix.** The five ways the world is touched.
  One table for what every sound and every light means. A count of streams and of roughness, kept by
  the engine.
- **0.11 The rules file split by the order of a step,** and the scene loop made blind to kinds.
- **0.12 All of it on the purple.** Black triangles together with lines; the second table; parting;
  the mix; the path from a press to its sound. Each is measured, and the same-take check is run
  again.

## Leg 1. An evening

_You cross the garden on three chords. You find a voice in the dark under it and your own voice
turns warm. At dusk you bring three knots home, the hose opens, and you fall asleep in its water.
You wake on an island, and your day is a song._

- **In the direction:** `the-game.md`, "The first hour, as played", "The hands", "The rules" and
  "Where the game stands, and what I would build first"; `the-depths.md`, "The third", "What moves
  least" and "When"; `the-wormhole.md`, 1, 2, 3, 7 and 8.
- **It is whole when** Morgan can play it from the first drop to the island and start a second
  evening, the scripted player can do the same with no screen, and the measures hold on the purple.

### Before anything

- **1.1 Read what his hands did.** When the purple is next on the cable, pull the try-out's take
  (`results/walks/chords-tryout-*`) and its session log, play the take back, and read where he
  stepped the chord, how often on the tick, and what he tried that did nothing. Pull the game's kept
  takes and dawns from that unit too, and file them with the build that made them: they will not
  open in what comes next. Nothing of his is deleted from the unit. The old folder is pulled, and
  then set aside under a dated name.
- **1.2 The bench.** A page in the pause screen that lists whatever is being tried. Each number that
  is his hands' to set can be nudged there while he plays, and each either-or has a switch. What he
  leaves it on is written to the session's log. `the-game.md`, "Yours": "Every number in the body.
  Your hands." (Proposal. It is a tool, and no part of the game.)

### A. The chord becomes the game

- **1.3 The try-out becomes the rule.** Stepping the chord stops being a switch (`--chords`) and
  becomes what the game is. In the code the two left triggers are still named for the older design's
  voice wheel and guard, and L2 also swings the view round behind Hum. The names go, and so does the
  swing. The day and the chord take the direction's names in the code. The seven tests that switch
  knots or cells on by hand are replaced by tests of what the scripted player can reach. Once this
  is on the purple, the try-out's own entry there is retired.
- **1.4 The day's ring on one finger.** L2 rises a fifth inside the key and L1 falls one, all the
  way round the seven. From home, L2 goes to the lean, the cave that runs, the cave that remembers,
  the cave that aches, the seam, the lift, and home. The seam can't be stood on: one beat there, and
  Hum falls on. Before the third is found, the three chords past the lean are bare fifths with
  nowhere to go.
- **1.5 The chord's own sound.** Each step strikes the chord's root and fifth, pure, over the
  ground's own note, and never its third: the third is Hum's. It is struck and dies away, and is
  never held. What the last chord and this one share keeps sounding, and what leaves moves to the
  nearest note. It is measured as the try-out was (16% rough, against 12% for the same hands without
  it).
- **1.6 What is in the chord is awake.** Rule 2, for everything in the garden. (The law itself is
  step 0.9. This is the Garden's things given their notes so that each chord wakes a different set.)
  A thing whose note is in the chord brightens, firms up and answers. A thing whose note is not dims
  and goes soft. The try-out lights what is kin; this makes it the world's law, so that a chord is a
  set of colours and changing it changes what the world is made of. What firm and soft are under
  Hum's feet is for the bench: my first guess is that a firm thing bears his weight and a soft one
  gives way slowly.
- **1.7 Which way things go.** Rule 3, on the reactions of step 0.9. On the lift, what belongs to
  the chord rises. On the lean, it tilts toward home and winds up. At home it holds, and what was
  leaning lands. The garden's own things do it: leaves on water, grass, seeds, the asters' heads.
- **1.8 Hum's three bodies above ground.** Light on the lift, sure-footed and heavy at home, drawn
  forward on the lean. The try-out's two numbers (the ground pulls 0.55 as hard; the legs run 1.3
  times as fast) go on the bench beside the design's own (two thirds and four thirds), and his hands
  set them.
- **1.9 Two ways home.** From the lean, the full close: what leaned springs home and Hum is thrown
  forward. That is the launch. From the lift, the amen: things settle, and Hum lands softly. Both
  are heard and both are seen.
- **1.10 Time rewards.** A step of the chord on Drip's tick rings fuller and does more, as a timed
  strike already does. Then the beat as a small key: acting on the beat lands, on the off-beat
  lifts, and a hair before the beat leans.
- **1.11 Hum's body keeps time.** A jump that lasts one beat lands on the next tick. Today a jump
  lasts 0.68 s and Drip ticks every 0.833 s, so the two don't fit. On the bench: Drip at 72 a minute
  as now, or at 88 to 90 so that the jump stays snappy and lasts a beat. And his stride as the drum
  part: the beat's halves at a run and its thirds at a sprint.

### B. The garden asks for them

- **1.12 The leaf on the first puddle.** Drip hops ahead to a puddle. A teal leaf sits low on the
  water, and Drip leans left. On the lift the leaf rises and Hum is light enough to reach it. Then
  L2, and everything settles: the first amen.
- **1.13 The run beside the hose.** On the lean the grass bends toward the middle of the garden and
  Hum is drawn along it. Stepping home on Drip's tick lands everything at once and throws him: the
  long jump.
- **1.14 The high landing by the great aster.** Home is the body that lands anything.
- **1.15 Crossing by ear.** The garden is laid out so that the three chords, in any order, take you
  somewhere: lean to run, lift to leap, home to land. The scripted player crosses it. Each thing
  answers the first try, because Morgan's first play of the older build got lost at Drip: every verb
  is shown by need, and every try is answered.

### C. The right hand

- **1.16 The fork is the tune.** The strike plays the next note of the chord at once: the one
  nearest the note it last played. So the right thumb's part comes out as a line whatever the left
  finger does. Before the third it has roots, fifths and octaves. On the bench: the candidate that
  it steps up the chord while Hum rises and down while he falls.
- **1.17 The swell, a floor a bar.** R2 held adds a floor each bar, from the overtones Hum's voice
  has opened so far: at first the root and the fifth. A held breath stores, and letting go on the
  one releases all of it. The triggers step inside it, as they do now.
- **1.18 The wheel, whole.** All twenty-four cells can be pointed at, gone to, and stayed in. The
  lit six are today's key. The dark eighteen are the wormhole, and going there costs nothing. Half a
  push is the inner ring and a full push the outer, as now. Resting on a cell plays it softly,
  pointing lights what near you belongs to it, and a thread through the day's seven shows the ring.
  It is drawn as part of the world, and never under foliage.
- **1.19 Twenty-four cells in tune.** Hum's note never moves, so each cell needs a root that sits
  right against it. A script works the table out, the ears measure each cell, and the doubtful ones
  (the sevenths, and the altered floors sharpward) go to Morgan as a sketch before they go in.
- **1.20 Every cell has a body.** Two candidates, on the bench. One is the six bodies, with the
  three axes giving every dark cell one of hold, lean or lift. The other is the elevator: flatward
  Hum gets lighter and more vivid a floor at a time, and sharpward he hangs and then pulls harder.
- **1.21 A wide chord is a band of colour.** As the swell stacks fifths, the chord lights a band of
  neighbouring colours. Before a jump through the wheel, the colours the two chords share show what
  will come with you.
- **1.22 The pocket, tried.** Every press is already stamped to the sample. First measure how finely
  the purple times the triggers. Then the rut: where his presses keep landing against Drip's tick
  wears in, and inside it everything rings fuller. Ahead of the beat pushes, and behind it sinks in.
  Off-beats kept late make Drip swing. Rests give breath back. And since the triggers are on or off,
  how long a press is held and where it falls is how loud it is.
- **1.23 Six wonders of when.** The rut. Lifting and setting down. Ahead and behind. Long and short.
  Turn it around. The rest. Each is the playable test of something in 1.10, 1.11 or 1.22. (That
  these six live in the Garden is a proposal.)

### D. Underneath

- **1.24 A second place.** Today the Garden is compiled into the rules from one score. A place
  becomes data. The cave under the Garden is the second place, from its own score, and the well by
  the stopped hose joins them.
- **1.25 The cave under the Garden.** It is dark. The asters' roots hang like pillars, one for each
  aster above. You see by calling. Its ground sounds A.
- **1.26 The third.** Someone is singing down there. Fall in with them, breath for breath, as with
  Drip, and the third opens in Hum's own voice: it was his fifth overtone all along (5/4, 386.314
  cents). The three plain chords turn warm, the fork gains its third, the swell gains a floor, and
  three more chords wake under the first three. Who that someone is belongs to Morgan.
- **1.27 Going under and coming up.** The left stick's click moves between a chord and the one under
  it. If the click is awkward under a thumb that is steering, both left triggers together is the
  other way. Both go on the bench. With it comes the wonder of the note beneath the note.
- **1.28 Three bodies underneath.** Under the lift Hum slides: over water, under gates. Under home
  he is small and close, and singing shows what was: paths, the past, a thing's last motion run
  backwards. Under the lean he hits hard, and shakes things at their own note until they give.
- **1.29 The turn, and the long way home.** From the lean to the cave under home: things land
  somewhere they did not expect, and show their other side. A walk of falling fifths: each step adds
  to what the last one stored. With 1.9 these are the four ways home.
- **1.30 Roots and flowers.** Wake a root from below and the aster above it changes.

### E. Dusk

- **1.31 The Garden's own music, and the day's shape.** The Garden plays a root and a fifth and
  leaves room. It thins when the player is busy and answers in the gaps. While the lake is low its
  phrases end on almost-endings. It has a dawn, a long middle and a dusk, and that is the only
  clock.
- **1.32 Knots.** At dusk they come out by the hose's knot. Each is two notes pulling against each
  other with nothing under them. Call one and it rings its notes. Put under it the chord it is the
  top of, and it stops thrashing and leans. Ring it on the beat until it is ready. Hold your breath,
  step home, and let go on the one. It comes home and becomes something else. The three in the
  Garden's score are C and A over a missing F, pulsing three against five, so the chord that goes
  under them is the lift and they come home by the amen. (That last reading is a proposal.)
- **1.33 The fight is in time.** A knot lunges on its own pulse. The right face pressed on its beat
  is the dodge that opens the pocket. Clicking the right stick sends Drip to whatever you are
  facing, to tick its time.
- **1.34 The hose opens.** Water runs to the pool, over its lip, and down a dry channel toward the
  lake. Who sits on the pool's edge is Morgan's.

### F. Night

- **1.35 Lying down.** At dusk Hum can lie down in running water. Nothing forces it. He can stay up,
  and nothing is kept from a day he never slept on. If he is shaken apart he falls asleep where he
  is, and the river takes him early with a shorter song.
- **1.36 The day sung back.** Eight bars, made from the chords he played, in the order he played
  them, with the endings he landed. It is never an exact repeat: two bars become four by one small
  change, and four become eight by another. First as a sketch made from one of Morgan's own takes,
  for his ears. Then in the game.
- **1.37 Keeping.** One moment of the day is chosen and kept. The rest goes into the water.
- **1.38 What lasts.** What a night keeps (the river freed, the verse, the kept moment, the third,
  the rut) goes in a file of its own that every later build can read. The whole-world save stays,
  for opening a dawn again.
- **1.39 The island, first cut.** Hum wakes on an island in a low lake. Twelve posts stand round its
  shore and one is lit. The verse plays. Waking the post begins the next day.
- **1.40 The second evening.** The hose runs, the Garden's own music lands more often, and what was
  kept stands on the island. The loop is whole.

### What leg 1 settles

In "What is sure, and what is still a bet": that stepping chords while running feels good (1.4 to
1.15); that a change of chord can be seen and understood (1.6, 1.7, 1.12 to 1.15); that trouble as
something that leans makes a good fight (1.32, 1.33); that underneath is worth going to (1.24 to
1.30); that the night gives the day back as a song worth keeping (1.36); that the game can hear
where he puts the beat (1.22); that leaving the key and staying sounds good (1.18, 1.19, with sketch
l); that the right hand is the tune (1.5, 1.16, with sketch m). The six places sounding like their
six words is still for his ears on sketch j.

## Leg 2. A morning

_You wake on the island. Your verse is playing. Twelve posts stand round the shore and one is lit.
You wake it and set out, and from the Garden's rim you can see the whole world: a land awake on
either side of you, nine more dark round a low lake, a field of ice, and far across the water a
place where one bank stands a little higher than the other._

- **In the direction:** `the-game.md`, "The world" (all of it), "A day", "Outside the key" and
  "Tuning"; `the-depths.md`, "Your second picture is a compass".
- **It is whole when** he can walk from the island into any of the twenty-four places, on a day in
  any key the bench lights, and the purple holds it.
- **It settles:** whether a day with a key is a good shape for a world, in a first test (2.15); the
  world's size (2.1); whether the purple can draw and sound all of it (2.16).

- **2.1 How big the world is, by his legs.** The world's size is open. So the first step is a
  try-out: the island, the lake bed and the Garden's shore at a **compact sightline-rich starting
  scale** (target ~400–600 m lake diameter, ~15–25 s island-to-shore at 12 m/s, and ~150–250 m per
  land — sized cleanly to fit all three faces, cave links, Great Instrument, wonders and sightlines
  without vast empty ground) beside larger variants, for his legs to choose. Because every place
  uses local-origin scores (`2.2`), scaling any land up later is pure score/data work rather than
  an engine rewrite. (The older notebook's 3.7 km lake in `spec/size.md` is 154 s island-to-shore
  and waits for Stage C scale-up if the legs ever ask for it.)
- **2.2 A world of places.** One score for each place: twelve lands, twelve caves, the island and
  the lake. The world holds the place Hum is in in full and what he can see of the others in
  outline, and it steps only what is near him. On the surface nothing loads behind a door. A picture
  of any place from straight above can be made with no screen, so a layout can be checked before it
  reaches a handheld. Memory is not what limits this: today's whole world saves as 389,376 bytes,
  against 918 MiB. What limits a place is what one core can step and sound, and how many lines a
  frame holds.
- **2.3 The lake.** It is low. Where it is open, sound carries over it and comes back. Its level is
  one number that rivers raise, and that number decides how often the world's own phrases land.
- **2.4 The ice.** Parts of the lake are frozen. On the ice the notes are the treaty's, every fifth
  1.955 cents narrow, and nothing rings. It is the short way between far lands, and it is the first
  time the difference between pure and the treaty is under his feet.
- **2.5 The island.** Twelve posts, one facing each land. Waking a lit post chooses the day. Walking
  the shore plays the verses in order. What was kept stands where it was put.
- **2.6 Twelve lands and twelve caves, bare.** Each comes from a score with its shape, its ground
  covers, its own note and colour, and the tall things its material makes. No river's stop, no
  people and no wonders yet.
- **2.7 The day's key lights six.** The six lit cells on the wheel are the six lit places. Each mode
  falls out of a place's own note under the day's seven notes, and nothing is arranged to make it
  so.
- **2.8 Faces, first cut.** What each face does to a place's own things. Floating, they drift up,
  and one note of the land is raised and hangs. Home, everything is where it lives. Leaning, the
  land tilts toward home next door and things roll that way. Underneath: water that moves, pools
  that show, a roof that sits close.
- **2.9 Asleep.** The other eighteen are dark and quiet and can be walked into. It is night there. A
  chord from that place, brought with the wheel, wakes a patch of it round Hum for as long as he
  stays, and what his chord shares with it is footing.
- **2.10 Across the water.** From any shore the lights of every land show across the lake, and the
  far ones are heard late.
- **2.11 The ways between.** Down a river bed, across the ice, round the shore. And underneath: the
  well to a land's own cave, the slip under the border to the cave beneath its sharpward neighbour,
  and still water to the cave with the land's own name, a quarter of the way round the lake.
- **2.12 The gap, seen.** At the far side of the lake one bank stands a little higher than the
  other: 23.460 cents, as a ledge.
- **2.13 The four winds.** The four cells that hold, as places on the lake. On a day in C they are C
  in the north, A in the east, F♯ in the south and E♭ in the west. The caves that join them make a
  ring of eight places. The wonder of the four winds comes in here, in a first cut.
- **2.14 Under the island.** The deep place, and its first level.
- **2.15 The morning.** Wake, hear the verse, choose, go. The bench can light any post, so any day
  can be walked before its river is free. That gives the row "a day with a key" its first test: the
  Garden on a day in G, and on a day in F.
- **2.16 The whole map on the purple.** Measured before any more land is made whole, with the world
  at its fullest: lines a frame, late frames, the slowest sound buffer.

## Leg 3. Three days

_On a day in C you walk sharpward and the land tilts back toward the Garden. Strings hang between
the stalks, and a harp the wind plays is holding a ditch shut. Another day you walk flatward, and
everything floats a little, and you go in through the sound hole of a guitar. Then one morning there
are three lit posts. You wake the yellow-green one, and the Garden you have known since the first
evening is floating._

- **In the direction:** `the-game.md`, "Three faces above, three below", "In every land" and "What
  grows"; `the-depths.md`, "It is a cave with two mouths", "What is underneath", "What moves least",
  "The great instruments", "Wonders" and "Endless composition"; `the-wormhole.md`, 4, 5 and 8.
- **It is whole when** three rivers run, three posts are lit, and each of the three days is
  different to play.
- **It settles:** a day with a key, in full: a second land beside the Garden, visited on two
  different days; and whether the whole of it can be built, because it shows what one land costs
  (3.14).

- **3.1 What making a land whole is.** The list in "What making a land whole means", below, made
  into the words a score needs: a river and its stop, roots, wonders, people, creatures.
- **3.2 The songbook under the direction.** Names wait there until they are asked for, and the top
  face held on anything gives its name. A page for each wonder, drawn by the beam. A page for each
  verse: the chords' letters above the line and their numbers below.
- **3.3 A wonder gives a page and a figure.** The figure is a small shape of rhythm or of notes. It
  can be planted on the island, and the band starts to use it. Taking hold and planting are the top
  face.
- **3.4 The Garden whole.** Its twelve wonders from the notebook, as things to find. Its people and
  its creatures. Its second and third ways down. And the Hose as a place to go inside on the
  Garden's own day, where its standing wave is the floor plan. At its heart the notebook put the
  Great Knot, five against seven. Five and seven are the third and the low seventh of the leaning
  chord when it is tuned 4, 5, 6, 7, so the Great Knot is the seam itself, the top of the lean with
  its root missing (7/5, 582.512 cents), and it comes home by the full close. (That reading is a
  proposal.)
- **3.5 The Alfalfa, met leaning.** Strings and stalks, and wind. Three, as a field sways: the long
  breath. Its river is the irrigation ditch and its stop is the Wind Harp, where a light touch a
  fifth of the way along a ringing string leaves only its fifth overtone: the third, inside the
  note. Under it is E minor, the cave with two mouths, with the wonders "Two mouths" and "Home,
  hollowed".
- **3.6 A second voice, and the D-pad.** Who sings with you, from the lowest voice to the highest.
  With a low voice singing, each chord's own root goes down under it, and every chord stands
  wherever you are. The low voice walks from one chord's note to the next and answers the tune: the
  counter melody. Whoever sings highest is what the ear follows. And the band listens: it thins when
  you are busy and answers when you leave a gap.
- **3.7 What is underneath.** The ground's note makes one chord six different things in the six
  places of a day. Root lowest, it stands and bears weight. Third lowest, it slides and passes you
  along. Fifth lowest, it hangs until you resolve it, and then it drops. A place strengthens its own
  job. Each place has one chord that sounds like here. With it comes the wonder of the three
  landings.
- **3.8 What moves least, seen.** What stays in the chord is footing. What leaves hands its light to
  its nearest neighbour, a step up or down. Things lean the way they want to go. Hum's rings show
  which voices stay and which slide. With it come four wonders: the step that stays, two become one,
  the stone that waits, the slow slide.
- **3.9 The Porch, met floating.** Wood: boards, chimes, a chair, a guitar in the corner. The
  chair's slow two: laying back, a strum that falls just behind. Its river is the narrow water
  between it and the Garden, and its stop is the Guitar, entered by the sound hole: one chord in
  many shapes, and six strings that can't all agree (four pure fourths and a pure third fall 21.506
  cents short of two octaves). Under it is D minor, the cave that runs on a day in C. Who sat in the
  chair is Morgan's.
- **3.10 Days in G and in F.** On a day in G the Garden floats, and the sky over it opens. On a day
  in F it leans, and the road onward and the border open. The cave under it runs on the first and
  aches on the second. On those days the Glass Hills and the Reed Mouths are awake too, and still
  bare.
- **3.11 Lives by key.** People keep their lives by the day's key. The caravan moves three lands at
  a time. Someone is only in the Garden on days it floats. Talking, on the top face.
- **3.12 The island with three posts.** Three voices in its song, three rises of the lake, and the
  deep place two levels deeper.
- **3.13 The page as a tool.** One wonder that can only be read from straight above. Morgan's
  thought is that this view will solve things the standing view can't. The direction keeps that
  open, and this is its try-out.
- **3.14 What a land costs — and the Essence Pass.** Counted, not guessed: how many steps of this
  road one land took, how long its score is, how many things it holds, and its lines a frame and
  overtones at their fullest. Rather than stuffing all 12 notebook wonders and 8 lives into the
  first three lands before building lands 4–12, legs 3 and 5 bring **all twelve lands through
  Essence Density first** (3 above/below faces, 3 cave links, Great Instrument / River Stop, 1–2
  signature wonders covering all 18 core theory wonders across the wheel, 1–2 land-native creatures,
  metre/timbre/weather, and island voice) straight through leg 6's ending. Expanding every land to
  full 12-wonder / 96-life maximal density follows once the complete 12-land arc plays cohesively.

## Leg 4. Two consoles

_JJ sits down beside you with the purple. There are two small figures in the garden now, and two
notes. Each of you is the third the other can't make._

- **In the direction:** `the-game.md`, "Two consoles".
- **It is whole when** two people can play a whole day together on two consoles, and the game for
  one needs nothing from the second.

- **4.1 Two pairs of hands in one world.** The rules take a second Hum. On the laptop the second is
  played back from a take, so the rules can be tried before any cable.
- **4.2 What two Hums are to each other.** The direction's words are all there is: the second player
  is the other voice on the same wheel, each is the third the other can't make, and the treaty is
  two wheels pointed at one key. What that is in the hands is found by trying it with JJ.
- **4.3 The link.** Both consoles step the same world from both pairs of hands. One take already
  plays out the same on every machine tried, and the cable's round trip is under 3% of a frame. Each
  console sounds the whole of the music by itself, because nothing may rest on two speakers being in
  time.
- **4.4 What the cable needs.** The black hosts, because only it has the device tree for it, and the
  host has to switch its port's 5 V on. That needs Morgan's word each time, and it never happens
  with a computer on that port. Not yet tried, and tried here: the purple as host, a link held for
  hours, the cable pulled in the middle of a day.
- **4.5 Keeping, for two.** A take with two pairs of hands. Whose island a shared day's verse goes
  to is not decided.
- **4.6 Whole alone.** Checked again: nothing in the game for one waits on the second console.

## Leg 5. Round the lake

_Every new morning shows a land you have not seen. Sharpward each one leans back toward where you
came from. Flatward each one floats over it. They are made of glass, of reeds and breath, of bells,
of rain, of wire and salt, of petals, of chrome, of still things under panes, and at the far side
there is a city where everything is a little off and everything is connected._

- **In the direction:** `the-game.md`, "In every land", "Trouble" and "What grows"; `the-depths.md`,
  "Each land has a feel", "The great instruments" and "Wonders".
- **It is whole when** all twelve lands are whole, and their rivers can be freed in whatever order a
  player reaches them.
- **The order.** Outward from the Garden by fifths, one sharpward and one flatward in turn, and the
  Seam last. It is the order a player meets them in whichever way round they go, and each pair is
  the same distance from home. (Proposal.) Each land is built by the list in "What making a land
  whole means", and its row is in "The twelve lands".

- **5.1 The Glass Hills and the Reed Mouths (D and B♭).** Glass that rings longer than anything, and
  reeds on one breath. Both are made of long sounds, and held tones are what Morgan's ears liked
  least in the room. So each begins as a sketch for his ears before anything is built. The Armonica:
  holding a note over a change and letting it settle. The Mouth Organ: the ground, and breathing as
  the cadence, out for home and in for the chord that leans on it. Time with no beat, and breath as
  time. Under them: B minor and G minor.
- **5.2 The Bell Meadow and the Rain Steps (A and E♭).** The east and the west of the compass on a
  day in C. The Belfry: the two thirds, sad and sweet, and an order as a tune. The Cistern, where a
  sound lasts half a minute: a tune sung slowly is a chord, and you sing against your own echo. Six,
  danced as three against two, and a beat found in rain. Under them: F♯ minor, and C minor, where
  the Garden's still water comes out.
- **5.3 The Highway and Verbena Hollow (E and A♭).** The Looper: layers, a round of twelve bars, the
  low seventh on every chord. The Music Box: writing, where a pin is a note at a moment. The shuffle
  and the backbeat, and six counted two ways at once. Under them: C♯ minor and F minor.
- **5.4 The Chrome Nave and the Aster Steps (B and D♭).** The Organ under the hood: a voice built
  from overtones, with a stop for each. The Bell Jar: silence, the half step, and the lean's twin.
  The machine's sixteen, and the rest. Under them: G♯ minor and B♭ minor.
- **5.5 The Seam (F♯ and G♭).** It is met leaning from a day in B and floating from a day in D♭, and
  it has a bank for each. The Piano, with the Metronome under it: the treaty, where every key is
  next door; the grid, and what swing does to it. Under it: D♯ minor.
- **5.6 The band, whole.** The friends who join give time, a bass, a tune, an inside line and a
  light on top. Each is a vowel, and each shows Hum where one overtone lives in his own voice. That
  is six held voices, where the bank has four today.
- **5.7 The seventh.** Hum's voice gains it, and there is a hook on every lean. He can lean on any
  cell, wake a sleeping neighbour, and carry the day: the wheel held on the lift or the lean for a
  whole bar slides the lit six one step, with no trip to the island. With it comes the wonder of the
  gap that closes.
- **5.8 Changing key by a shared chord, and the twin across the lake.** The chord a tritone from the
  lean shares its restless pair, so pointing at it slides you home from across the lake. Going down
  a well and up through the mirror with the day in hand moves the key a minor third and keeps four
  of its seven notes. With these come two wonders: the twin, and the four winds whole.
- **5.9 Four voices that must not cross.** The wonder of the loom, once the band has four.
- **5.10 Trouble's variety.** What is missing under a thing; which way home suits it; how its pulse
  sits against yours; how many there are and what order brings them all in; the face of the place
  you meet it in. Threes above ground and fives underneath. What rushes is beaten by patience, what
  drags by push, what is stiff by swing. The big ones are the rivers' stops, each built from its
  land's own piece of harmony.
- **5.11 The lake rising.** With each river the lake is higher, the island has another part and
  another voice, the deep place another level, and more of the world's own music lands.

## Leg 6. The gap

_All twelve rivers run and the lake is full to the gap. The circle still does not close. You are
standing where it ought to, with everything you have learned, and the game asks what to do with what
is left over._

- **In the direction:** `the-game.md`, "Tuning" and "The story"; `the-depths.md`, "The pocket is the
  remainder, in time".
- **It is whole when** the game can be played from the first drop to an ending and on past it.

- **6.1 The ice, whole.** What it is to cross, what it is to stand on, and what the ice has taken:
  one of the two kinds of trouble that come from tuning.
- **6.2 The wolf's valley.** One place, and one great trouble. Eleven fifths are tuned so that their
  thirds are sweet, and the twelfth comes out 35.682 cents too wide and howls. Where the valley lies
  is not placed by the direction. As that tuning was usually set, the wide fifth falls between G♯
  and E♭, which on this wheel is the border of Verbena Hollow and the Rain Steps, and the notebook
  already had the wolf's fifth "lying along" Verbena Hollow's border. So that border is my proposal.
  (How the tuning was usually set is general knowledge, not checked against a source today.)
- **6.3 The lake, full to the gap.** The twelfth river, whichever it is.
- **6.4 The remainder.** Three things can be done with the gap: freeze it shut, keep everything pure
  and let the lake drain, or hold it open with someone. They are gestures the player already knows:
  a clap, a step, a hold. In time they are the click, everyone in their own time alone, and a
  pocket. Which of them are endings is Morgan's.
- **6.5 Hum's voice, whole.** A closed hum at the first drop. By the last river it is a voice.
- **6.6 The bottom of the deep place.** Where the lake's water goes.
- **6.7 The table on the island.** After the ending, for anyone who wants it: the twelve small
  shares of the gap can be laid on the fifths any way you like, and each way is a tuning that people
  once lived in. This is where the parked twelve-shares dial comes back.
- **6.8 Each land's own tuning,** if Morgan says the lands keep theirs.

## Leg 7. Past the lake

_You sing a phrase at the river and it carries you somewhere that has never existed until now.
Nobody has seen it. Anyone who sings the same phrase will arrive in the same place._

- **In the direction:** `the-game.md`, "The story" (its last line); `the-depths.md`, "Endless
  composition".
- **It is whole when** a player can leave the lake, arrive somewhere made from their own phrase, and
  come back with something.

- **7.1 By thirds.** The world past the lake opens in the direction the caves already run.
- **7.2 Lands that are made.** A land out there is three numbers: how many fifths, thirds and
  sevenths it lies from the Garden. Rules and those numbers make its ground, its things and its few
  lives. None repeats.
- **7.3 Songs are places.** A phrase is a walk, each step a fifth, a third or a seventh, up or down.
  Sing it at the river and it carries you to the land where that walk ends, on any console.
- **7.4 Loops that miss.** Twelve fifths round the lake come back 23.460 cents high. Four trips down
  a well and up through the mirror come back 62.565 low. Three by the slip and the mirror come back
  41.059 low. Each of those is another garden.
- **7.5 The island as a music box.** What you kept are its pins, and the river turns it. Move a kept
  thing and the order changes. Choose who in the band plays each verse.
- **7.6 Every place is a variation.** Carry a verse to any place and that place plays it: its note
  underneath, its great instrument on the tune, its feel moving the time. Seventy-two ways to hear
  every verse.
- **7.7 It leaves the handheld.** A verse goes out as its sound and as its page. A day is its
  inputs, a few thousand bytes that play back the same on any machine.
- **7.8 What is still open out here,** and is built only if Morgan asks for it: the islets of other
  equal temperaments, the Shimmer, the country with no octave, free choice of notes, lives changing
  over years, and what the card is for beyond takes and saves.

## Leg 8. Out of the house

_Someone who has never seen it picks it up. Nobody tells them anything. An hour later they are
crossing a garden on three chords and have not been told a single name._

- **In the direction:** `the-game.md`, "A newcomer and a master".
- **It is whole when** a stranger with an R36S can install it and play.

- **8.1 A newcomer, watched.** Someone who has never played, with no help, from the first drop.
  Where they stop is where the game is unclear.
- **8.2 A master, watched.** Someone who knows harmony. Everything they know has to work the first
  time they try it.
- **8.3 The name of the game.** Morgan's.
- **8.4 The songbook's credits.** The notebook's were from general knowledge. Each is checked
  against a source before it is written.
- **8.5 A port anyone can install.** The launcher and its folder as they are, made to stand on a
  unit that has never been set up by hand: other clones, both refresh rates, the buttons found by
  where they are.
- **8.6 Other machines.** `docs/other-platforms.md` says what travels.
- **8.7 The repository.** Private. Changing that needs Morgan's word.

## Lines that run the whole way

These are not legs. Each grows at nearly every step.

- **The sound.** One bank of resonators, with one core's worth of overtones to spend. It gains:
  every chord pure against Hum's fixed note (1.5, 1.19); the ground's note, struck and never droned;
  the land's own music, which leaves room; Hum's voice opening, heard in his own hum; six held
  voices for the band; one timbre for each great instrument; the night's eight bars; and the
  treaty's notes for the ice and the Seam. The speaker is small and mono, and the bank already
  shapes low notes for it.
- **The look.** Lines of light on black, and colour by fifths. It gains: awake and asleep, firm and
  soft; rising, tilting, landing; each land's material drawn in lines; caves you see by calling; the
  sky; water and ice; the wheel with its thread; Hum's rings, which stay or slide; the songbook's
  pages drawn by the beam; and the island growing.
- **Places as data.** A score for each place, and the tools (`game/tools/score.py --inspect --map`)
  that turn a score into a place, a top-down PNG map picture, travel-time estimates, and a
  build-time
  count of lines and black triangles against the Mali-G31 budget (`24,000` lines / `12,000` black
  triangles).
- **The Workbench & Cohesion Guard.** Four force multipliers kept live across every leg: (1) the
  Start/Pause Menu Workbench (`1.2`: Songbook, live GPU/audio/harmony Status, live `feel.now` Bench
  sliders + optional corner HUD, and dev Arena warps/toggles); (2) `score.py` Place Inspector & Map
  Exporter; (3) Durable Cross-Build Progress (`1.38`, `keep/progress.txt` surviving struct changes);
  and (4) Per-Land Automated Cohesion Checks (GPU ceiling, `ears` roughness, bot reachability, and
  `same-take` determinism).
- **Keeping.** Takes, saves, and the file that lasts. A take from any step of the road must still be
  readable for what the hands did, even when the world it was played in is gone.
- **Measuring.** The ears; the purple's frames and buffers; the same-take check; the scripted player
  finishing whatever a person is meant to be able to finish.
- **His hands and ears.** The purple always holds the newest step that passed its measures, as
  `Gameguy`. The bench holds whatever is being tried. Sounds go to him as sketches before they go
  in. When he says he has played, his take and his log are pulled and read.
- **The theory, checked.** The arithmetic of the three documents was checked by a script outside the
  repository. It comes in with 0.1. The game's own tables (the ring, the modes, the floors, the
  shared notes, the tunings) are made from one source, so they can't drift apart, and every one is
  stated at the size it is true.
- **Playthroughs.** Before a leg goes to Morgan it is walked as a newcomer would walk it and as
  someone who knows music would. The seven older playthroughs in `design/playthroughs/` are history,
  and their method is kept.
- **Words.** At most one line on the screen. Names only when asked for.
- **Thumbs.** Before any control is called done, the digit that performs each of any two things done
  together is named.

## What making a land whole means

Leg 2 gives every land its ground, its shapes, its note and its colour. Making it whole is the rest.
Each land in legs 3 and 5 gets all of this.

1. **Its three faces above:** floating, home and leaning, and what each opens: the sky over it; its
   people at home and what they give there; the road onward and the border.
2. **Its cave, and its three faces below:** running, remembering and aching, and what each opens:
   ways through along the water; the past; the deepest doors.
3. **Three ways down and three ways up:** the well, the slip under the border, and still water.
4. **Flowers above and roots below:** everything tall has a root in the cave under it.
5. **Its river and what stops it,** which is its great instrument: a place you go inside. It is met
   on the face the land first shows, and on the land's own day it plays.
6. **Its big trouble,** built from its own piece of harmony.
7. **Its feel:** its metre, and what the hands learn there.
8. **Its twelve wonders** from the notebook, and any of the eighteen new ones that live there. Each
   gives a page and a figure.
9. **Its people,** each with a note and something they lean toward, and lives kept by the day's key.
10. **Its creatures,** found nowhere else. Morgan: "All creatures should be unique and intentional
    based whatever one of 12 lands they are from".
11. **A voice for the band,** in most lands.
12. **Its own music:** a root and a fifth, with room left, in its own instrument's sound.
13. **Its weather:** what its chord brings when it is carried somewhere else through the wheel.
14. **Its post,** its part of the island, its voice in the island's song, its rise of the lake, its
    level of the deep place.
15. **Its measures:** the ears, the purple, the same-take check, the scripted player.

## The twelve lands

The names, what each is made of and each river are the notebook's (`spec/world.md`, history, kept by
name). The feel and the instrument are from `the-depths.md`. "First met" follows from the direction:
flatward of what you have joined a land is met floating, and sharpward it is met leaning.

| land | key | first met | made of | its river | its feel: what the hands learn | its great instrument: the place to learn | its cave | leg |
|---|---|---|---|---|---|---|---|---|
| the Garden | C | at home, on the first evening | water and stems | the hose's water | four, with Drip's swing: the tick, and landing on the one | the Hose: the pulse; three against two; the three chords and the two ways home | A minor | 1, 3 |
| the Alfalfa | G | leaning, on a day in C | strings and stalks; wind | the irrigation ditch | three: the long breath | the Wind Harp: the ladder of overtones, and the third inside the note | E minor | 3 |
| the Porch | F | floating, on a day in C | wood | the narrow water between it and the Garden | the chair's slow two: laying back | the Guitar: one chord in many shapes; the strum | D minor | 3 |
| the Glass Hills | D | leaning, on a day in G | glass | meltwater from the frost | none, long tones: time with no beat | the Armonica: holding a note over a change and letting it settle | B minor | 5 |
| the Reed Mouths | B♭ | floating, on a day in F | reeds and breath | the delta's mouths | long rounds that all land on one: breath as time | the Mouth Organ: the ground | G minor | 5 |
| the Bell Meadow | A | leaning, on a day in D | bells and pendulums | the mill-race | six, danced as three against two: counting six two ways | the Belfry: the two thirds; an order as a tune | F♯ minor | 5 |
| the Rain Steps | E♭ | floating, on a day in B♭ | drops, puddles, caps and gutters; delay | the one the cloud is holding | rain's own: finding a beat in what has none | the Cistern: a tune sung slowly is a chord | C minor | 5 |
| the Highway | E | leaning, on a day in A | wire, tarmac and salt; distance | the old inflow of the salt lake | twelve, shuffled: the shuffle and the backbeat | the Looper: layers; twelve bars; the low seventh | C♯ minor | 5 |
| Verbena Hollow | A♭ | floating, on a day in E♭ | petals and thorns | the spring in the hollow | six, counted two ways at once: time that runs down and is wound up | the Music Box: writing | F minor | 5 |
| the Chrome Nave | B | leaning, on a day in E | chrome, springs, cones and relays | the channel under the windscreen | hits spread as evenly as they will go: the machine's sixteen | the Organ: a voice built from overtones | G♯ minor | 5 |
| the Aster Steps | D♭ | floating, on a day in A♭ | panes of glass over things that don't move | the cascade down the terraces | stillness, then seeds falling in threes: the rest | the Bell Jar: silence; the half step; the lean's twin | B♭ minor | 5 |
| the Seam | F♯ and G♭ | leaning from a day in B, floating from a day in D♭ | everything, a little off and all connected | the lake's way out, under the bridge | four, dead straight: the grid, and what swing does to it | the Piano, with the Metronome under it: the treaty | D♯ minor | 5, 6 |

## The wonders

- **The notebook's 144,** twelve to a land, come in with their lands: the Garden's in 3.4, the
  Alfalfa's in 3.5, the Porch's in 3.9, and the rest in leg 5.
- **The eighteen new ones** come in with the rule each is the test of. Where each stands in the
  world is not placed by the direction, and the land given here is a proposal.

| wonder | comes in with | step |
|---|---|---|
| 1. The three landings | what is underneath | 3.7 |
| 2. Two mouths | the cave under the Alfalfa | 3.5 |
| 3. Home, hollowed | the cave under the Alfalfa | 3.5 |
| 4. The note beneath the note | going under | 1.27 |
| 5. The four winds | the compass on the lake | 2.13, whole in 5.8 |
| 6. The twin | the lean's twin across the lake | 5.8 |
| 7. The step that stays | what moves least | 3.8 |
| 8. The gap that closes | the seventh in Hum's voice | 5.7 |
| 9. Two become one | what moves least | 3.8 |
| 10. The loom | four voices | 5.9 |
| 11. The stone that waits | what moves least | 3.8 |
| 12. The slow slide | what moves least | 3.8 |
| 13. The rut | the pocket | 1.23 |
| 14. Lifting and setting down | the beat as a small key | 1.23 |
| 15. Ahead and behind | the pocket | 1.23 |
| 16. Long and short | swing | 1.23 |
| 17. Turn it around | the clap setting the one | 1.23 |
| 18. The rest | rests | 1.23 |

## Morgan's calls

Each is his: from `the-game.md`, "Yours", or a row marked open in "What the older notes had, and
where each stands". None of them stops the road. The last column is what stands in until he says,
and it never builds anything new out of the older notes.

| the call | the road reaches it at | until he says |
|---|---|---|
| every sound; every number in the body | every step | measured first; then his ears, and the bench |
| what soft does under Hum; whether grass parts for the line of sight; whether Hum's light shows on what hides him | 0.5 to 0.7 | as `docs/engine.md` proposes: a soft thing sags or parts and is never passed through; thin things part for the eye; his light shows as a dim ring |
| the clap, now that L1 steps the chord | 1.4 | L1 and R1 together as built, and a clap takes back the chord step that came with it, as it already takes back a call (proposal) |
| the sprint | 1.8 | as built: the right face held |
| the breath: what spends it | 1.17, 1.18 | a swell stores it and rests give it back; the wheel costs nothing; the sprint as built |
| who first sings the third with Hum | 1.26 | a voice and a light, with no face and no name |
| how the past is drawn (the older notes' sun-print blue) | 1.28 | in a thing's own colour, thin and still |
| the day's length | 1.31 | the code's 1,080 seconds of daylight |
| Gentle and Fierce | 1.32 | as built: the wider timing the code calls Gentle |
| who sat on the pool's edge | 1.34 | the figure the code already shows for a moment, with nothing said of who |
| dreams that find shortcuts; sleep that makes you better | 1.36 | not built |
| the world's size | 2.1 | nothing stands in: 2.1 is the asking |
| Jeanne and her compass | 2.13 | the four winds are places; Jeanne is not built |
| what a creature leaves | 3.4 | nothing |
| who the friends are, their names, and which land each lives in | 3.6, 5.6 | the notebook met them in the Alfalfa, the Glass Hills, the Highway and the Rain Steps; in 3.6 the second voice is a low one with no name |
| who sat in the chair | 3.9 | the chair rocks, and it is empty |
| the sky's detail | 3.10 | a first cut: the layer above, reached when a land floats (a proposal for its planets is in `docs/engine.md`) |
| the caravan, the white cat and the fly: their parts | 3.11 | they are in the world, and have no part yet |
| how many lives there are, and their rounds | 3.11 | as many as each land needs, kept by the day's key only |
| whether every line is sung; the seven answers | 3.11 | at most one line of words, as now |
| each land's own tuning | 5.1, 6.8 | every land's own music is tuned pure, as Hum's chords are |
| who the vine is; the odd and even passage | wherever he places them | nothing touches them |
| which of the three things at the gap are endings | 6.4 | all three can be done, and none of them ends the game |
| the islets, the Shimmer, the country with no octave; free choice of notes; lives over years; the card | 7.8 | not built |
| the name of the game | 8.3 | Gameguy, the working name |
| the repository's visibility | 8.7 | private |

## Proposals this road makes

These are mine, new on 2026-11-26, and none is decided. Each is marked where it stands above.

1. **A rule comes in with a wonder that needs it,** and so the six wonders of "when" live in the
   Garden (1.23).
2. **The whole wheel exists bare from leg 2,** and the rest of the road makes it whole.
3. **The bench** (1.2): a page where he sets the numbers himself.
4. **A clap takes back the chord step that came with it.**
5. **The Garden's first knots come home by the amen, and the Great Knot is the seam** (1.32, 3.4).
6. **The wolf's valley lies on the border of Verbena Hollow and the Rain Steps** (6.2).
7. **The lands are made whole outward from the Garden by fifths,** sharpward and flatward in turn,
   the Seam last.
8. **Two consoles come before the other nine lands** (leg 4), so that every land after is built for
   two.

The engine's own proposals are in `docs/engine.md`: what soft does, parting for the line of sight,
Hum's light on what hides him, the mix's count of roughness, and three for the game from the field
of data sonification.

## What could go wrong, and what would show it early

| what | what would show it early | where the road meets it |
|---|---|---|
| a change of chord is still faint: he "kinda" sees it | his hands on 1.6 to 1.15; if they say no, the hands change before anything else is built | leg 1, A and B |
| too much answering at once sounds rough: the try-out's first version measured 47% | the ears at every step, against the same hands without it | every step |
| lands made of long sounds (the Glass Hills, the Reed Mouths, the Cistern), when held tones are what his ears liked least | a sketch for his ears before any of the three is built | 5.1, 5.2 |
| the purple can't draw or sound the whole world | 2.16, with every land there and bare | leg 2 |
| the band needs six held voices and the bank has four | the sound's own bench (`game/bench/speaker.zig`), run with six | 3.6, 5.6 |
| a save strands whenever the world's layout changes, and it will change at nearly every step | 1.38: what lasts is kept in a file of its own | leg 1 |
| twelve lands, each with twelve wonders, an instrument, people and creatures, is more than can be made one by one by hand | 3.14: the cost of one land, counted | leg 3 |
| the stick's click is awkward under a thumb that is steering | 1.27, both ways on the bench | leg 1 |
| half a push of the stick is hard to hold: the stick is read 56 to 58 times a second | his thumb on 1.18; the thresholds on the bench | leg 1 |
| two consoles can't be in time at their speakers | nothing is built to need it (4.3) | leg 4 |
| the link drops, or needs the port's 5 V | 4.4; never without his word | leg 4 |
| all the rules are one file of 6,888 lines with the Garden built into it | 0.3 and 0.11 take the kinds out of the rules, and 1.24 and 2.2 take the place out | legs 0, 1 and 2 |
| a world that hides and moves by table costs the purple more than the sums say | 0.12, before the evening is built on it | leg 0 |
| I can't hear | the ears, sketches, and Morgan | every step |
| a theory table goes wrong as it is turned into code | the checks run with the tests | 0.1 |
| two things done together need the same digit | the digits are named before a control is called done | every control |

## Nothing left out

Every section of the three documents, and where the road builds it.

### `the-game.md`

| section | where |
|---|---|
| In one breath | the whole road |
| What I had wrong | nothing to build: it is why the hands come first |
| The first hour, as played | leg 1 |
| The wheel is the map | 2.2, 2.6 |
| A day has a key | 2.5, 2.7 |
| Three faces above, three below | 2.8; whole in 3.10 and leg 5 |
| The lake, the ice and the rivers | 2.3, 2.4; 1.34; 3.12; 5.11; 6.1 |
| The island | 1.39, 2.5, 2.14, 3.12, 5.11, 6.6 |
| Night, and what the river is | 1.35 to 1.40 |
| The hands | leg 1; the D-pad in 3.6; the top face in 3.2 and 3.11 |
| What holding R1 does | 1.18; carrying the day in 5.7 |
| The rules, 1 to 7 | 0.9; 1.5 to 1.10, 1.18; rule 7 at the size of a place in 2.9 |
| One note, six bodies | 1.8, 1.20, 1.28 |
| Coming home, four ways | 1.9, 1.29 |
| Outside the key | 1.18, 1.19, 2.9 |
| A day | 1.31, 1.35, 2.15, 3.11 |
| In every land | "What making a land whole means"; legs 3 and 5 |
| Trouble | 1.32, 1.33; 5.10; the wolf and the ice in 6.1 and 6.2 |
| What grows | the 1 and the 3 are in the build; the 5 in 1.26; the 2 in 3.6; the 7 in 5.7 |
| A newcomer and a master | 1.15, 3.2, 8.1, 8.2 |
| Tuning | pure in 1.5 and 1.19; the lake in 2.12; the ice in 2.4 and 6.1; the wolf in 6.2; the last river in 6.3 to 6.7 |
| The story | 1.26, 5.7, 6.4, 6.5, 7.1 |
| Two consoles | leg 4 |
| Where the game stands, and what I would build first | leg 1, in that order |
| Step one, as a try-out on the purple | 1.1, 1.3 |
| What is sure, and what is still a bet | "What it settles", in each leg |
| What I am dropping or parking | nothing to build; the dial comes back in 6.7 |
| What the older notes had, and where each stands | "Morgan's calls" |
| Yours | "Morgan's calls" |
| The arithmetic | "The theory, checked" |

### `the-depths.md`

| section | where |
|---|---|
| The third: what I said wrong | 1.26; the Wind Harp in 3.5; the Organ in 5.4 |
| Six questions, and where each lives in the hands | legs 1 to 3 |
| It is a cave with two mouths | 3.5 |
| Your second picture is a compass | 1.20, 2.13, 5.8 |
| Your third picture is the long way home, on one finger | 1.4, 1.18, 1.29 |
| What is underneath | 1.5, 3.6, 3.7 |
| What moves least | 1.5, 1.16, 3.8, 5.7, 5.9 |
| The beat is a small key | 1.10 |
| Hum's body keeps time | 1.11 |
| The pocket is yours | 1.22, 1.23 |
| The pocket is the remainder, in time | 6.4 |
| A thing's pulse is its interval | 1.32, 5.10 |
| Each land has a feel | "The twelve lands" |
| The great instruments | "The twelve lands"; 3.4, 3.5, 3.9, leg 5 |
| Wonders | "The wonders" |
| Endless composition | 1.36, 3.2, 3.3, leg 7 |
| What this changes | 1.4, 1.8 |
| Two sketches for the ears | sketches j and k, still for his ears |
| The arithmetic | "The theory, checked" |

### `the-wormhole.md`

| section | where |
|---|---|
| What he teaches | nothing to build: it is where part three comes from |
| What the design already had, under other names | nothing to build |
| 1. Outside the key is a wormhole | 1.18, 1.19, 2.9 |
| 2. The elevator | 1.20 |
| 3. A wide chord is a band of colour | 1.21 |
| 4. Root, costume and voicing are the three hands | 1.4, 1.17, 3.6 |
| 5. The counter melody | 3.6 |
| 6. His grooves are the vocabulary for "When" | 1.10, 1.22 |
| 7. The night's eight bars must not be an exact repeat | 1.36 |
| 8. Melody is the main character | 1.5, 1.16, 1.26, 1.31, 3.6 |
| Why it compounds | 1.17 to 1.21, and every friend who joins |
| Two sketches | sketches l and m, still for his ears; 1.19, 1.16 |
| The arithmetic | "The theory, checked" |
| Sources | nothing to build |

## The next step

0.1, the music as its own module, with 1.2, the bench, beside it, since every number after needs it.
1.1 waits for the purple to be on the cable.
