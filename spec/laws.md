# The laws

_Part of the specification (`../SPEC.md`, section 7). What every thing in the world is made of, the
seven laws it obeys, and the numbers. The numbers marked "to tune" are starting values for hands and
ears to change; the forms of the laws are decided._

## What a thing is

Every thing in the world is a **body** with a place, and any number of two kinds of part:

- **Resonators.** A resonator has a family (the shape it is), a lowest note, and how long it rings.
  Its family gives its overtones. The sound thread renders each overtone as one small filter; the
  world keeps each overtone's loudness, 60 times a second, for the rules and the picture.
- **Pendulums.** A pendulum has a rate, counted in beats, and a place in its cycle. A creature's
  gait, a blinker, a rocking chair, a swinging bell-flower and a life's round of mornings are all
  pendulums at different sizes of time.

Hum is a body too: one resonator (its voice) and one pendulum (its pulse).

## The families

The overtones of real shapes, as multiples of the lowest note.

| family | things | overtones | notes |
|---|---|---|---|
| string | stems, wires, vines, the patio's strand, a guitar's strings | 1, 2, 3, 4, 5, 6, 7, 8 | plucked or struck one nth of the way along, every nth overtone is missing |
| open pipe | reeds, a hose with both ends free, downspouts | 1, 2, 3, 4, 5, 6 | |
| stopped pipe | the knotted hose, a bottle's neck, a capped reed | 1, 3, 5, 7 | odd overtones only; an octave below an open pipe of the same length |
| bar | glass rods, boards, doorstops, keys | 1, 2.76, 5.40, 8.93 | rings longest held 22.4% of the way from each end, where it doesn't move |
| fork | Hum's tuning fork | 1, 6.27 | nearly a pure tone |
| round skin | pools, puddles, leaves, drumheads, speaker cones | 1, 1.59, 2.14, 2.30, 2.65, 2.92 | not in tune with itself, which is why a pool has many notes |
| bell | bell-flowers, asters, caps, bowls | 0.5, 1, 1.2, 1.5, 2, 2.5, 3 | a made bell can be given other overtones; each land's bells carry its own third in place of the 1.2 |
| bottle | bottles, jars, the car's cabin, a guitar's body | one note | bigger inside is lower; a longer or narrower neck is lower |
| plates and odd shapes | panes, the guitar's top, a doorstop's wedge, anything else | worked out from the shape by `game/tools/modes` | kept in the thing's sound file |

A sung voice is a string-like source through three to five bottles: the bottles are the vowel. That
is how real voices work, and it is why the five voices are five vowels.

## Law 1: sympathy

Sound flows between things that share overtones.

- **How much two overtones share.** If they are `d` cents apart, they share `exp(-(d/15)^2)`:
  everything at a pure match, 98% at 2 cents (an equal-tempered fifth), 43% at 14 cents (an
  equal-tempered third), under a tenth at 23 cents (a comma), nothing at a semitone. The width, 15
  cents, is to tune.
- **How sound flows.** Each step, a sounding overtone feeds every overtone it shares with, in
  proportion to its own loudness, how much they share, the receiving material, and how near they are
  (halving at 8 paces, to tune). Felt, petals and moss take almost nothing; glass, chrome and taut
  strings take a lot.
- **What follows.**
  - Ring one thing and its kin answer across the place, each in its own light: a different
    constellation for every note.
  - Pure lands ring. Tempered lands are duller, and at the Seam "everything is a little off,
    everything connected".
  - You can only move what your voice shares something with. Doorstop's *oo* has few overtones and
    reaches octaves and fifths. Patio's *ee* has many and reaches far more, faintly.

## Law 2: gravity

An overtone falls toward the note that contains it.

- **The rule.** Take a thing's lowest note and your home. If the thing's note is home's 3rd, 5th or
  7th overtone (in any octave), the thing belongs to home, and home pulls it. If home is the thing's
  3rd, 5th or 7th overtone, you belong to it, and it pulls you. The pull is one third, one fifth or
  one seventh of full strength.
- **On the wheel** this is the canon's table:

| where it sits from home | what it is | the laws' reason | what happens |
|---|---|---|---|
| on your wedge | kin | the same note, or its octave | weightless to you; it keeps your time |
| one wedge right (a fifth above) | it leans to you | it is home's third overtone | it falls toward you; a full close brings it home |
| one wedge left (a fifth below) | you lean to it | home is its third overtone | you fall toward it; an amen sings it to sleep |
| two wedges | passing | a ninth overtone: too far to hold | you pass through each other |
| three or four wedges | warm | at four, a fifth overtone; at three, an overtone shared with neither containing the other | it doesn't move: it takes colour and grows |
| five wedges | grinding | a half step: rough | it shakes, and pushes away a little |
| straight across | far | nothing shared, and rough | your blows throw it, and its blows throw you |

- **Moving home changes everything at once.** That is the wheel's whole power, and it is why the
  same boulder is weightless one morning and falls toward you the next.
- **The seventh.** A thing that sits on home's seventh overtone is off the wheel, 31 cents flat of
  the piano's seventh. It is pulled faintly and from far away. The caravan trades in these.

## Law 3: falling into step

Things at nearly the same rate pull each other together.

- **Pendulums.** Each step, a pendulum's place in its cycle moves by its own rate, plus a pull
  toward each neighbour it can feel: `pull × sin(the gap between them)`. Two lock when the
  difference in their rates is smaller than the pull.
- **Pulls, to tune:** Hum's pulse on a creature in reach, once Hum has kept steady for a bar: 0.5.
  Between creatures of one kind: 0.05. Between parts Hum has bound: 1.
- **The clap** sets everything in reach to the start of its cycle.
- **Voices.** A voice marked as one of a crowd (reeds, a choir, a pack that has lain down) that is
  within a quarter tone of a louder, steady note slides onto it over a few beats. Nothing else in
  the game ever slides in pitch by itself, so the music stays in tune.
- **What follows:** a parade behind steady steps; parts that move as one machine while they share a
  beat; a bank of reeds finding your drone; hearts in step.

## Law 4: standing waves

A driven thing shows still lines and bellies.

- **Along a line** (a string, a wire, a pipe): the nth overtone has n bellies with still points
  between them. Hum can stand on a still point. A belly throws, harder the louder that overtone is.
- **Across a surface** (a pool, a pane, a drumhead): each overtone has its own figure of still
  lines. They are drawn as lines of light, as bright as that overtone is loud, and they can be
  walked on while it sounds. When the note dies the path goes with it, so a path lasts as long as
  someone or something keeps singing: you, an echo, a loop, a machine.
- **Between two voices** facing each other on one note: still places stand in the air between them,
  closer together the higher the note. Things rest in them. That is the bridge two Hums can hold,
  and that one Hum and an echo can.

## Law 5: cancelling and beating

Opposite sounds make silence, which is dark. Near-misses beat, and the beating turns things.

- **Cancelling.** The same overtone from two sources half a cycle apart sums to nothing. Hum can
  sing the mirror of a sound it has leaned in to, and for as long as its breath lasts there is a
  small ball of silence round it: dark, unheard, safe.
- **Beating.** Two overtones a little apart beat at the difference between them. The figure between
  the two turns once per beat. Sharp turns it one way and flat the other.
- **Turning does work.** A turning figure bound to a thing turns the thing.

| how fast the beat | what it does | where |
|---|---|---|
| none: a pure pair | locks. A clamp, a held door, a bridge that stays | the Garden, and pure pairs anywhere |
| under 8 a second | turns: wheels, winches, walkways, a slow fan | fifths in tempered lands (0.9 a second in equal temperament at middle C, 2.4 in sweet thirds) and the comma (3.6) |
| 8 to 30 a second | shakes: a sieve, a shimmer, sand that creeps | thirds in tempered lands (10 in equal temperament, 16 in pure fifths) |
| over 30 a second | roughness: it pushes the two apart | half steps, and straight across |

- **So tuning is machinery.** In the Garden nothing turns by itself. In the Glass Hills fifths clamp
  and thirds shake. At the Seam everything turns, and the city runs on it: the error it agreed to
  share is its engine.

## Law 6: travel

Sound moves at a speed you can see.

- **Speed.** About seven times Hum's run (to tune). A call's ring crosses a clearing in a breath and
  the lake in about a minute (62 seconds, `size.md`).
- **Late arrivals.** What happens far away is heard late, and seen when the sound arrives.
- **Echoes.** A wall sends a sound back after twice its distance. The return lands on the beat: the
  engine moves it to the nearest bar line, so an echo wall is a looper whose length is how far away
  you stand.
- **Fast roads.** Sound in metal, glass and taut wire moves fifteen times faster. Sing into a pipe
  and its far end sings at once.
- **Speed bends pitch.** Something coming at you sounds higher and something leaving sounds lower.
  At a ninth of the speed of sound the bend is a whole step, at a fifth it is a pure third, at a
  quarter a fourth, at a third a fifth, at a half an octave. Things that pass (a truck, the black
  train) bend as they pass. Hum's own note bends only on rides built for it, where the ride's speed
  is one of those fractions.
- **Night over water.** Sound carries further across the lake at night, when the air over the water
  is cool.
- **The lake's own slow wave** is separate: a song sung on the shore travels round the lake and
  comes back across the water about a quarter of a day later, softer and lower
  (`design/memory-in-rhythm.md`, idea 5).

## Law 7: building up

Push a thing at its own rate and it grows.

- **The rule.** A push within an eighth of a cycle of the right moment adds its whole size. The gain
  falls to nothing at a quarter of a cycle off, and beyond that the push takes energy out. Between
  pushes the thing loses a share that depends on how long it rings.
- **Three thresholds** for each thing: it **rings** (it lights and sounds), it **swings** (it moves
  what is on it), it **gives** (glass breaks, a knot opens, a seed-head scatters).
- **The same law at both sizes of time.** A bell-flower's sway is pushed on the beat. A wine glass
  is pushed 500 times a second by holding its note.
- **Taking it out.** Pushes against the swing calm it. Gentle fights end this way.

## Home over the laws

The wheel, the moods, the swell and the four cadences are in `design/the-wheel.md` and stand as
written. They sit on the laws like this:

- **Home** is the note law 2 measures everything against.
- **A mood** is where home sits among today's seven notes, and each mood is the feel of one law:

| mood | power | the law it leans on |
|---|---|---|
| wonder | Lift | standing waves: things rest in the still places |
| sunny home | Bind | falling into step: parts on one beat are one machine |
| drive | Drive | beating: a near-miss turns a wheel |
| cool soul | Flow | cancelling and travel: slip through, ride water |
| tenderness | Remember | travel: what comes back is what was sent |
| fierceness | Strike | building up, fast |
| the darkest | Break | building up, to the point of giving |

- **A cadence** is letting go of a swell with home beside the leaning thing. Which side, and how
  far, decides which of the four doors opens.
- **The groove.** Today's seven notes among twelve make a pattern of long and short gaps. The same
  pattern, as beats, is the day's bell rhythm, started from wherever home is.

## Tuning

- **The garden's note** is middle C, 261.63 Hz. Morning n is n − 1 pure fifths higher, folded back
  into the octaves round it. The thirteenth morning is 265.20 Hz: C, a comma sharp.
- **Each land tunes its own things** in its own way. Steps of the scale in cents above the land's
  note:

| tuning | lands | 2nd | 3rd | 4th | 5th | 6th | 7th |
|---|---|---|---|---|---|---|---|
| pure | the Garden, the Alfalfa, the Porch | 204 | 386 | 498 | 702 | 884 | 1088 |
| pure fifths | the Glass Hills, the Reed Mouths | 204 | 408 | 498 | 702 | 906 | 1110 |
| sweet thirds | the Bell Meadow, the Highway, Verbena Hollow, the Rain Steps | 193 | 386 | 503 | 697 | 890 | 1083 |
| well-tempered | the Chrome Nave, the Aster Steps | by key, after Werckmeister | | | | | |
| equal | the Seam | 200 | 400 | 500 | 700 | 900 | 1100 |

- **Who gives way.** The day's key sets which notes are in play. A land's own things keep the land's
  tuning. Hum, the voices and the echoes take the tuning of the land they are in, so the band always
  sounds good. At a border, one bell plays a phrase in both tunings.
- **Each land plays only the music that sounds best in its tuning:** no held thirds in the Glass
  Hills, no far keys in the lands of sweet thirds except the wolf's valley on purpose.

## Sound and light

`texture.md` carries this table all the way through: what every line looks like at rest and
sounding, what each material's line is, and the rules that keep a frame beautiful.

| quantity | heard as | seen as |
|---|---|---|
| pitch class | note | hue, by fifths: C green, sharps warming, flats cooling, purple at the seam |
| octave | register | height |
| loudness | volume | brightness; silence is dark; the backlight follows the whole |
| ratio between two voices | interval | the figure between them |
| a near-miss | beating | the figure turning, at the beat rate |
| a note, eight octaves down | too slow to hear | a pulse: the halo round a ringing thing beats at its own note halved eight times, so middle C beats about once a second and a fifth above it three times for its two |
| overtone recipe | timbre | the texture of the line |
| place in a cycle | together or loose | moving together |
| the note between two notes | the third voice | depth |
| sameness | nothing left over | flatness; pixel stairs |

## For the ears

Limits the engine keeps, so that "it sounds good" is checked and not hoped for:

- **Roughness.** `game/tools/ears` measures it. More than two seconds of sustained roughness is an
  error, except in the moments on this list, each of which is brief and resolves: a wolf's howl, the
  two suns at dawn, the dome's shiver, the close that misses, and the comma held on the thirteenth
  morning.
- **Slow beating** is allowed as shimmer where a land's tuning makes it (the Seam, the Shimmer), and
  Morgan's ears decide how much.
- **Everything a player must hear** sits between 400 Hz and 8 kHz, where the small speaker speaks.
  Low voices are built from upper overtones.
- **Out of phase is never out of tune:** hollow, then loose in time, then silent.
- **A missed beat sounds plainer, never wrong.**
