# Promises of the texture of the world

_Part of the promise book (`../promises.md`). What `../texture.md` says, sized as it is built._

### `texture.frame` What makes a frame beautiful

- **Said:** `spec/texture.md` "In the place, at least half the screen is black." "On the page and at
  2am, at least four fifths." "No more than a tenth of the screen is brighter than half." "Walking,
  Hum is under a twentieth of the screen's height."
- **Stage:** 2
- **Scene:** evening
- **The moment:** Whatever you stop on, the frame is something you would want to look at: mostly
  dark, the way a night garden is, with a few things shining because they are sounding, and nothing
  glaring. You are small in it. Your eye goes to what matters without being told.
- **A cheat would be:** a glow filter over the whole screen; a bright wash that makes everything
  visible and nothing special; a frame tuned once by eye and never measured again.
- **Full size:**
  - `fact beauty.place_black_least >= 0.5` Every frame kept from the place, measured by the game as
    it keeps it.
  - `fact beauty.page_black_least >= 0.8` Every frame kept from the page.
  - `fact beauty.bright_most <= 0.1` No kept frame has more than a tenth of its dots brighter than
    half.
  - `fact asters.hum_px_walking <= 24` Walking, Hum is under a twentieth of 480 rows.
  - `owed` Few colours near: near Hum, most of what is lit in the day's three hues, because that is
    mostly what sounds there. Measured from the kept frames' hues, counting only the ground and near
    things.
  - `owed` The brightest tenth of the light belongs to things that are sounding: measured by drawing
    a kept frame twice, once with only what sounds.
  - `owed` Near, middle and far in every view of the place: the score tool, for every piece.
  - `owed` At 2am, at least four fifths black: no frame is kept at 2am yet.
- **Asks:** Is every frame something you would want to look at?

### `texture.light` Light is loudness

- **Said:** `spec/texture.md` "A thing's light is its loudness, spread over all its lines." "It is
  seen only when something else lights it: the day, or a call's ring passing over it." "So the
  brightest thing on the screen is always something that is sounding, or Hum."
- **Stage:** 2
- **Scene:** evening
- **The moment:** After a while you read loudness by eye. A crown of small bells ringing hard is
  piercing; a whole lawn rustling is only a mist; a silent tower is dark until the day or your call
  lights it. When something goes quiet you see it go.
- **A cheat would be:** brightness chosen per object by eye; glow added to whatever should look
  important.
- **Full size:**
  - `test what lights a thing by ringing is what sounds it` One number rings a thing: heard as that
    number, seen as its root.
  - `frame evening-page` In the dark, only what a call has passed is lit, and it fades behind the
    ring.
  - `frame evening-answer` The bells that are kin to the call blaze; the rest stay dim.
  - `owed` A sounding line moving in the shapes of its own overtones, at its note eight octaves
    down.
  - `owed` The depth of a colour from how much of the sound is note: noise in no colour.
  - `owed` Each material's line: glass hard and long-glowing, wood in short strokes, moss giving no
    glow.
  - `owed` The spread measured: a big sounding thing, drawn with many lines, is dimmer for each line
    than a small one equally loud.
- **Asks:** Could you tell what was loud by looking?

### `texture.one-rule` How a thing looks is how it sounds

- **Said:** `spec/texture.md` "How a thing looks is how it sounds. Every part of a thing's look is
  one
  part of its sound, by the same number." "how loud it is | how much light it gives" "its note | its
  colour, by fifths round the wheel" "how much of its sound is note and how much is noise | how deep
  its colour is: a clear note is full colour, and noise has no colour at all" "its overtones | the
  shape its lines take when it sounds" "how long it rings | how long its light lasts" "how it is set
  sounding: struck, plucked, bowed, blown | how its light begins: at once, or swelling" "its
  register
  | how heavy its line is" "Colour's depth has four causes, and any one of them greys a thing: noise
  (a click has no colour), harm (hits drain it and a cadence restores it, ../SPEC.md, 10),
  dissonance with home" "They are told apart by the line: a harmed thing leans, a dissonant one
  turns, and the Grid's grey is drawn in pixel stairs."
- **Stage:** 2
- **The moment:** A glass bell struck hard flashes at once and glows for half a minute in its note's
  full colour; a bowed string swells into light and fades with its sound.
- **A cheat would be:** a light effect per kind of thing, tuned by eye.
- **Full size:**
  - `test a cue can't be made with a sound and no light, or a light and no sound` Loudness is light,
    the note is the colour and how long it rings is how long its light lasts, through one mapping.
  - `owed` How much of a sound is noise sets how deep its colour is; how it is set sounding sets how
    its light begins; its register sets its line's weight: each a sum from the sound's own numbers.
  - `owed` The four causes of grey told apart by the line: a harmed thing leans, a dissonant one
    turns, the Grid's grey is in pixel stairs.
- **Asks:** Could you tell how a thing sounded from how it looked?

### `texture.at-rest` A line at rest

- **Said:** `spec/texture.md` "A crown of small bells ringing loudly is a few short lines carrying a
  great deal of light: piercing." "A lawn rustling faintly is a great many long lines carrying
  almost
  none: a mist." "A big thing has to be very loud to be bright." "Lower is heavier. A line's weight
  has one source, its thing's register, in three steps: heavy, plain and hair." "Distance thins a
  line only by perspective, and a material changes a line's edge, grain and glow, never its weight."
- **Stage:** 2
- **The moment:** A crown of bells rings and it is piercing, a few short lines blazing; the lawn
  around you rustles as a faint mist of long lines.
- **A cheat would be:** brightness set per kind of thing.
- **Full size:**
  - `frame evening-climb` A crown ringing: a few short lines carrying a great deal of light.
  - `owed` A thing's light spread over all its lines (`texture.light`), so a big thing must be very
    loud to be bright: a check over the renderer's table.
  - `owed` Three weights of line by register, heavy, plain and hair, and nothing else sets weight.
- **Asks:** Did loud things look loud?

### `texture.sounding` A line that sounds

- **Said:** `spec/texture.md` "A sounding line is a standing wave. It moves sideways in the shapes
  of
  its own overtones: the first as one loop, the second as two, and on." "How far it moves is how
  loud it is." "So you can see what kind of thing is ringing, and which of its overtones, by
  looking." "It moves at its own note, eight octaves down, and a note above 2,048 hertz is folded
  down by further octaves until it moves fewer than eight times a second, so nothing swings faster
  than the screen can show." "Middle C swings once a second." "A fifth above swings three times for
  its two." "A chord is seen as lines swinging in step." "The light is brightest where the line
  turns. The beam that draws a thing is slowest at the two ends of a swing, so those are the bright
  places, and the middle of the swing is faint." "A still line is brightest at its corners for the
  same reason, and evenly lit along its length." "Each family moves in its own way:" "string | one
  thin line | whole loops: one, two, three bellies, with still points between that you can touch"
  "open pipe | two walls | beads of light inside it, evenly spaced: one for each belly of air"
  "stopped pipe | two walls and a cap | beads at odd spacing only: half as many, and hollow-looking,
  as it sounds" "bar | a slab's edge | a bend that is not even: its still points sit 22.4% of the
  way
  in from each end, a little over a fifth" "fork | two tines | the tines swing apart and together,
  and nothing else moves" "skin | a rim | the figure on its surface: rings and spokes of still line,
  with the rest shimmering" "bell | a profile and a rim | the rim becomes a flower of four lobes,
  then
  six: its wall bulging in and out" "bottle | an outline with a neck | the air in its neck: one
  bead,
  swelling and shrinking" "plate | an outline | its figure, from its own outline, in still line"
  "voice | the singer's figure against your home | lobes by the ratio of its note to yours: still
  when the two are true, turning when they are not"
- **Stage:** 2
- **The moment:** The bridge puddle stands in its figure, rings and spokes of still line with the
  water heaving between them once a second; a string beside it swings in two loops, and you can see
  it is sounding its octave.
- **A cheat would be:** a wobble added to sounding things at a rate someone liked.
- **Full size:**
  - `frame evening-pool` Skin: rings and spokes of still line, the rest heaving.
  - `frame evening-bridge` The water heaving at middle C eight octaves down, once a second.
  - `test four breaths on the tick bring the drip's fifth true, and the figure stops` Voice: lobes
    by
    the ratio of the two notes, still when they are true.
  - `owed` Every family drawn moving in the shapes of its own overtones, as far as it is loud, at
    its
    note eight octaves down (folded below eight times a second): string, pipes, bar, fork, bell,
    bottle and plate.
  - `owed` A chord seen as lines swinging in step; the light brightest where a line turns
    (`light.beam`).
- **Asks:** Could you see which note a thing was sounding?

### `texture.tuning-seen` Tuning, seen

- **Said:** `spec/texture.md` "True is still. A figure between two voices in a pure interval does
  not
  move." "In a land of sweet thirds the fifths' figures turn slowly; at the Seam everything turns."
  "Out of tune is never blur. It is two crisp copies sliding against each other on the beat
  (../SPEC.md, 15)." "The comma is 1.96 m of height and 7.04 degrees of sky (sky.md). Wherever two
  things a comma apart stand together, that gap is between them: seen as two copies when near, and
  as
  a beat when far."
- **Stage:** 2
- **The moment:** The figure between you and Drip stops turning when you lock: true is still.
- **A cheat would be:** a blur that clears as notes come into tune.
- **Full size:**
  - `test four breaths on the tick bring the drip's fifth true, and the figure stops` True is still.
  - `owed` A thing a comma off seen as two crisp copies sliding on the beat when near, and as a beat
    when far (stage 3 and the thirteenth morning).
- **Asks:** Could you see when two notes were in tune?

### `texture.silence` Silence, seen

- **Said:** `spec/texture.md` "Silence is black, and black is the commonest thing on the screen." "A
  quiet place is darker than the dark round it. Where sounds cancel (law 5), the ground's kept light
  does not show and a call's ring does not enter." "It has an edge you can walk." "A silent thing in
  front of a sounding one is a hole in the shape of the silent thing."
- **Stage:** 2
- **The moment:** Hum sings the mirror of a wolf's howl and stands in a ball of black, a hole in the
  night that the wolves can't see into.
- **A cheat would be:** a vignette.
- **Full size:**
  - `fact beauty.place_black_least >= 0.5` Black is the commonest thing on the screen.
  - `owed` A cancelling place drawn darker than the dark round it, with an edge Hum can walk, that a
    call's ring does not enter (`laws.cancelling`).
  - `owed` A silent thing in front of a sounding one drawn as a hole in its shape.
- **Asks:** Did silence ever feel like a place?

### `texture.surfaces` Surfaces, when there are only lines

- **Said:** `spec/texture.md` "Solid matter is black shape. It hides what is behind it." "The more
  of a
  thing is black, the heavier it is." "A hollow thing is see-through. A pipe, a bell, a pot and a
  bottle are outlines, and you see the air inside them move." "Near things show what is Hum's own
  size on them: the joints of a stalk, a drop of dew, the grain of a board, the thread of a screw."
  "Far things are a mast and a point of light." "The same thing is drawn four ways by how far off it
  is (engine.md, three distances and a fourth)." "Wet ground is a mirror. Every light near it has a
  fainter copy under it; only a pool shows the sky, and a call's ring runs twice as far across it."
  "The ground has two textures and no third: what it wears (shape.md), and the light it has kept
  (size.md)."
- **Stage:** 2
- **The moment:** Close to an aster you see the joints of its stalk at your own size; a kilometre
  off
  the same aster is a mast and a point of light.
- **A cheat would be:** a texture painted on a surface.
- **Full size:**
  - `frame evening-foot` Near: the stalk's joints at Hum's own size, its leaves black shapes that
    hide what is behind them.
  - `frame evening-far` Far: masts and points of light.
  - `owed` Wet ground and pools as mirrors of the lights near them, a pool showing the sky, and a
    call's ring running twice as far across water (`garden.w04`).
  - `owed` A hollow thing as an outline with the air inside it seen moving.
- **Asks:** Did the world feel solid, though it was made of light?

### `texture.sound-grain` The texture of the sound

- **Said:** `spec/texture.md` "Each land has its own grain in the ear, from what it is made of: the
  Garden wet and soft" "It begins nearly bare. On the first evening there is your note, then
  Drip's, and over them the morning's sky." "The sound of the world thickens across the thirteen
  mornings from a single line to twelve songs at once, and is only ever full on the thirteenth."
  "Thin is the rule and thick is an event. At most four things carry the tune at once." "Everything
  else is a soft bed, the land's own grain, quieter than any one voice." "A land's song thickens
  with
  its lives. With none helped a land has a ground and a pulse." "The speaker is the floor
  (../SPEC.md, 15). Low voices are built from their upper overtones and the ear supplies the root."
  "Nothing a player must hear lies below 400 hertz alone or above 8,000."
- **Stage:** 2
- **The moment:** On the first evening there is your note, then Drip's, and over them the morning
  sky's drone; the world's sound starts as almost nothing and you hear every part of it.
- **A cheat would be:** a full soundtrack from the first minute.
- **Full size:**
  - `fact ears.third_note_db_over_quiet >= 30` The first evening's sound: your note, Drip's, and the
    third between them, over a quiet that came before.
  - `owed` `ears` over a take: at most four things carry the tune at once, and the bed is quieter
    than any one voice.
  - `owed` A land's song thickening with its lives helped (`people.helping`).
- **Asks:** Did the sound grow with you?

### `texture.across-time` Across time

- **Said:** `spec/texture.md` "noon | everything sounds at once, quietly: the whole land is a fine
  web
  of faint line, and what you set ringing stands out of it" "2am | almost nothing sounds: the moon's
  drone, the stars' soft bed, the lives that keep the night, and what flies. Mostly black. You see
  by
  calling, and by what flies" "the lake low | glow is short and the ground forgets: crisp, clean and
  lonely" "the lake full | glow is long and the ground holds what was sung on it: warm, and written
  on" "a land with nobody helped | a ground and a pulse: bare" "a land with all eight | a band:
  full"
- **Stage:** 2
- **The moment:** At 2am you call into the black and see the garden only where your call reaches;
  at noon the whole land is a faint web and what you ring stands out of it.
- **A cheat would be:** a day-night colour grade.
- **Full size:**
  - `frame evening-black` The dark before anything sounds: mostly black.
  - `owed` Noon, 2am, the lake low and full, a land bare and a land with all eight, each with a kept
    frame and its beauty facts (stage 2's day).
- **Asks:** Did the time of day change how the world felt?

### `texture.beautiful` A beautiful frame, checked

- **Said:** `spec/texture.md` "These are rules, and the build can check each one from its own
  frames." "A cheat would be: a colour scheme for each land chosen by eye" "The brightest tenth of
  the light belongs to things that are sounding." "Few colours
  near.
  Every thing is the hue of its own note, by fifths, whatever the day." "Near Hum, most of what is
  lit
  is in the day's three hues, its note, its fifth and its third (sky.md), because most of what
  sounds
  there is in the day's chord." "Bone-white is for what has no note, and chrome for a note off the
  wheel." "The sky's upper rings, the far lands, the moon, the stars and echoes in sun-print blue
  keep
  their own colours." "Three weights of line: heavy for what is low, a plain line, and a hair for
  what
  is high." "Near, middle and far. Every view in the open air has something within twenty metres,
  something between, and something a kilometre off." "Inside a room, a pot or the hose, the far
  thing
  is the room's far end or its way out." "The score tool checks it for every piece." "Nothing is
  drawn
  that isn't in the world. No frame, no gradient, no texture, no glow that nothing is giving."
  "Rest.
  Nothing swings unless it is sounding." "A living line's small boil goes on even in a quiet land,
  and
  only the Grid's lines are dead still." "A still frame of a quiet land should be mostly still."
- **Stage:** 2
- **The moment:** Any frame of the game, paused, could be printed and hung on a wall.
- **A cheat would be:** a colour scheme for each land chosen by eye; a glow filter over the whole
  screen.
- **Full size:**
  - `fact beauty.place_black_least >= 0.5` Half black at least, in every kept frame of the place.
  - `fact beauty.bright_most <= 0.1` And no more than a tenth of it brighter than half.
  - `owed` From each kept frame: the brightest tenth of its light on sounding things; near Hum most
    of the lit in the day's three hues; something near, between and far; nothing swinging that is
    not sounding. The game measures them as it dumps the frame, as it does the black and the bright.
  - `owed` The score tool checks near, middle and far for every piece.
- **Asks:** Did you ever stop just to look?
