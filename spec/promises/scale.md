# Promises of size

_Part of the promise book (`../promises.md`). What `../size.md` says about one to a hundred and the
ring round the lake, sized before the stage that builds the Garden at its size. What the card is
for is in `loop.md`._

### `scale.one-to-a-hundred` One to a hundred

- **Said:** `spec/size.md` "The world is a real garden at one scale." "Hum stands one metre tall,
  which is one centimetre of the real garden." "Every thing is its real size, times a hundred."
  "Nothing is sized by eye." "an aster (New England aster) | 0.9 to 1.85 m | 90 to 185 m: Cologne
  Cathedral is 157 m and the spire of Ulm Minster, the tallest church spire ever built, 161.5 m"
  "one
  of its flower heads | 2.5 to 4.5 cm across | a bell 2.5 to 4.5 m across" "its stalk; one of its
  leaves | under 1 cm through; 5 to 10 cm | a mast a metre through; a blade 5 to 10 m long" "a reed
  (cattail) | 1.5 to 3 m | 150 to 300 m" "alfalfa | 60 cm to 1 m | a forest 60 to 100 m high" "a
  blade of grass | 4 to 9 cm | a tree 4 to 9 m tall, as wide as a door" "a crumb of soil; a marble |
  1 to 3 cm; 1.6 cm | a boulder 1 to 3 m; a ball taller than Hum" "a drop of water | 4 mm | 40 cm:
  Drip sits on Hum's head" "a pill bug; a fly | 10 mm; 7 mm | as big as Hum; a little smaller" "a
  garden hose | 15 to 30 m long, 13 to 19 mm in the bore | a tunnel 1.5 to 3 km long that Hum walks
  through upright" "a brass spigot | 10 to 15 cm | a monument 10 to 15 m tall" "a puddle from the
  storm | 1 to 3 m | a lake 100 to 300 m across" "a flowerpot | 15 to 30 cm | a hall 15 to 30 m
  high"
  "a guitar; its sound hole | 1 m; 10 cm | 100 m long; a door 10 m across" "a piano key | 2.3 cm
  wide, 15 cm long | a floor 2.3 m wide and 15 m long" "the inside of a parked car | 2 to 2.8 m
  long,
  1.2 m floor to roof | a nave 200 to 280 m long and 120 m high" "a porch step | 18 cm | a cliff 18
  m
  high" "The aster's height and the two churches were checked against sources on 2026-11-19
  (below)." "The other real sizes are from general knowledge and are checked when their land's score
  is written." "A call takes almost three seconds to climb the tallest aster, and its bells are
  heard
  as late again." "Every big thing has parts Hum's own size: the joints of a stalk, a drop of dew, a
  thread on the spigot." "Small things are places: the bore of the hose, the cup of a flower, the
  hollow of a pot." "A score gives real sizes and the score tool multiplies." "A thing in a score
  with no real size is refused."
- **Stage:** 2
- **The moment:** You stand at the foot of an aster and its crown is a cathedral's height above you;
  you call and watch the ring climb the stalk for three seconds before the bells answer.
- **A cheat would be:** things sized to look right.
- **Full size:**
  - `fact scale.one_to == 100` One to a hundred.
  - `fact asters.tallest_m <= 185` The tallest aster is no taller than a real New England aster
    times a hundred.
  - `fact asters.great_climb_s <= 3` A call climbs the great aster in under three seconds.
  - `test a call climbs a tower, and its bells are heard late by their height` And its bells are
    heard as late again.
  - `test a round skin's still rings and spokes are where the Bessel functions are nought` A puddle
    is 100 to 300 m across: the bridge puddle is 220 m.
  - `owed` The score tool: a land written as a score with real sizes, multiplied by a hundred, and a
    thing with no real size refused (`spec/stages.md`, stage 1).
  - `owed` Every big thing with parts Hum's own size, and small things as places, written in the
    Garden's score.
- **Asks:** Did the asters feel as tall as cathedrals?

### `scale.ring` The ring round the lake

- **Said:** `spec/size.md` "the lake | 3.7 km across: 11 square kilometres of water" "each land |
  about 3 square kilometres: a kilometre of shore, two kilometres deep, two kilometres along its
  outer edge" "all twelve | about 36 square kilometres of ground" "the whole world | 7.7 km across:
  47 square kilometres" "A land is as big as a country to Hum. A run straight across one takes five
  and a half minutes at 6 m a second." "Nobody sees a whole land in one twenty-minute day." "The
  lake is the hub. Its shore is 11.6 km round: more than half an hour's run, more than a day."
  "Straight across by boat is a few minutes." "Sound crosses it in 62 seconds, so what rings on the
  far shore is seen at once and heard a minute later; a note that is ridden (law 6) carries Hum over
  in the same minute." "And things as tall as cathedrals need room to stand apart and be seen from
  far off." "Past the lake each land that is made after the thirteenth morning is another three
  square kilometres, with no end to them." "These replace the estimate the atlas had before (a ring
  of about 3 square kilometres), which let a "country" be crossed in a minute and a half."
- **Stage:** 2
- **The moment:** From the Garden's shore you hear something ring on the far side of the lake a
  minute after you saw it light; the horn hangs over the water, far off.
- **A cheat would be:** a backdrop of the far shore.
- **Full size:**
  - `test the sun climbs the horn: each rung lights where it stands at once, and is heard late by
    its distance`
    What rings over the lake is seen at once and heard late.
  - `owed` The Garden at its size, about three square kilometres, every thing its own shape and
    loaded as Hum walks (stage 2's build).
  - `owed` The lake 3.7 km across and sixty-two seconds of sound to cross it, measured in the world
    once the ring is built (stage 3).
- **Asks:** Did the Garden feel as big as a country?
