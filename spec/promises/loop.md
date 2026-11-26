# Promises of the loop, memory and the card

> **Status, 2026-11-26.** History: part of the promise book, retired as a frame on 2026-11-25
> (Morgan: other models "treated the experiments as settled commitments and built process machinery
> on top of them"). The build still runs `spec/tools/promises.py --zig` to write the list the game's
> witness code reads; nothing else uses it. Don't extend it. What the game is: `design/the-game.md`.

_Part of the promise book (`../promises.md`). What `../../SPEC.md` section 13 says, sized before the
stage that builds it. `memory.md` holds the ground's light; `workshop.md` holds takes and saves._

### `loop.river` The river sings your day back

- **Said:** `SPEC.md` "At dusk the river sings your day back, backwards from a big win."
- **Stage:** 2
- **The moment:** At dusk you sit by the river and it sings your day back to you, the biggest moment
  first and then backwards to the morning, in your own notes.
- **A cheat would be:** a replay video with music laid over it.
- **Full size:**
  - `owed` The day's take is found again by the river and its biggest moment chosen by a sum over
    the world's witnesses; the river plays it backwards from there, through the world's own
    resonators.
- **Asks:** Did the river's song sound like your day?

### `loop.echoes` Echoes

- **Said:** `SPEC.md` "You keep up to four takes as echoes." "The rest walk into the water, and the
  water keeps them." "Echoes are flat blue selves that walk, fight and sing beside you, always
  retuned into today." "They age by mornings travelled, set and rise on the wheel, and on their
  eleventh dusk step in front of you: let it go, sing it again, or turn away."
- **Stage:** 2
- **The moment:** On the second morning a flat blue Hum walks beside you, doing what you did
  yesterday, in today's key. On its eleventh dusk it steps in front of you and waits.
- **A cheat would be:** a ghost that replays positions only, out of key.
- **Full size:**
  - `owed` A test: an echo is a take played by a second Hum in today's world, retuned to today's
    home; at most four are kept, and the fifth walks into the water.
  - `owed` A test: an echo ages a morning for each morning travelled, and steps in front of Hum on
    its eleventh dusk.
- **Asks:** Did your echo feel like you?

### `loop.release` What you let go becomes the place

- **Said:** `SPEC.md` "What you let go becomes the place. A released take plays through the lake
  again
  and again until only the lake's own ringing is left." "Pools play it back for a phrase, the vine
  hums it, and on the tenth morning it rains." "The Grid is a day that changed nothing. Only that
  sets grey."
- **Stage:** 2
- **The moment:** You let an old echo go. For days after, a pool plays a phrase of it back as you
  pass, the vine hums it, and on the tenth morning it rains.
- **A cheat would be:** a counter of released echoes.
- **Full size:**
  - `owed` A test: a released take plays through the lake, losing a little each time, until only the
    lake's own overtones are left.
  - `owed` A test: a day in which nothing changed sets grey, and only that does.
- **Asks:** When something you let go came back as rain, did you notice?

### `loop.dreams` Dreams join paths

- **Said:** `SPEC.md` "Dreams join paths. Sleep eases what you practised."
- **Stage:** 2
- **The moment:** You practised a hard walk home all evening and failed it. In the morning it is a
  little easier, and you find yourself where two of yesterday's paths cross.
- **A cheat would be:** a difficulty slider that drops after failures.
- **Full size:**
  - `owed` A test: a walk practised the day before has a wider window the next morning, by a sum of
    the tries in the take.
- **Asks:** Did anything come easier after a night's sleep?

### `loop.pools-remember` Pools hold what happened beside them

- **Said:** `SPEC.md` "Pools hold what happened beside them: each of a pool's overtones is one
  memory,
  and the deeper ones need notes you don't have yet."
- **Stage:** 2
- **The moment:** You come back to the bridge puddle and the pollen is still lying in the cross and
  the ring you sang there last night. Hum its note again and it plays back the last phrase sung
  beside it.
- **A cheat would be:** a sound clip triggered near the pool.
- **Full size:**
  - `test pollen on a standing pool gathers on its still lines, and stays there when it stills` A
    puddle keeps the figure of the last note that stood in it.
  - `owed` Each of a pool's shapes keeps the last phrase sung beside it that stood in that shape,
    and plays it back when that shape is sung again; the deeper shapes need notes Hum doesn't have
    yet.
- **Asks:** Did a pool remember something you had forgotten?

### `loop.book` A page a day

- **Said:** `SPEC.md` "The book has a page a day." "Songs leave as sound, as notes and as separate
  tracks."
- **Stage:** 2
- **The moment:** Each night the book gains a page: what you heard, drawn as it looked, and your
  day's
  song, which you can take off the card and play anywhere.
- **A cheat would be:** a list of achievements.
- **Full size:**
  - `owed` A page made each dusk from the day's take: the day's song kept as sound, as notes and as
    a track for each voice, written to the card (`design/the-card.md`).
- **Asks:** Would you show someone a page from your book?

### `loop.card` A card is a number of years

- **Said:** `SPEC.md` "The card's room is spent on two things (spec/size.md). Nothing is a copy:
  every
  aster, leaf and blade of grass is its own shape and stays as it is left." "And nothing is
  forgotten: the ground keeps the light of what was sung on it, every dawn's save is kept so any
  morning of your life in the game can be walked again, and each day's song is kept as sound." "A
  card is a number of years."
- **Stage:** 2
- **The moment:** A year in, you open the book at the morning you first met Drip and walk it again,
  and it is all there.
- **A cheat would be:** saves overwritten; one aster copied a thousand times.
- **Full size:**
  - `test a dawn's save is kept and opened again a hundred dawns later` Every dawn's save is kept.
  - `fact save.bytes <= 1000000` A dawn's save is small enough for a dawn a day for decades.
  - `owed` Every thing its own shape, kept on the card and loaded as Hum walks (`spec/stages.md`,
    stage 1).
  - `owed` Each day's song kept as sound; how many years a 32 GB and a 64 GB card hold, measured
    from the sizes.
- **Asks:** Did it feel like the game remembered everything?

### `loop.mornings` Days are mornings played

- **Said:** `SPEC.md` "The handheld doesn't know how long it was off (measured). Days are counted in
  mornings played, never by the calendar."
- **Stage:** 2
- **The moment:** You don't play for a month. When you come back the world is where you left it,
  waiting for its next morning.
- **A cheat would be:** a world that moves on while you are away, or punishes you for it.
- **Full size:**
  - `fact world.clock_reads == 0` The world and what it keeps never read a clock: a check over the
    source.
- **Asks:** nobody: the source answers it.
