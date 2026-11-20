# Promises of fights

_Part of the promise book (`../promises.md`). What `../../SPEC.md` section 10 says, sized before the
stage that builds it. The wheel toy (`toys/wheel/`) tried strikes on the beat, the pocket and the
cadences._

### `fight.beat` On the beat

- **Said:** `SPEC.md` "On the beat. Every hit rings the enemy at its own note." "Dodge on the beat
  and
  the pocket opens." "A strike you time yourself rings fuller than one the game placed."
- **Stage:** 2
- **The moment:** A knot lunges on its stumbling beat; you dodge on yours and the pocket opens, a
  breath of time where everything is in step. Your strike lands on the one and the knot rings out
  at its own note, fuller than any strike the game could have placed for you.
- **A cheat would be:** hit points and a damage number; strikes snapped to the beat with no
  difference for timing them yourself.
- **Full size:**
  - `test a knot struck on the one with home on its root greys, and a cadence beside its root brings
    it home`
    A strike rings the struck knot at its own strands' notes, as hard as the strike met it.
  - `test a knot lunges to arrive on its one; a dodge on that beat opens the pocket, and a lunge not
    dodged knocks Hum back`
    Knots lunge to arrive on their one, so with home on their root a lunge comes on Hum's downbeat;
    a dodge within a few steps of it opens the pocket, time thickens and the next strike takes more;
    a lunge not dodged knocks Hum back and dims it, and nothing dies.
  - `frame evening-pocket` The first pocket: a knot mid-lunge, Hum stepped aside and glowing.
  - `test a strike timed within an eighth of a beat lands at once with its octave; off the beat the
    game places it on the next beat, plain`
    Within an eighth of Hum's beat (law 7's window) a strike is the hands' own: it lands on the
    sample pressed, rings with its octave and a brighter light, and takes a quarter more. Off the
    beat the game places it on the next beat, on the beat's own sample, its note alone.
  - `fact ears.strike_timed_octave_db >= -10` Measured from the evening's sound by
    `game/tools/ears`:
    a timed strike's octave stands within a few decibels of its note.
  - `fact ears.strike_placed_octave_db <= -30` A placed strike has no octave to speak of.
- **Asks:** Did a timed strike feel like power?

### `fight.looper` The looper in a fight

- **Said:** `SPEC.md` "The looper in a fight. Each bar you stay in the pocket, your last bar's
  strikes
  keep landing beside you as an afterimage, up to four layers." "The clap cashes them in:
  everything near resets to the same point in its cycle."
- **Stage:** 2
- **The moment:** You stay in the pocket for four bars and four ghost layers of your own strikes are
  playing beside you. You clap, and every creature near you snaps to the same point in its cycle.
- **A cheat would be:** a combo counter that multiplies damage.
- **Full size:**
  - `test each bar in the pocket keeps its strikes as an afterimage that lands again; the clap
    spends them and sets the knots' one`
    A bar in which the pocket opened keeps its strikes as a layer, up to four, the oldest going;
    each layer's strikes land again where they fell in the bar, from a small Hum of light beside
    Hum, at half a strike's drain. The clap spends the layers, each taking a part from every knot
    near, and sets every knot in reach to the start of its cycle (law 3).
  - `test out of the pocket the afterimage lands softer each bar, and is gone` A looper's feedback:
    while you stay in the pocket the layers hold; each bar out of it they land at half, and the
    faintest go, so an afterimage never follows Hum out of the fight.
  - `test a clap takes back a call begun just before it, and leaves a call made long before` L1
    and R1 together are one gesture: a call begun within the clap's window is taken back, its ring
    and its sound.
  - `frame evening-afterimage` The first afterimage, landing beside Hum.
  - `frame evening-clap` The clap's ring out to its reach.
  - `owed` The clap resets every other cycling thing in reach as well, as each comes to keep a phase
    of its own (law 3): Drip's tick, the bee's buzz, the fireflies (`sky.md`).
- **Asks:** Did the afterimages feel like your band?

### `fight.transform` Nothing dies in a fight

- **Said:** `SPEC.md` "Nothing dies. Hits drain colour, a grey creature leans, and a cadence on the
  downbeat brings it home." "The mood you bring it home in is the gift it leaves."
- **Stage:** 2
- **The moment:** The wolf goes grey and leans toward a wedge. You let go of the swell on the
  downbeat, the cadence lands, and it comes home in tenderness: it curls up, and where it lay a
  small tender thing remains.
- **A cheat would be:** an enemy that vanishes with a puff.
- **Full size:**
  - `test a knot struck on the one with home on its root greys, and a cadence beside its root brings
    it home`
    Hits drain a knot's colour, and a cadence on the downbeat brings a grey one home.
  - `frame evening-swell` Struck grey, the knots circle Hum as dim ghosts.
  - `frame evening-grey` Grey, each knot leans toward the wedge on its left, where the full close
    would bring it home; on the wheel its threads bend there too.
  - `test the four doors: rung open and the next grey, settled, kin for a phrase, slid home, and a
    plain ending`
    Where home stands against a grey creature's root when the cadence lands decides its door: one
    to its left rings it open and greys what has its root where home landed; one to its right
    settles it to sleep; two to its right makes it kin for a phrase, then home; five fifths away it
    slides home by a half step; anywhere else, home on its root among them, a plain ending.
  - `frame evening-asleep` After the amen the knots lie curled and breathing, asleep.
  - `test a knot struck on the one with home on its root greys, and a cadence beside its root brings
    it home`
    It keeps the mood home was in: sunny home, for the amen landed there.
- **Asks:** Did bringing a creature home feel kinder than beating it?

### `fight.kinds` Wolves, knots and greys

- **Said:** `SPEC.md` "Wolves are made of the comma." "Knots are fear, tangled rhythms." "Greys are
  the Grid's soldiers, on the grid exactly; swing breaks them and standing a third away brings their
  colour back."
- **Stage:** 2
- **Scene:** asters
- **The moment:** (From the room: the first knots are south of the puddles, a minute and a half's
  walk behind where you wake; they come to you. Hold R1, point where their threads meet, let go, and
  strike with the left face on the one.) A knot's two strands stumble against each other until you
  find the wedge where they meet on the one.
- **A cheat would be:** three enemy types told apart by colour only.
- **Full size:**
  - `test a knot dances on Hum's one with home on its root, and stumbles anywhere else` A knot's
    strands pulse three and five to its cycle, which is a bar stretched by home's pitch against its
    root: rhythm is pitch, slowed (`game/src/world/knots.zig`).
  - `test a knot struck on the one with home on its root greys, and a cadence beside its root brings
    it home`
    Three meeting strikes grey it; the amen with home beside its root brings it home.
  - `test struck with home elsewhere, a knot drains slower: the dance's one is not Hum's` Every hit
    works, and home on the root works best.
  - `frame evening-knots` A knot: two strands tangled, a loop of three lobes and one of five.
  - `owed` Wolves (the comma) and greys (the grid) come with the lands that have them (stage 3).
- **Asks:** When you moved home to where their threads met, did the knots stop stumbling?

### `fight.bosses` Bosses are pieces of music

- **Said:** `SPEC.md` "Bosses are pieces of music: the Great Knot (five against seven), the
  Metronome
  (it learns you; swing breaks it), the Wolf at the Seam (every echo you turned away from)." "Each
  great instrument has its own trial on Fierce."
- **Stage:** 2
- **The moment:** Inside the Hose the Great Knot plays five against seven, and you untie it a strand
  at a time until the two meet.
- **A cheat would be:** a health bar with music playing.
- **Full size:**
  - `owed` A test: the Great Knot is five against seven, and is untied only by finding where they
    meet; the scripted player does it.
  - `owed` The Metronome and the Wolf at the Seam come with their lands (stages 3 and 4).
- **Asks:** Did the Great Knot feel like a piece you learned to play?

### `fight.gentle` Gentle or Fierce

- **Said:** `SPEC.md` "Gentle or Fierce, chosen any night. Gentle widens the timing and the ledges,
  leans home for you, and lets most fights end by comfort."
- **Stage:** 2
- **The moment:** On Gentle the knot is calmed by sitting with it; on Fierce you have to untie it on
  the beat.
- **A cheat would be:** an easy mode that halves damage.
- **Full size:**
  - `test Gentle widens each window of timing by half again, and Fierce keeps them` The strike's,
    the dodge's, a meeting's, the downbeat's and the breath's, by one sum.
  - `test on Gentle a swell held a bar unsteered leans home beside the grey knot on its amen side;
    on Fierce the amen is a plain ending`
    Gentle leans for you: hold the swell and never touch the stick, and after a bar home drifts
    beside the grey knot on its amen side; let go on the one and it settles and sleeps, a fight
    ended by comfort. Fierce asks for the full close, and leans for nobody.
  - `owed` The ledges, when there are ledges to widen.
  - `owed` On Gentle the knot is calmed by sitting with it (`spec/laws.md`: pushes against the
    swing calm it), when there is sitting.
  - `owed` Choosing, any night, when there are nights; until then the first evening is Gentle.
- **Asks:** Which did you choose, and did you ever want the other?
