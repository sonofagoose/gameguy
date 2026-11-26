# Promises of the game's arc

> **Status, 2026-11-26.** History: part of the promise book, retired as a frame on 2026-11-25
> (Morgan: other models "treated the experiments as settled commitments and built process machinery
> on top of them"). The build still runs `spec/tools/promises.py --zig` to write the list the game's
> witness code reads; nothing else uses it. Don't extend it. What the game is: `design/the-game.md`.

_Part of the promise book (`../promises.md`). What `../../SPEC.md` sections 4, 6.2 and 7 say about
the whole: the game in one breath, the shape of a day, and things as instruments._

### `arc.one-breath` The game in one breath

- **Said:** `SPEC.md` "You are Hum, a small plaster creature who can sing one note, in a world drawn
  in lines of light where everything that sounds shines and silence is dark." "The world is a garden
  after a storm, seen from a seed's height: twelve lands round a lake, one for each key, and every
  thing in them is an instrument that obeys the real laws of sound." "Each morning comes a pure
  fifth higher." "Each night a river carries you home, sings your day back, and lets you keep four
  of your past selves as a band." "About a hundred lives keep their own cycles round the lake, each
  with a tune it can't finish." "Twelve mornings on, home comes back a hair too warm, and what you
  do with that small difference, alone or with someone holding the other console, is the ending."
- **Stage:** 2
- **The moment:** On the first evening you are small and singing one note in the dark, and things
  answer; by the thirteenth morning you have walked twelve fifths round the lake and come home a
  hair too warm.
- **A cheat would be:** any of it told in words instead of played.
- **Full size:**
  - `test nothing sounds without its light: every sound in a scripted take was told as a cue`
    Everything that sounds shines, and nothing else does.
  - `owed` Each stage's proof (`spec/stages.md`): the Garden in stage 2, the mornings in 3 and 4,
    the ending in 5, two consoles in 6.
- **Asks:** At the end, could you say what the game was about?

### `arc.day` A day is a song

- **Said:** `SPEC.md` "A day is about twenty minutes, shaped like a song, and it follows the five
  steps of Morgan's worksheet." "The music and the sun are the clock." "You can stop anywhere."
  "dawn | intro | wake at the garden; Drip hums you back in; the river post" "morning | verse |
  walk the day's land; listen to who is there today | notice" "noon | chorus | the land's great
  instrument, its packs, everything sounding | capture" "afternoon | bridge | what your kept phrases
  are made of; wonders; who wants what | extract" "dusk | chorus | the land's people gather for the
  reason they sing; the pack comes | sing" "night | outro | the river sings your day back; keep
  four; Repeat or Onward | select"
- **Stage:** 2
- **The moment:** You play a day without looking at a clock: the light and the music tell you it is
  noon, and then that dusk is coming, and you finish where the song finishes.
- **A cheat would be:** a timer on the screen.
- **Full size:**
  - `test the sun climbs the horn: each rung lights where it stands at once, and is heard late by
    its distance`
    The sun is the clock: its height is the time of day.
  - `fact world.clock_reads == 0` And nothing else is.
  - `owed` A test: a day of the scripted player lasts about twenty minutes and passes through dawn,
    morning, noon, afternoon, dusk and night in the music's sections.
  - `owed` You can stop anywhere: a take written as it is played and a save at every dawn
    (`card.takes`) mean leaving at any moment loses nothing.
- **Asks:** Did the day feel like a song?

### `arc.instruments` Every thing is an instrument

- **Said:** `SPEC.md` "Every thing in the world is a resonator with the overtones of its shape, or a
  pendulum, or both." "Home is laid over the laws. The wheel decides where home is, and law 2 then
  says what every thing is to you." "The canon's table of relations (kin, a fifth above falls to
  you, a third warms, across pushes away) is what the laws do in the simplest cases, and it stays
  the short version" "Building is instrument-making. Join resonators and pendulums and they become
  machines that play themselves: a string stretched between two stalks, a bottle on a pipe, a
  pinned wheel that plucks a comb." "Every thing has a tune, and what you do to the tune you do to
  the thing: move it up or down and the thing moves; sing it backwards and the thing runs back; sing
  it slower and the thing slows."
- **Stage:** 2
- **The moment:** You stretch a strand of grass between two stalks and it becomes a string that
  plays whenever the wind blows; hum a thing's tune backwards and it runs back the way it came.
- **A cheat would be:** objects with an "instrument" flag.
- **Full size:**
  - `test a thing answers by its own overtones, whatever its family` Every thing rings by the
    overtones of its shape.
  - `test a round skin's still rings and spokes are where the Bessel functions are nought` A pool's
    shapes are its own.
  - `owed` Pendulums, and machines joined from resonators that play themselves (law 7).
  - `owed` A test: a thing's tune moved up moves the thing up; sung backwards, it runs back.
- **Asks:** Did you ever build something that played itself?
