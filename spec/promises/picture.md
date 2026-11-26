# Promises of sound and picture

> **Status, 2026-11-26.** History: part of the promise book, retired as a frame on 2026-11-25
> (Morgan: other models "treated the experiments as settled commitments and built process machinery
> on top of them"). The build still runs `spec/tools/promises.py --zig` to write the list the game's
> witness code reads; nothing else uses it. Don't extend it. What the game is: `design/the-game.md`.

_Part of the promise book (`../promises.md`). What `../../SPEC.md` section 15 says: how a sound is
seen, and how the sound is made, sized before the stage that finishes them. `texture.md` holds the
promises of the texture of the world, and `workshop.md` the beam and the hue the engine owes._

### `picture.looks-as-it-sounds` How a thing looks is how it sounds

- **Said:** `SPEC.md` "How a thing looks is how it sounds (spec/texture.md). A thing's light is its
  loudness spread over its lines; the depth of its colour is how much of its sound is note; a
  sounding line stands in the shapes of its own overtones; what it is made of is the grain of its
  line." "Octave is height. Loudness is brightness, and silence is dark." "Timbre is the texture of
  a line."
- **Stage:** 2
- **The moment:** With the sound off you can still tell which bell is ringing, how loud, and whether
  it is a bell or a string: you can read the sound off the picture.
- **A cheat would be:** lights that flash when a sound plays, the same for every sound.
- **Full size:**
  - `test a cue can't be made with a sound and no light, or a light and no sound` A sound's light is
    its own numbers through one mapping: its note is its colour, its loudness its brightness.
  - `test what lights a thing by ringing is what sounds it` Light and sound come from one
    happening.
  - `owed` Octave as height and timbre as the grain of a line, for every family (`light.hue`).
  - `owed` A sounding line stands in the shapes of its own overtones (`texture.md`).
- **Asks:** Could you tell what was sounding with the sound turned off?

### `picture.interval` An interval is a figure

- **Said:** `SPEC.md` "An interval is the figure between two voices: still when pure, turning at the
  beat rate when tempered." "Phase is things moving together." "Depth is the third note." "Out of
  tune is never blur. It is two crisp copies sliding against each other on the beat, or flat where
  it should be deep."
- **Stage:** 2
- **The moment:** Beside Drip the figure between your two voices turns, slower with each breath,
  and stops when the two are true; under you both a third note comes in, deeper than either.
- **A cheat would be:** a blur filter that lifts as the notes come into tune.
- **Full size:**
  - `test four breaths on the tick bring the drip's fifth true, and the figure stops` Still when
    pure, turning at the beat rate when not.
  - `test two voices together make a third between them, and one alone makes none` The third note
    is the square of the voices' sum, as air makes it.
  - `fact ears.third_note_db_over_quiet >= 30` Read back from the sound itself.
  - `owed` Phase seen as things moving together, wherever two things share a rate (law 3).
- **Asks:** When the figure stopped, did you feel the two of you lock?

### `picture.afterglow` Afterglow is memory

- **Said:** `SPEC.md` "The beam. Things that sound leave a short afterglow." "Afterglow is memory: a
  low lake forgets and trails die fast."
- **Stage:** 2
- **The moment:** A bell rung in the dark leaves a ghost of its rings that fades as its sound does.
  Later in the game, when the lake is low, trails die almost at once, and you notice what the world
  has stopped remembering.
- **A cheat would be:** a motion-blur effect.
- **Full size:**
  - `frame evening-answer` The rings a call left, fading behind it.
  - `owed` The lake's level sets how long afterglow lasts, from a breath to for good
    (`card.ground`).
- **Asks:** Did the fading light feel like something remembering?

### `picture.backlight` The backlight is the sun

- **Said:** `SPEC.md` "The backlight is the sun. The game sets the screen's backlight itself: nearly
  off in the first dark, low at 2am, up at noon, and breathing a little with the music." "It is more
  than half of what the idle handheld draws, so dark hours are also long hours on the battery."
  "Morgan's eyes decide whether the breathing stays."
- **Stage:** 2
- **The moment:** In the first dark the screen itself is almost off, and the handheld in your hands
  is as dark as the world on it. When the day comes up, so does the screen.
- **A cheat would be:** a black picture on a screen at full brightness.
- **Full size:**
  - `fact dark.first_backlight <= 20` The backlight's first level, of 255.
  - `owed` Morgan's answer in the room to the backlight check: does the breathing look good?
  - `owed` Measured on the handheld: how much longer the battery lasts in the dark hours than at
    noon.
- **Asks:** Did the screen's own light feel like the day?

### `picture.physics` Made from the same physics

- **Said:** `SPEC.md` "Made from the same physics. Every sound is resonators being struck, bowed,
  blown or sung: no recordings are needed." "Each place's echoes are worked out from its shape and
  kept on the card."
- **Stage:** 2
- **The moment:** Every sound in the Garden is something ringing because something touched it: no
  sound you hear was recorded.
- **A cheat would be:** a sample library behind a few synthesised showpieces.
- **Full size:**
  - `test the same cues make the same samples` One bank of resonators makes every sound in the game.
  - `test a held tone is a clean sine at its note, and eases in and out` Standing water is a
    resonator too.
  - `owed` Each place's echoes worked out from its shape on the laptop and kept on the card, tried
    on one place first (`spec/engine.md`).
- **Asks:** Did anything sound fake?

### `picture.speaker` The speaker is the floor

- **Said:** `SPEC.md` "The speaker is the floor. Low voices are built from upper overtones and the
  ear
  supplies the root." "Nothing essential is in stereo or deep bass. Headphones add space."
- **Stage:** 2
- **The moment:** Doorstop's low oo comes out of the handheld's small speaker as a low voice, though
  the speaker can't play its root: you hear the root anyway.
- **A cheat would be:** a bass that only exists in headphones.
- **Full size:**
  - `owed` Measured with `ears`: each low voice's overtones above 300 Hz carry its pitch, and a
    listener hears the root through the speaker (a clip in the room).
  - `owed` The game is whole in mono: a check that nothing essential differs between the two
    channels.
- **Asks:** Did the low voices sound low through the speaker?

### `picture.seeing` A seeing option

- **Said:** `SPEC.md` "A seeing option: heavier lines and a lifted floor for blacks."
- **Stage:** 2
- **The moment:** For eyes that need it, the lines thicken and the blacks lift a little, and the
  world is still made of light.
- **A cheat would be:** a high-contrast mode that turns the lines into filled shapes.
- **Full size:**
  - `owed` A choice in the songbook that thickens every line and lifts black to a dark grey; every
    kept frame dumped again with it and looked at.
- **Asks:** Was everything easy enough to see?
