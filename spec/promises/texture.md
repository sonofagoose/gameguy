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
