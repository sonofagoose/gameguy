# Promises of the lands

_Part of the promise book (`../promises.md`). What `../world.md` says of the world's shape and of
what
every land has, and what `../shape.md` says of the Garden's bowl, sized before the stage that builds
the Garden at its size. The Garden's own wonders are in `garden.md`._

### `lands.shape` The world's shape

- **Said:** `spec/world.md` "A round lake with twelve lands on its rim, in the order of the circle
  of
  fifths: the Garden at the north, sharp keys warming clockwise, flat keys cooling the other way,
  meeting at the Seam in the south." "One continuous place. There are no loading doors between
  lands." "One to a hundred. Hum stands one metre, a centimetre of the real garden, and every thing
  is its real size times a hundred (size.md)." "Sizes (size.md): the lake is 3.7 km across, and its
  shore more than a day's run round." "Each land is about 3 square kilometres: a kilometre of shore,
  two kilometres deep." "The ring is 36 square kilometres of ground, and the whole world 7.7 km
  across." "The whole shape is a spiral shore of fifths, with thirds going outward, overtones going
  up and the mirror going down (shape.md)." "Height is the octave, and an octave is 100 m." "Higher
  ground is a higher register." "The rim climbs by a hair all the way round, so at the Seam one side
  of the crack stands a step above the other: the comma, as a ledge." "The city bridges it."
- **Stage:** 2
- **The moment:** You walk out of the Garden along the shore and never pass through a door; the
  ground climbs so slowly you don't notice, until at the Seam you find yourself a step higher than
  where you began.
- **A cheat would be:** a map of rooms joined by loading screens.
- **Full size:**
  - `test the horn's rungs stand at the heights of the overtones, and the seventh never sounds`
    Height is the octave: an octave is 100 m, in the sky's horn.
  - `fact scale.one_to == 100` One to a hundred.
  - `owed` The ring of twelve lands in the order of the circle of fifths, continuous, with no doors,
    and the rim climbing a comma round to the Seam (stage 3).
  - `owed` Higher ground a higher register: a thing's note set by its height in the Garden's score.
- **Asks:** Did the world feel like one place?

### `lands.two-faces` Every place has two faces

- **Said:** `spec/world.md` "Every place has two faces. At noon everything sounds at once, quietly,
  and the land is lit from the horizon." "At 2am the field is black and you see by calling." "The
  same things are there at both hours and do different things."
- **Stage:** 2
- **The moment:** You walk the field at noon, lit and faintly ringing everywhere; you come back at
  2am and it is black until you call, and the same bells do something else in the dark.
- **A cheat would be:** a day level and a night level.
- **Full size:**
  - `frame evening-black` The field black before anything sounds: you see by calling.
  - `test the second call is answered by the drip, late by the distance there and back` In the dark,
    what answers a call is what you see.
  - `owed` Noon in the Garden, everything sounding at once quietly and lit from the horizon, and
    the same things doing other things at 2am (stage 2's day).
- **Asks:** Did the night feel like the same place, changed?

### `lands.every-land` What every land has

- **Said:** `spec/world.md` "A shape that follows from what it is made of, and three to five covers
  on its ground, each of which does something to Hum (shape.md); its own sky (sky.md); a key and a
  morning; a tuning" "A wonder is one true thing about sound, found by doing it." "It needs
  no
  fight and no words." "Finding one adds a page to the songbook, drawn by the beam." "A great
  instrument is a place you go inside." "Each has a trial for Fierce players and can be sat with on
  Gentle." "Setting it right frees the land's river." "The credits are from general knowledge and
  are to be checked against sources before the songbook is written."
- **Stage:** 2
- **The moment:** You cross the bridge puddle on its still lines and nobody tells you anything; that
  night the songbook has a page with the puddle's figure on it, drawn by the beam.
- **A cheat would be:** a wonder explained in a caption.
- **Full size:**
  - `test a pool hummed at its note stands in that shape, and holds Hum on its still line across` A
    wonder found by doing it, with no fight and no words.
  - `test fallen leaves ring underfoot and lawn sheds dew behind you, each seen at once and heard as
    late as it is far`
    Covers on the ground that each do something to Hum (`garden.ground`).
  - `owed` A songbook page for each wonder found, drawn by the beam.
  - `owed` The Hose, the Garden's great instrument, gone inside; its trial on Fierce and sitting on
    Gentle; setting it right frees the river (stage 2).
  - `owed` Each wonder's credit checked against sources before the songbook is written.
- **Asks:** Did finding a wonder feel like discovering something true?

### `lands.garden-bowl` The Garden is a bowl

- **Said:** `spec/shape.md` "Shape. A shallow bowl a kilometre and a half across, with the Mirror
  Pool
  at its lowest point." "The ground rises gently from the pool on every side to a rim of raised
  beds, each edged with a wall of brick ten metres high." "The spigot stands on the highest rise at
  the back, and the hose runs from it down across the whole bowl to the pool." "Why. A bowl
  gathers. Every sound made in it runs down to the water and comes back up, so the Garden is the
  land
  where your own voice returns to you from all sides." "It shows all seven laws gently because
  nothing in a bowl is far away." "Sound. A call from the rim is heard everywhere in it." "The bowl
  has one low note of its own, a C, which the right call at the pool's edge wakes." "Seen. The
  asters' skyline; the spigot, a monument of brass; the hose, a green river you can hear."
  "Silhouette. A low bowl of towers, with a glint of brass among them." "Hands. Easy. Gentle slopes,
  short distances, everything rings."
- **Stage:** 2
- **The moment:** You call from the rim of the Garden and your voice runs down to the Mirror Pool
  and
  comes back to you from every side; at the pool's edge the right call wakes the bowl's own low C.
- **A cheat would be:** a reverb on the whole land.
- **Full size:**
  - `fact asters.count >= 60` The asters' skyline, in the proof field.
  - `owed` The Garden's score: a shallow bowl a kilometre and a half across, the Mirror Pool at its
    lowest point, a rim of raised beds walled in brick, the spigot on the highest rise and the hose
    running down across the bowl.
  - `owed` A test: a call from the rim is heard everywhere in the bowl, and comes back from the
    sides; the bowl's own low C woken by the right call at the pool's edge.
- **Asks:** Did the Garden feel like it held you?
