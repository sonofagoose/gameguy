# Shape 2: Volta, the day that never quite repeats

Brainstorm, 2026-11-13. Nothing here is decided. Morgan asked for "a different shape with even more
depth and immersion" after `shape-1-a-musical-zelda.md`.

When a passage of written music repeats, the bracketed ending you take on the second time through
is a *volta* ("prima volta, seconda volta": first time, second time). In Italian the word means
both "time" and "turn". This shape is a day that repeats, and each time through, the ending can be
different.

It keeps almost everything from shape 1: the 3D world, the third-person camera and first-person
focus, the two wheels, the voices, combat, the harmony rule that ties everything to the circle. It
changes the spine.

> **Ear check (Morgan, 2026-11-13).** He likes the loop, the spiral, and the depth. He rejects the
> idea that kept echoes sound sour (the table under "How a kept day sounds against today"): "think
> about what a human would experience ... most of the game sounding out of tune is just going to be
> so fucking irritating."
>
> The rule from here on:
> - The game sounds consonant and beautiful by default.
> - Dissonance is brief and always resolves.
> - The comma lives in structure, in sight and in rare deliberate moments, never as a sustained
>   sound.
> - Echoes are retuned into today, so the band always sounds good. Their age shows in how they look
>   and what part they play, not in sourness.
>
> Listening tests for Morgan's ears are in `listen/` (`python3 -I design/listen/make.py` rebuilds
> them).

---

## Five shapes I considered

1. **The numb world.** The whole world is the inside of someone who has stopped feeling. "Bloom,
   touch me, please, I'm numb." Places are memories; the greying is numbness; you bring feeling back
   one sound at a time. Deeply human, but it risks being only sad.
2. **Forty octaves.** A journey across scale: inside a petal, the meadow, the sky, the planets, the
   beginning of the universe. The same law (the harmonic series) holds at every size. Wondrous, but
   cold without people in it.
3. **Entrainment.** A world of rhythms that pull each other into step: fireflies, hearts, bells,
   tides. Loneliness is being out of phase; love is two rhythms that lock and stay two. Beautiful
   physics, but on its own it is mostly a feeling.
4. **Half a world each.** Two consoles each hold half of everything; the world is only whole when
   both play. Lovely for Morgan and JJ, but then playing alone is half a game.
5. **The loop band.** A day that repeats, where your past selves stay with you as a band. This is
   the one. It is deep on its own, and it has room for the best of the other four: numbness becomes
   the enemy, the forty octaves become the hidden layers, entrainment becomes how hearts and lives
   move, and the other console becomes the ending.

## The shape in one paragraph

Each day is one loop, shaped like a song, and each day is in the next key, a pure fifth above the
last. Everything you do is recorded. At night the river carries you home, and you choose which of
the day's takes to keep. The next day your past selves walk, fight and sing beside you, each in the
key of its own day, so how they harmonise with you depends on how long ago they were. You can build
chords out of your own past, but there is one sweetness you can never make from yourself: it has to
come from someone else. Twelve days on, the morning comes back almost home, a comma sharp. The enemy
is not the loop; it is the loop closing perfectly, every day the same. The way out is not to escape
time but to let it spiral, with someone.

## Why it's deeper, and why it's Morgan's

- **His favourite games are loop games.** Majora's Mask (#1) and Outer Wilds (#6) are both built on
  a repeating span of time, where what you know is what you keep.
- **His stage is a loop stage.** The Khole Caddy book describes the show as "one figure backlit ...
  bass and guitar as the loops stack".
- **His app has four tracks.** noodles' song is four tracks (harmony, drums, bass, melody); here
  your past selves are the tracks.
- **His framework says it outright.** The Generative Self writes its loop as a repeat sign,
  `|: NOTICE → EXTRACT → CHOOSE → EXPRESS → ENCOUNTER → OBSERVE → LEARN :|`, and says "The identity
  is the loop. Not the current frame of it."
- **His poem is the calendar.** "Twelve fifths overshoot home and miss forever."

---

## The day is a song

- **Length.** Around fifteen to twenty minutes of play, to be tuned. On a handheld you can stop at
  any moment and pick the day up where you left it. You can end a day early by sleeping at the
  river.
- **Form.** The day has a song's form: dawn is the intro, morning a verse, noon the chorus, the
  afternoon a bridge, dusk the chorus again, night the outro. The music tells you the time; there is
  no clock on the screen.
  - Morgan's suite already has section names that could be the hours: CENTER STAGE, GIVEN TO FLY,
    LOVE'S TRUTH, LITTLE BIRD, SAFE AND SOUND, with "Skip to" between them. His call.
- **The river home.** At night the river carries you home: "together we can make it home safe
  downstream". The loop's machinery is something in the world, not a menu.
- **A new key each day.** Each day is a pure fifth above the last.
  - The world's lead colour moves one step round the wheel each day (warm sharps, cool flats; see
    `look.md`).
  - Creatures' songs transpose; some events only happen in some keys, the way Majora's Mask has
    first-day and third-day events.
  - An option worth testing: you choose each night whether tomorrow goes a fifth up (sharper,
    brighter) or a fifth down (flatter, darker). The spiral can be walked either way, and the comma
    comes either way after twelve steps in one direction.
- **The thirteenth morning is B♯.** On a piano it's the same key as C. Spelled honestly it is
  not C: it is C a comma sharp, home and not home. This is the reckoning (see "The ending").

## Echoes: your past selves are your band

- **Keeping takes.** Everything you do in a day is recorded: where you walked, what you struck, what
  you sang. At the river you choose which takes to keep, up to four, like four tracks.
- **Playing back.** The next day each kept echo replays its day beside you: same path, same strikes,
  same songs, sung in the key of its own day. Echoes appear in sun-print blue (see `look.md`).
- **When the world has changed.** If you changed something (a door you opened yesterday is closed
  today), the echo stops where its path breaks and hums until the way opens. Nothing explodes; it
  waits.

### How a kept day sounds against today

Because each day is a pure fifth above the last, an echo kept from *d* days ago always sits *d*
fifths below today. The arithmetic (computed for this document):

| kept from | interval with today | how true |
|---|---|---|
| 1 day ago | a fifth | exactly pure |
| 2 days ago | a whole tone | exactly pure |
| 3 days ago | a sixth | 21.5 cents sour |
| 4 days ago | a major third | 21.5 cents sour |
| 5 days ago | a major seventh | 21.5 cents sour |
| 6 days ago | a tritone | your most foreign self |
| 7 days ago | a semitone | within 2 cents of sweet |
| 8 days ago | a minor sixth | within 2 cents of sweet |
| 9 days ago | a minor third | within 2 cents of sweet |
| 10 days ago | a minor seventh | within 2 cents of sweet |
| 11 days ago | a fourth 23.5 cents too wide | the wolf |
| 12 days ago | home, 23.5 cents off | the comma |

The 21.5 cents is the syntonic comma; the 2 cents is the schisma; the 23.5 cents is the Pythagorean
comma.

Read as memory, the numbers happen to tell a familiar story. Yesterday is clear. Last week grates.
The further past turns sweet again. A year on, it howls, and it misses.

### What echoes are for

- **Chords out of your past.** One voice can't make a chord. Keep the right days and your past
  selves sing the other notes. Doors, bindings, healing and the bigger songs in the world need
  chords, so which days you keep is composing.
- **Puzzles across days.** Do one part of something today, keep the take, and do the other part
  tomorrow beside yourself. Hold a plate down with yesterday while today crosses.
- **A band in a fight.** Enemies repeat their day too, so yesterday's dodge-and-strike lands again
  in the same place. Arrange takes so your band hits from several sides. A strike that lands on the
  same beat as an echo's rings as a chord, and hits harder.

### Retune or release

- **Drift.** Echoes beat against you as days pass. That's the table above, heard.
- **Retune.** You can retune an echo into today's key: hear the past again in the present. It
  rejoins the band in tune, but it loses some purity. It's still you, slightly rewritten.
- **Release.** You can let an echo go. It walks into the river.
- **Hoarding.** Keep an echo too long without retuning it and, at eleven days old, it forms the wolf
  interval with today. It starts to howl, then it hunts you. The wolves in this shape are your own
  unreleased past.

---

## The third you can't reach alone

The centre of this shape rests on three facts:

- **Near:** stacking four of your own fifths gives a major third, but a harsh one. It comes out as
  81/64, 21.5 cents sharp of the sweet third (5/4) that makes major chords warm.
- **The long way round:** eight fifths in the other direction gets within 1.95 cents of sweet. At
  440 Hz that is one slow swell every two seconds: almost, not quite.
- **Never exactly:** multiplying 3s and 2s can never produce a 5, so no stack of your own fifths will
  ever land on the sweet third exactly.

So: near you, a harsh third. The long way round your own past, nearly sweet. Exactly sweet, only
from someone who isn't made of your fifths.

### The beloved

- **The one who remembers.** One voice in the world remembers across the days, faintly: they hum
  yesterday's melody back to you. Their voice lives on the 5, the direction your fifths can't
  reach.
- **What they change.** With them, your band's chords turn warm. Without them, your band rings
  bright and harsh, or reaches sweetness only the long way round.
- **How it grows.** The relationship grows across days by learning their days and their song, by
  singing with them, and by sharing the comma.
- **How they're seen.** The beloved may be the figure you never quite see: blurred and doubled when
  you're out of tune with them, and only in focus when you are in tune (see `look.md`). "I see you."

### Everyone has their own comma

Everyone's life in the world turns on its own interval, so everyone has their own cycle and their
own gap:

| a life that steps by | comes nearly home after | and misses by |
|---|---|---|
| fifths (you) | 12 days | 23.5 cents sharp |
| whole tones | 6 days | 23.5 cents sharp |
| major thirds | 3 days | 41.1 cents flat |
| minor thirds | 4 days | 62.6 cents sharp |

- **Lives as polyrhythms.** A three-day life and a four-day life meet every twelve days. Learning
  when lives line up (who is at the bridge on which day, and in what mood) is how you make progress,
  the way learning schedules is in Majora's Mask, but here it is literally musical.
- **Personality from the interval.** A thirds person loves fast and misses wide; a whole-tone person
  drifts dreamily; a fifths person is patient and almost comes home.
- **No maths required.** A player never needs to see any of this. They notice "she's at the bridge
  every third day" and feel why.

### Hearts falling into step

- **Clocks and fireflies.** Rhythms that touch pull each other into step. Huygens saw two pendulum
  clocks on one wall fall into step in 1665; the fireflies of the Great Smoky Mountains flash
  together.
- **The maths.** It has a simple form (the Kuramoto model): enough coupling, and a crowd of rhythms
  locks.
- **Singers' hearts.** A small 2013 study found that singers' heart rates followed the structure of
  what they sang together, most of all in slow, steady chants, probably through breathing: you
  breathe out on the phrase, and the heart slows.
- **In the game.** Your heartbeat is part of your body, heard in focus and seen in the light you
  carry. Sing with someone and the two rhythms drift into step. Over days, with the beloved, they
  lock.

### Primes as relationships (an offer, not a rule)

In tuning theory each prime is its own direction. Read as a life:

- **2** is you at another height (the same note, an octave up or down).
- **3** is you growing (your days, your fifths).
- **5** is another person (the sweetness you can't make alone).
- **7** is the blue note: what's lost, the ones who aren't here. The harmonic seventh sits 31 cents
  flat of the piano's, and it is the colour of the blues.

---

## The two dangers

### The Grid: the loop closing

In most loop games the loop is the trap and you escape it. Here the loop is how life goes, and the
danger is the loop closing perfectly: every day the same, nothing left over, nothing to want.

- **What it looks like.** Colours band into flat steps, motion stutters onto a grid, lines stop
  wobbling, the grain of the picture goes smooth (see `look.md`).
- **What it sounds like.** Everything snaps exactly onto the beat and exactly into equal temperament
  with no vibrato. "Bloom, touch me, please, I'm numb."
- **What it wants.** To fix the comma by tempering the whole world, so that day twelve really does
  equal day zero, forever.
- **How you fight it.** With what quantising removes: swing, rubato, the human remainder. Music
  software has a function called "humanize" that adds tiny timing errors so quantised music sounds
  alive. Against the Grid's soldiers, strikes laid slightly behind the beat hurt most (like the
  late trains in wasatch that "literally lay back").

### The Wolf: the past that won't let go

The Wolf is error kept pure and unshared: the echoes you neither retuned nor released. It howls,
which is the beating, and it hunts. The great Wolf lives at the seam, where the circle doesn't meet
itself.

### The way through

Neither. Let time spiral. Keep some of the past, retune some of it, release some. Share the comma
with someone.

---

## Immersion: nothing on the screen that isn't in the world

- **Breath is stamina.** You hear and see your creature breathe; silence refills it.
- **Steadiness is health.** When you're hurt, your tone wavers; badly hurt, vibrato becomes tremor
  and the music thins.
- **The time** is the section of the song you're in, and the sun's place on the sky.
- **The key** is the colour of the world.
- **Home.** Your home chord can always be heard from home's direction (stereo on headphones).
- **Paths.** Your routines wear paths into the meadow. The Grid wants you on the same path forever.
- **The map** is your songbook and the trails your echoes leave.
- **Notation is the world's old script.**
  - Repeat signs are carved by the river where the day turns.
  - Volta brackets stand at forks: first time, second time.
  - A fermata hangs over the moment you hold a wheel.
  - Breath marks mark resting places, rests mean hide, and the coda is the way out.
- **Your heart sets the tempo.** In a fight your heart races and the world's music quickens; when
  you're calm, it slows.

## The hidden layers: forty octaves

Octave travel (from shape 1) goes further than the meadow, and the same law holds at every size:

- **Inside a petal.** Things vibrate in standing waves; electron orbitals are standing waves too.
- **The meadow.**
- **The sky.** Planets in resonance: the neighbouring planets of TRAPPIST-1 go round their star in
  ratios close to 8:5, 5:3, 3:2, 3:2, 4:3 and 3:2.
- **The beginning.** The young universe rang. Its sound waves left a series of peaks in the cosmic
  microwave background, harmonics of one wave.
- **Light** is a voice, forty octaves up (shape 1, "Earlier ideas").

The way out at the end, the coda, could go up through every octave.

## Two consoles

- **You are each other's 5.** Each player is the one voice the other's fifths can't make.
- **Two bands in one room.** Each player has their own echoes, and both bands play at once.
- **Hearts in step.** The two players' hearts drift into step as they sing together.
- **The third voice in the air**, between the two machines (untested on these speakers).

## Combat in this shape

- **Shape 1's combat carries over:** lock-on, dodges, guards, sung shots, finishers that resolve
  rather than kill, and the key wheel's slowed time.
- **Enemies repeat their day.** Knowledge carries over, and your echoes' strikes land again.
- **Changing key is a held breath.** Modulating within a day doesn't last: the day's own key pulls
  you back, like gravity.
- **Bosses as pieces of music:**
  - **The Metronome**, the Grid's: a great pendulum that quantises the arena. It's beaten by
    syncopation and swing.
  - **The Wolf at the Seam**, made of your oldest unreleased echoes. Tame it by retuning them.
  - **A Knot of five against seven**, a fear that is a polyrhythm. You untie it by finding the pulse
    they share.

## The ending

The thirteenth morning, B♯, makes three offers:

- **The Grid** offers to close the circle: temper everything, and every day is the same forever.
  Safe. Grey.
- **The Wolf** offers to keep everything pure: the error stays where it is and it devours.
- **The duet.** You and the beloved hold the comma between you, and the spiral opens. The fourteenth
  morning is the first day that isn't a repeat. "It is freedom, our arrival."

With two consoles, the duet is the two of you.

---

## A day, walked through

You wake in the reeds by the river at dawn; the intro is a single held note, yours. Up the bank,
two blue figures are already walking: yesterday's you, and the you from three days back, humming.
Yesterday's hum sits a fifth below yours and it's warm. The older one is sour, and you wince a
little; you kept it for the bridge.

By noon, the chorus, you're at the bridge. The gate wants a chord. Yesterday is your fifth; you
sing the root; the older take arrives on its sour sixth and the gate shudders but doesn't open. Not
today, then.

You find her where the minor-thirds lives cross on every fourth day. She's humming the tune you
sang last time, a little wrong, the way someone remembers a song. You sing it back. For a moment
your two notes lock, and something like a third voice rings between you; you see her clearly for a
second, then she's soft again.

At dusk the Greys come up the path in perfect step. You lay your strikes just behind the beat, and
they come apart.

At night the river takes you. You let the three-days-ago take go; it walks into the water. You
keep today's, and the moment with her.

## What to test first for this shape

The echo test, in the meadow:

1. Play a minute. Keep the take.
2. Play again beside your echo, then again with two echoes.
3. Build a chord from three versions of yourself and open a gate with it.

The question: does it feel like a band? Does opening a door with your own past feel wonderful?
This can be built before the wheel test, or with it.

## Open questions

- **Length.** How long a day is, and how that fits handheld sessions.
- **How many echoes** before it's chaos (four is a guess; each echo is one more creature to draw
  and animate, which is cheap).
- **Paradoxes.** What echoes do when the world has changed under them; "waits and hums" is a first
  answer.
- **Direction.** Whether the calendar walks only sharpward, or the player chooses each night.
- **Who the beloved is.** An NPC, one of the voices, or the other console. Maybe all three at
  different times.
- **Tone.** How to carry numbness and rumination without naming them or preaching (Garden's rule
  applies: the world teaches by consequence; the words are never spoken).
- **Visible maths.** None is required; how much is offered to the curious.

---

## Sources

- Echo intervals and commas: computed for this document (pure ratios, 3/2 per day).
- [NPR: "When Choirs Sing, Many Hearts Beat As One" (Vickhoff et al., 2013)](https://www.npr.org/sections/health-shots/2013/07/09/200390454/when-choirs-sing-many-hearts-beat-as-one)
- [EurekAlert: the study's press release](https://www.eurekalert.org/pub_releases/2013-07/f-mmc070313.php)
- [Luger et al. 2017: "A seven-planet resonant chain in TRAPPIST-1"](https://www.nature.com/articles/s41550-017-0129.pdf)
- Morgan's material: the poem (brainstorm Appendix A), The Generative Self §III (brainstorm §13),
  the Khole Caddy Style Book v1.1, noodles and wasatch (brainstorm §11–§12),
  `material/morgan-pieces-2026-11-12.md`.
