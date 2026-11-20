# Promises of the design's rules

_Part of the promise book (`../promises.md`). What `../../SPEC.md` section 5 says: the rules every
part of the game is held to, sized so that each has something that would show it broken._

### `rules.human-first` Human first

- **Said:** `SPEC.md` "Human first. Every part starts from something a person feels: calling and
  being
  answered, being seen, losing a voice and finding it, keeping and letting go." "The mechanic and
  the code come after."
- **Stage:** 2
- **The moment:** Every wonder in the Garden is remembered as something that happened to you, not as
  a rule you learned: the night the puddle held you up, the morning Drip sang with you.
- **A cheat would be:** a feature list with a story painted on afterwards.
- **Full size:**
  - `owed` Every promise in this book has its moment written before its full size, and the tool
    refuses one without (it does); a reader with fresh context grades each of the stage's moments
    against what was built, and none is graded "a mechanic with a story painted on".
- **Asks:** Which moment from the Garden would you tell someone about?

### `rules.consonant` Dissonance going somewhere

- **Said:** `SPEC.md` "Dissonance is brief and always going somewhere." "The comma is felt in the
  story and the world, and heard only in a few earned seconds."
- **Stage:** 2
- **The moment:** The two notes beside Drip waver against each other, a little less with each
  breath,
  and then stand still. You never sit in a sour sound; when one comes, it is on its way out.
- **A cheat would be:** dissonance avoided by never letting two things sound together.
- **Full size:**
  - `fact ears.breath4_beats <= 0.6` The breaths' beating dies away as they lock.
  - `fact ears.hold_beats <= 0.02` And once locked, the two do not beat at all.
  - `fact ears.pool_near_note_db <= -30` Standing water adds nothing rough near the note it sings.
  - `owed` A measure over a whole take: no roughness lasting longer than the moments `laws.md` lists
    for it.
- **Asks:** Was there a sound you wanted to get away from?

### `rules.ears` Morgan's ears judge every sound

- **Said:** `SPEC.md` "Fable can't hear, so Morgan's ears judge every sound idea from a short sketch
  on
  the handheld's own speaker."
- **Stage:** 2
- **The moment:** Morgan sits with the handheld, hears a sketch, and presses yes or no; the answer
  is
  in the log, and the sound is built or dropped on it.
- **A cheat would be:** a sound kept because a number said it was consonant.
- **Full size:**
  - `owed` Every one of the 31 clips in `design/listen/` has Morgan's answer in a room log, read and
    folded into the specification.
  - `owed` Every sound added in the stage has a clip and an answer before it is called done. Clips
    32 to 36 are cut from the game's own evening (`game/tools/clips.py`): the water singing back,
    the bee, underfoot, wonder and the amen; the answers are owed.
- **Asks:** Did any sound in the game surprise you badly?

### `rules.no-tables` Nothing matched by hand

- **Said:** `SPEC.md` "Nothing is matched by hand, and no effect is looked up in a table that the
  laws
  in spec/laws.md could produce."
- **Stage:** 2
- **The moment:** You try something nobody wrote down, humming at a puddle in another voice, and the
  world answers by the same laws as always.
- **A cheat would be:** a table that says which note opens which door.
- **Full size:**
  - `test a pool hummed at its note stands in that shape, and holds Hum on its still line across`
    The puddle's figure comes from the Bessel functions and Hum's overtones, not from a list.
  - `test a rung bell rings its kin, and they ring theirs, more faintly each time (law 1)` Kin are
    found from overtones, never listed.
  - `owed` A check over the source: no table in the rules that a law could produce (`whole.true`).
- **Asks:** Did something work that you didn't expect to?

### `rules.no-notes` You never choose a note

- **Said:** `SPEC.md` "In the first turn you never choose a note. You choose a moment, a home, a
  voice
  and a mood, and everything lands in key and in time." "Choosing notes is the ending's gift."
- **Stage:** 2
- **The moment:** You can't play a wrong note. You choose when, and where home is, and the world is
  in
  key around whatever you did.
- **A cheat would be:** wrong notes made impossible by a filter laid over free playing.
- **Full size:**
  - `owed` A test: whatever the hands do, Hum's hum and call are on home's note, and home moves only
    by the wheel and the swell.
  - `owed` After the thirteenth morning Hum chooses its notes, by the fifths walked and the third
    given (stage 5).
- **Asks:** Did you ever feel you'd played a wrong note?

### `rules.transform` Nothing dies

- **Said:** `SPEC.md` "Nothing dies. Things transform. You can't die either: the sun sets on you."
- **Stage:** 2
- **The moment:** A wolf sung to sleep curls up and becomes a stone that hums its note. When your
  breath and your light give out in a fight, the sun sets on you, and you wake at the next dawn
  where you lay.
- **A cheat would be:** a game-over screen with a softer name.
- **Full size:**
  - `owed` A test: nothing in the world is ever removed; a thing that is beaten becomes another
    thing, kept.
  - `owed` A test: Hum worn out in a fight is carried to the next dawn, and keeps everything.
- **Asks:** Did anything ever feel lost for good?

### `rules.no-hud` Nothing on the screen that isn't in the world

- **Said:** `SPEC.md` "Nothing on the screen that isn't in the world. No meters, no map screen, no
  menus in play." "At most one line of text, large."
- **Stage:** 2
- **The moment:** The first evening has one line of words, "Oh. You're in.", and it is the only text
  you ever see while playing.
- **A cheat would be:** a breath meter in the corner, made pretty.
- **Full size:**
  - `fact hud.text_lines <= 1` In play, one place draws a line of words: a check over the source.
  - `owed` A reader with fresh context looks at every kept frame and finds nothing that is not in
    the world.
- **Asks:** Did you ever want a meter or a map?

### `rules.lines` Lines of light

- **Said:** `SPEC.md` "Lines of light on black, drawn the way an oscilloscope's beam draws." "Hum
  and
  the voices riding on it are the only solid things." "The code enforces it (section 15)."
- **Stage:** 2
- **The moment:** A world of bright lines on black, and one small solid creature in it, which is
  you.
- **A cheat would be:** filled shapes lit to look like lines.
- **Full size:**
  - `fact beauty.place_black_least >= 0.5` Every kept frame of the place is at least half black.
  - `owed` A check over the source: only Hum and the voices on it are drawn as lit solids; every
    other shape is black, there only to hide.
- **Asks:** Did it look like light, or like a drawing of light?

### `rules.alone` Whole alone

- **Said:** `SPEC.md` "Whole alone. No door, fight or land needs a second console."
- **Stage:** 2
- **The moment:** JJ's handheld is in a drawer, and the Garden is all there, every door of it.
- **A cheat would be:** a door that says "come back with a friend".
- **Full size:**
  - `owed` The scripted player finishes the stage with one console.
- **Asks:** Did anything ever feel shut because you were alone?

### `rules.original` Original

- **Said:** `SPEC.md` "Original. No existing game's world, characters, music or look."
- **Stage:** 2
- **The moment:** Someone who has played everything watches you play and can't say what it is like.
- **A cheat would be:** a known game's world, renamed.
- **Full size:**
  - `owed` A reader with fresh context, shown the kept frames and the specification, names no
    existing game it copies.
- **Asks:** Did anything remind you of another game too closely?

### `rules.morgans-layer` Morgan's layer stays his

- **Said:** `SPEC.md` "Morgan's own layer stays his. Who the vine is, who sat on the pool's edge and
  in
  the chair, and the odd and even passage are never filled in for him."
- **Stage:** 2
- **The moment:** The vine sings, and nobody says who it is.
- **A cheat would be:** a caption that names them.
- **Full size:**
  - `owed` Morgan reads what the game says of the vine, the pool's edge and the chair, and says it
    is still his.
- **Asks:** Is it still yours?
