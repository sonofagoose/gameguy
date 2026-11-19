# Drawn in light

_On 2026-11-17 Morgan said the page toy's look is "VASTLY cooler" than the meadow's: "scrap the
meadow style lol. thoughts? be ambitious". This is what the look becomes if it is built on the page
toy. The page toy now has a light that goes with it, the beam (`toys/page/`), and it runs on both
units. Nothing here is decided._

## The idea in one breath

Everything you see is something you hear. The world is drawn the way an oscilloscope draws a sound:
by a beam of light on black. What sounds, shines. What is silent is dark. Hum is the one solid thing
in it: a small plaster body in a world made of light.

## Why the lines won

- **The meadow** was solid, lit, shaded 3D: grass, stones, a tree. It ran well (8 to 12 ms of GPU on
  the handheld), but it could have been any game's meadow.
- **The page toy** draws only lines of light, and every line means something:
  - a creature's body is its interval to home;
  - a ring is a call;
  - the wheel is the circle of fifths.
- **It suits this screen.** At 229 pixels an inch a one-pixel line reads like a fine pen line, and
  broad smooth gradients band (`look.md`). Lines of light on black play to the first and avoid the
  second.
- **It's cheap.** A whole frame of the page toy, the rules and about 1,400 marks of drawing, takes
  about 1.5 ms of the processor's time and, in plain lines, one draw call.
- **It's honest.** Nothing pretends to be a material. What you see is what the music is doing.

## Eight rules for a world drawn in light

### 1. If it sounds, it shines

- Silence is dark. You see by calling: a call's ring lights what it passes, as it already does in
  the toy.
- At night the garden is black until Hum sings.
- By day the sky is the day's chord, a held drone. It lights everything faintly from the horizon,
  the way the toy's sky does once the world stands.
- Brightness is loudness. A voice that falls quiet fades from sight.

### 2. Every figure is a real figure

- The figures are not decoration. Put two tones on an oscilloscope's two inputs and it draws exactly
  these shapes.
  - Nathaniel Bowditch drew them with a pendulum in 1815.
  - Jules Antoine Lissajous drew them independently in 1857, with mirrors fixed to tuning forks.
- **A pure interval stands still. A tempered one turns**, at the rate the two tones beat. So the
  canon's tunings, pure near home and equal at the Seam, become something you can see. At middle C:

| interval | tuning | it beats | so its figure |
|---|---|---|---|
| fifth | pure (3:2) | not at all | stands still |
| fifth | equal temperament | 0.89 times a second | turns slowly, once in 1.1 s |
| fifth | quarter-comma meantone | 2.4 times a second | turns once in 0.4 s |
| major third | pure (5:4), and meantone | not at all | stands still |
| major third | equal temperament | 10.4 times a second | shimmers |
| major third | Pythagorean (81:64) | 16.4 times a second | shimmers faster |

- **In the world:**
  - In the Garden every figure stands still.
  - In the Glass Hills (pure fifths) the fifths stand still and the thirds shimmer.
  - In the Bell Meadow (sweet thirds) it is the other way round.
  - At the Seam, where everything is equal-tempered, every third shimmers and every fifth turns. It
    is "everything a little off, everything connected", and you can see it.
- **The comma** is the slowest of all: a figure that almost closes and creeps round. On the
  thirteenth morning it turns about three and a half times a second, the same 3.57 Hz as the beat in
  clip 24.

### 3. The beam leaves light where it lingers

- A beam deposits light at a steady rate, so where it moves slowly it leaves more light along its
  path, and where it races it leaves less.
- A figure's beam slows at its turns, so a figure glows brightest at its edges and corners. That is
  the look of a real oscilloscope trace.
- **Built:** the toy weights each part of a figure by how slowly its beam moves there.

### 4. Afterglow is memory

- What moves leaves a trail of light. How long the trail lasts is how long the world remembers.
- **Built in the toy:**
  - Only things that sound leave light behind: voices, calls, the wheel. The ground and the reeds
    stay crisp.
  - The afterglow is short (about 70 ms) and stretches to about a quarter of a second while R1
    thickens time. Everything then moves at a quarter of its speed, so a trail stays the same length
    on the screen.
  - A ring from a creature coming home leaves ripples, like a sound wave.
- **In the game:**
  - **The lake's level sets the afterglow.** A low lake forgets: trails die fast. A full lake
    remembers: the world glows with where things have been. The canon's rule, "a low lake forgets",
    becomes something you see before you understand it.
  - **Echoes are afterglow you chose to keep.** They walk in sun-print blue.
  - **At night the river replays the day** as a beam retracing your path. The pressed page in the
    toy is a first version (see `the-card.md`).

### 5. Line texture is timbre

- Each voice draws with its own wave. A pure tone draws a smooth line, and a voice rich in overtones
  draws a line with a fine ripple in it.
  - Doorstop's *oo* is a heavy, smooth line.
  - Drip's *oh* swells slowly.
  - Patio's *ee* trembles fast and fine.
- So you can tell who is singing with the sound off.
- Living lines boil a little from frame to frame, as hand-drawn lines do (`look.md`). The Grid's
  lines never move.

### 6. Depth is the third note

- Two voices draw on a page; a third pulls the figure into space (`the-page-and-the-place.md`).
- With the beam, depth also shows as light: the far parts of a figure are fainter and thinner.

### 7. Solid is close

- **Hum is the only solid thing in the world.** It is plaster, as the canon says, in a world made of
  light.
- **Voices in your band ride on you and are solid too.** Drip is already a solid drop on Hum's head
  in the toy.
- **The beloved is a figure of light until you are in tune with them, and then they have a body.**
  Being seen is having a body to someone. That is the canon's "blurred when you are out of tune with
  them, sharp when you are in", taken one step further.

### 8. The Grid is the pixel

- The beam's enemy is the raster.
- Where the Grid has grown:
  - lines snap to the pixel grid and become stairs;
  - they lose their glow and their boil;
  - colours band into flat steps (`look.md`, "Quantising as the uncanny").
- Greys are drawn in pixel stairs. Bringing a Grey home smooths it back into a curve.
- **The Wolf** is a doubled beam that never converges. Its two traces sit a comma apart, beating,
  and its eyes are the only red: found light.

## What stays from `look.md`

- Bone and chrome on black: Void is the ground, Bone is Hum.
- Colour by fifths: C green at the top, sharps warming clockwise, flats cooling the other way,
  purple at the seam.
- Red only as found light.
- Sun-print blue for the past.
- One line of type, Space Mono, set wide.
- No human faces.
- Hits that stop the picture for a beat instead of shaking it.

## What goes

- The noon meadow of lit, shaded solid shapes.
- Plaster creatures. Only Hum stays plaster, and creatures are their figures, as in the toy.
- Light worked out per vertex on solid ground, haze on terrain, and the painterly road.
- The meadow toy stays only as a measurement of what this GPU can draw (`docs/hardware-target.md`).
  Its look is dropped.

## Noon and 2am

- **2am** is the native state: a black field and the beam.
- **Noon** is everything sounding at once, quietly:
  - the horizon glows in the day's colour;
  - the ground's lines are lit faintly;
  - more of the world shows.
- It is the same garden. Noon is how it looks when the sky is singing.

## What the toy shows

The page toy has three lights. D-pad up and down change them, and the light's name shows at the top
right.

- **Beam**, the new default:
  - things that sound leave a short afterglow, longer while R1 is held;
  - figures are brightest at their turns;
  - what lingers has a soft halo.
- **Long afterglow:** the same with a long trail all the time.
- **Lines:** the toy as you first played it.

How it's drawn: light from things that sound is drawn at full size and kept, fading, in a half-size
copy (the phosphor). At each pixel the screen shows the brighter of this frame's light and what is
left of the frames before. So a thing that holds still is exactly as bright as before, and only what
moves leaves a trail. The half-size copy bleeds a little into its neighbours each frame, which gives
what lingers its halo. Halos and pools of light never linger, because a beam doesn't draw them.

Measured on the purple, the scripted player, 4,270 frames each:

| light | a frame | late frames | worst frame | the toy's work in a frame | sound gaps |
|---|---|---|---|---|---|
| lines | 17.10 ms | none | 20.2 ms | 1.5 ms | none |
| beam, first version (full-size phosphor, three blur passes) | 17.97 ms | 216 | 34.8 ms | 7.3 ms | none |
| beam, as built | 17.10 ms | none | 20.4 ms | 3.6 ms | none |

What the first version taught:

- This Mali GPU pays a fixed cost for every render pass and every change of target. Three blur
  passes on a picture a sixteenth of the screen's size cost more than their pixels suggest. Letting
  the phosphor bleed made the same halo with no extra passes.
- A phosphor that adds each frame's light on top of the last makes anything that holds still about
  five times too bright. Keeping the brighter of the two is what a phosphor does, and it costs
  nothing.
- A long afterglow while the camera moves smears the whole world. The afterglow stands aside while
  the view itself is moving.

## What only hands can answer

- Is the beam better than the lines you first played? D-pad up and down, mid-fight.
- Do trails help you read a fight (where a creature has been, where it's going), or clutter it?
- Does the long afterglow while R1 is held feel like time thickening?
- Is the halo too much or too little on this screen? It needs to be judged on the device, not on a
  laptop.

## What it would change

| in | now | with this |
|---|---|---|
| `look.md`, the synthesis | a noon meadow of solid shapes; plaster creatures with figures around them | lines of light; figures are the bodies; only Hum is plaster |
| canon section 12, sound and picture as one | pitch is hue, ratio is the figure, near-miss is ink out of register | add: tuning is how fast a figure turns; afterglow is memory; line texture is timbre; silence is dark |
| canon section 15, the hardware | light per vertex, haze, 3D at 75% resolution | lines projected on the processor, one draw call per layer, a half-size phosphor, three passes in all |
| the lands' tunings | heard | seen: still figures at home, turning ones round the rim, shimmering thirds at the Seam |
| the beloved | blurred out of tune, sharp in tune | light out of tune, a body in tune |
| the meadow toy | the 3D look under test | a measurement only |

## Not yet connected

- **Height.** Jumping and gliding need a ground to read against. In a world of lines that could be a
  ring on the ground under Hum that shrinks as it rises. Untried.
- **Big places.** The canon's cathedral asters, the Chrome Nave and the Stage as line drawings: how
  many lines before they turn to noise? The toy draws about 1,400 marks a frame with room for
  22,000.
- **Text.** The one line of type stays Space Mono, as the style book has it, rather than being drawn
  by the beam.
- **Afterglow in fierce fights.** Fierce might shorten it, so a fight stays crisp.
- **Line texture by timbre** and **turning by tuning** are designed but not built. Both are a few
  lines in the toy's figure drawing.

## Sources

- [Lissajous curve](https://en.wikipedia.org/wiki/Lissajous_curve) (Wikipedia): Bowditch 1815,
  Lissajous 1857.
- [Jules Antoine Lissajous](https://mathshistory.st-andrews.ac.uk/Biographies/Lissajous/)
  (MacTutor): the 1857 memoir and the mirrors on tuning forks.
- [Cathode ray oscilloscopes, part
  3](https://www.siliconchip.com.au/Issue/SC/1996/May/Cathode+Ray+Oscilloscopes%3B+Pt.3) (Silicon
  Chip, 1996): writing speed, and how the spot's speed depends on the signal.
- [Oscilloscope history](https://en.wikipedia.org/wiki/Oscilloscope_history) (Wikipedia):
  long-persistence phosphors such as P7.
- The beat rates are worked out from the frequencies (middle C at 261.63 Hz), as the clips' were.
- This repo: `look.md`, `the-page-and-the-place.md`, `thirteenth-morning.md` (sections 3, 10, 12 and
  15), `toys/page/README.md`, `docs/hardware-target.md`.
