# Shape 1: a Tears of the Kingdom ruled by music

Brainstorm, saved 2026-11-13 at Morgan's request ("I like all the ideas ... even as un-realized and
un-thought-through-as-far-as-how-they-actually-all-connect as they are"). Nothing here is decided.
It is the reply to Morgan's ask for a 3D, third-person game with a first-person focus view, combat
that is exhilarating, a hold-to-slow wheel for the circle of fifths, a second wheel for voices,
voices with Puppycat's energy, and "a Tears of the Kingdom ruled by music where the nature of
existence and love and humanity and the very fabric of space and time is revealed through the lens
of music and harmony and math and sound and love and dissonance".

The ideas that came just before this one (where sound and sight blur, the human verbs, the cast
from Morgan's worksheet) are kept at the end, in "Earlier ideas this builds on".

Companion documents: `shape-2-volta.md` (a different, deeper shape), `shape-3-the-lake-ring.md`
(the circle as the main tool, the lake world, temperament lands, teaching music theory) and
`look.md` (the visual aesthetic).

---

## The frame

- A 3D world. A third-person camera for moving and fighting. A first-person "focus" for close
  attention.
- Morgan's hold-to-slow wheel is very close to how Tears of the Kingdom handles abilities, and it
  suits music even better than it suits Zelda.

## What Tears of the Kingdom does, and what to take

- **Controls.** Tap L to use your current ability. Hold L to open the ability wheel, pick with the
  right stick, release to equip; the game pauses while the wheel is open. ZL locks on and shields,
  ZR draws the bow, Y attacks, X jumps, B dashes, A interacts, R throws.
- **Combat.** A perfect dodge slows time and opens a flurry of attacks. A perfect guard (shield up,
  A at the moment of impact) stuns the attacker.
- **World.** A physics engine decides how things move; a "chemistry engine" decides what state
  they're in. Elements change materials (fire burns grass), and elements change each other (water
  puts out fire). Nintendo calls the result multiplicative gameplay: a few rules, endless
  combinations.

What to take: a few rules that multiply; a wheel that suspends the moment; perfect-timing moments
that slow time and reward you; abilities that turn the whole world into material.

One change to the wheel idea: while it is open, slow time rather than pausing it. Danger keeps
coming, so each choice feels like a reflex instead of a menu. Holding the wheel costs breath, the
way the slow-motion bow aim in midair costs stamina in Breath of the Wild.

## How close this handheld can get

- **Pixels.** Measured: this GPU fills 925–955 million blended pixels a second. The GameCube's
  official figure is 648 million.
- **Shaders.** It runs programmable shaders, which the GameCube didn't have.
- **Memory.** About twenty times the GameCube's.

Wind Waker and Sunshine are GameCube games, so the honest ceiling is a modern game in that class:
big skies, haze, stylised light, a world you can see across. Tears of the Kingdom's scale and its
thousands of physics objects are out of reach. Its ideas aren't.

Sound is the exception: one CPU core runs 800–1,000 synth voices. So: be thrifty with pixels and
lavish with sound, and let the sound drive the picture.

## Camera

- **Third person for moving and fighting.** The creature sits in the lower third, the camera drifts
  behind it after a moment of stillness, and L2 locks on.
- **First-person focus.** Click the right stick, or draw a sung shot. The camera glides into the
  creature's eyes and the sound narrows to whatever you look at: aiming your eyes aims your ears.
  - You see the shape your note makes against what you're looking at, and its pulse.
  - From there you can tune to it, aim at it, or keep its phrase in your songbook.
  - Release, and you're back outside.
- **The human version:** leaning in to really hear someone.

## Controls on this handheld

Face buttons are named by position, because the printed letters differ from SDL's names.

| input | does |
|---|---|
| left stick / click | move / hold your breath (silence, stealth) |
| right stick / click | look / first-person focus |
| bottom face | jump |
| right face | dash, cancel |
| left face | strike |
| top face | interact, grab |
| R1 tap / hold | call out / **key wheel**: circle of fifths, time slows |
| L1 tap / hold | use your voice's power / **voice wheel**, time slows |
| L2 hold | lock on and guard |
| R2 hold | draw a sung shot; release to loose it |
| D-pad | quick picks: instrument, items, call companions |

- **Thumb check:** the index fingers hold the wheels while both thumbs stay on the sticks, so you
  can keep dodging in slow motion while you choose.
- **Melee:** strikes use the right thumb, so lock-on holds the camera on your target, as in Zelda.
- **This unit:** L2 and R2 are plain on/off buttons, so how hard you draw a shot comes from how long
  you hold.

## The key wheel (hold R1)

- **Choosing.** The wheel never rotates; your current home glows on it.
  - Point the right stick at a key. Push all the way for the major key (outer ring), or halfway for
    its relative minor (inner ring).
  - Let the stick go back to centre to cancel.
  - Push hard to be bright, gently to be tender.
- **Seeing while it's open.** Time slows, and the music slows with it, sinking octaves until chords
  turn into rhythm. Every enemy and object pulses at its own rate, so you read the battlefield's
  harmony as beats.
  - Not a metaphor: a 3-against-2 rhythm sped up a hundredfold is a perfect fifth.
  - Henry Cowell had Leon Theremin build an instrument on that idea, the rhythmicon, in 1930.
- **Release.** You change key (you modulate), and your relationship with everything around you
  changes at once.
  - A neighbouring key is a small flick, a small change and a small cost.
  - The far side of the circle changes everything and costs the most.

## The rule under everything

Everything has a home key on the circle. What happens between two things depends on the interval
between their homes.

| between you and it | feels like | does |
|---|---|---|
| same key | kin | weightless to you: lift, carry, stack |
| it sits a fifth above you | it wants to resolve to you | falls toward you: pull things in |
| it sits a fifth below you | you want to resolve to it | you fall toward it: grapple, fly |
| relative major/minor | same notes, other home | slip through it, hide in it |
| a third | warmth | grow, heal, melt |
| a fourth | opening | doors and flowers open |
| a second or seventh | friction | rattle, crack, unsettle |
| tritone (across the circle) | tearing | shatter, repel, hurts both of you |

On top of that, real acoustics, exaggerated a little:

- **Metal carries sound fifteen-plus times faster than air.** Sing into a pipe and its far end
  sings, the way electricity runs through metal in Zelda.
- **Cold air flattens pipes and flutes; warm air sharpens them.** The hour and the weather detune
  the world.
- **Resonance.** Hold an object's own note and it shakes; hold it long enough and glass breaks.
- **Levitation.** Two voices facing each other on one note make a standing wave that holds small
  things in the air. This is real, done with ultrasound.
- **Patterns.** Sing a stone plate's note and the sand on it gathers into a figure (Chladni
  figures): bridges, stairs, puzzles.
- **Cancelling.** Sing the mirror image of a sound and it cancels into silence, for stealth or for
  defence.
- **Echoes** show you the shape of a cave you can't see.
- **Speed bends pitch.** Sound travels slowly in this world, so running toward a note raises it
  (the Doppler effect).

## Abilities as musical transformations

- **Bind:** hold things together in a chord. Consonant joints hold; dissonant ones shake loose.
  Building a machine is voicing a chord.
- **Loops:** fans, wheels and engines are repeating patterns. Parts in the same tempo move together,
  and 3-against-2 makes a walking gait. Building contraptions is making beats: noodles' clip grid,
  out in the world.
- **Octave:** rise through a surface to the same place an octave up, or sink an octave down.
- **Retrograde:** sing an object's recent movement backwards and it runs in reverse.
- **Graft:** put an interval on a weapon or shot. A fifth splits it, a third makes it seek its
  target, an octave doubles it, a tritone shatters what it hits.
- **Capture:** keep a phrase you heard. The songbook is your map of the world's voices.

## Combat

- **The basics.** Third-person melee, lock-on, dodges, guards and sung shots. Every hit rings the
  enemy at its own note, so you learn enemies by ear while you fight.
- **The pulse.** On-beat actions chain into a melody; off-beat still works, just plainer.
- **In the pocket.** A perfect dodge on the beat slows time into a flurry where each strike is a
  note of a chord. Complete the chord and it rings out.
- **Unison guard.** Block at the moment of impact, at the attack's own pitch, and the sound reflects
  back.
- **Resolving, not killing.** You wear an enemy down with dissonance, then finish it with a cadence
  (the dominant falling home). It resolves, and it transforms.

The enemies:

- **Wolves.** Tune eleven fifths pure and the twelfth comes out short by the whole comma, beating so
  fast that musicians named it the wolf. Ours are made of that error, the part nobody shared, and
  their howl is the beating. A resolved wolf becomes a pup.
- **Knots** are tangled ratios: fear. You untie them into simple loops.
- **Greys** are soldiers of the Grid: perfectly tempered, no vibrato, and they flatten whatever they
  touch.
- **Bosses** are pieces of music. Their phases are movements, and the last blow is the cadence.

A moment: a wolf pack circles you. You hold R1, the world slows, and the music sinks into a slow
pulse with every wolf throbbing against it. You flick to the key a fifth below theirs, so you're
the home they ache for, and they stumble toward you. You release, strike on the beat, and the
cadence lands: the first wolf folds into a pup at your feet.

## Voices

Small, odd, ambiguous creatures with the energy Morgan likes in Puppycat. Puppycat talks through
Oliver, a Vocaloid singing voicebank, next to Bee's human actor: a synthetic voice beside a human
one. Ours would be original creatures whose speech is sung syllables from our own synth.

- **What each one has:** a vowel that colours its sound, a register from bass to treble, a
  temperament, and opinions about who it sounds good with.
- **What they are to you:** your powers (as the sages are in Zelda), your choir, and your friends. A
  low voice stomps and anchors; a high one glides and pierces.
- **The voice wheel** (hold L1) runs dark to bright through the vowels oo, oh, ah, eh, ee. Vowels
  are real shapes in sound, so switching voice audibly recolours everything you do.
- **The story:** at the start you can't sing alone, so they lend you their voices. The game is
  finding your own.

## The world: what the circle shows, and what it hides

What it shows:

- **Twelve regions around a centre, one per key.** Neighbours share six of their seven notes, so
  landscapes blend into each other; the far side is the most foreign place.
- **Three layers of one map:** the deep (bass), the surface, and the sky (treble), the same melody
  in three octaves.
- **The poem's coordinates.** "Two choices: WHERE, and HOW HIGH home is" becomes the world's
  coordinates: where is the key, and how high is the layer.

What it hides. Each of these is a discovery, the way Zelda's Depths are:

1. **It doesn't close.** At the seam where F♯ meets G♭, the world doesn't meet itself.
   - That's where the error collects and the great Wolf lives, and where time leaks in ("a crack in
     the wall where TIME enters").
   - Each year home comes back a comma off, which is 7° of hue.
2. **A second direction.** The circle of fifths is one axis of a grid with thirds running across it
   (the Tonnetz). Tempered, the grid wraps into a closed world; in pure tuning it never repeats, an
   endless frontier. "The primitive IS infinity."
3. **A mirror.** Negative harmony reflects the circle so home and its fifth swap places and major
   becomes minor. The deep is the surface's reflection, and the Mirror Pool is the way down.
4. **A twin across the way.** The dominant chord on the far side shares the same restless interval
   (the tritone) as the one next to home, so it can stand in for it. The far side is secretly next
   door: shortcuts.
5. **A rhythm inside every scale.** The West African standard bell pattern puts seven strokes in
   twelve with gaps of 2,1,2,2,1,2,2, which are exactly the steps of the natural minor scale. Both
   are the most even way to place seven in twelve.
   - Each region's drums play its scale.
   - Changing key rotates the world's rhythm, including how its creatures attack.
6. **Notes off the map.** The seventh harmonic, the blue note, sits 31 cents flat of the piano's and
   isn't on the wheel at all. Caravan No. 27 trades in notes like that.
7. **Time and pitch are one thing.** Slow down enough and chords become rhythms; speed up and
   rhythms become chords.
8. **Space is harmonic.** In tuning theory each prime number is its own direction: 2 is up and down
   (octaves), 3 is around (fifths), 5 is across (thirds), 7 is the hidden one.

## What it's about

Two forces pull at the world:

- **The Grid** tempers everything until nothing is out of tune and nothing wants anything: grey,
  safe, finished. "A music with no remainder leaves nothing to want."
- **The Wolf** is purity that refuses to share its error, so the error piles up somewhere and howls.
  "Errors do not sit well with my stomach."

The way through is neither. It's the treaty made with love: choose a home with someone, and carry
the small difference between you on purpose. "Harmony cultivates wanting by metabolizing our error
as remainder."

The ending is a duet. Two voices lock, and a third voice, home, appears between them, sung by
neither. With JJ's console in the room, that third voice can happen in the air.

The game takes the shape of Morgan's poems (home as a person, the gap kept on purpose), not his
biography. The odd/even passage from his worksheet stays out unless he says otherwise.

## What to test first

The key wheel, inside the 3D meadow, with sound. Hold R1; time and music slow into pulses; flick
and release; the meadow answers. The light shifts, a boulder rolls toward you, a crystal shatters,
a wolf staggers in. The question is whether flick-and-release feels fast and powerful in the hands.

---

## Not yet connected

Saved as they are; these are the places the ideas don't yet fit together.

- **Whose key wins.** Regions have keys, objects have keys, you have a key. When you modulate, does
  the region's key still pull? For how long?
- **One breath for everything.** Sprinting, climbing, singing and holding a wheel all draw on
  breath. How it balances is unknown.
- **The Grid and the Wolf in the world.** Where they live, how they spread, and how they relate to
  the twelve regions and the seam.
- **Voices.** How many, how you meet them, whether they map onto Garden's five kinds (Leaf, Rock,
  Water, Fungal, Ember).
- **Hidden layers.** Three octave layers, a Tonnetz frontier, a mirrored deep, tritone shortcuts:
  probably too many for one game; pick the ones that carry the most.
- **Combat arithmetic.** How dissonance damage, finishers, lock-on and melee fit together.
- **Two consoles.** What the game does when it can't hear the other console.
- **Scale.** How big the world can be on this hardware; the meadow benchmark has not run on the
  handheld yet.

---

## Earlier ideas this builds on

From the message before (2026-11-12/13), kept here so nothing is lost.

### Where sound and sight blur

1. **Light is sound, forty octaves up.** Raise a note by whole octaves and it lands in visible light;
   the eye sees almost exactly one octave of it (400–790 THz, 1,178 cents).
   - A440 raised 40 octaves is 620 nm, orange. Middle C raised 41 octaves is 521 nm, green.
   - The octave of light runs from F♯ (737 nm, deep red) to F (390 nm, deep violet), a semitone
     apart in sound.
   - The rainbow is a line; the eye bends it into a wheel by inventing purple, a colour with no
     wavelength. The eye fakes the closure. Morgan's worksheet asks "Is color in the eye?" Purple
     is, and the Khole Caddy palette (aster, verbena, snowberry) is built from it.
   - Where the seam falls depends on where you set A: the treaty again.
2. **The same equation, heard and seen.** One note against another on an oscilloscope makes a
   shape: 1:1 a circle, 3:2 a pretzel, 5:4 a rosette. Pure intervals draw closed, still figures; a
   tempered fifth draws the same figure slowly turning and never closing. Let the sound fade and the
   figure spirals inward (a harmonograph). A creature's body can be the drawing of its voice.
3. **Two voices make a third.** Lock two voices on neighbouring harmonics (5:4, 3:2, 4:3, 6:5 all
   checked) and the ear hears their common root, home, which neither is singing. The eye's version
   is moiré: two fine patterns slightly out of step make a third that is in neither. A possible
   reading of "Two pins and a generator, music?": two people's notes, and the generator appears
   between them.
4. **In the room.** Two handhelds in one room beat against each other in the air. Lock a pure
   interval and the third voice can sound between the consoles, made by neither. Untested on these
   speakers.

### What it's about

Being heard; losing your own note inside someone else's key; finding it again; singing beside
someone without disappearing into them. You begin without a voice of your own; the game ends when
you can sing in your own key next to someone else's and let the small difference ring.

### Human acts as verbs

- **Hum:** your note is your light; you carry it like a lantern.
- **Call:** a shout travels out as a ring of light and lights whatever it touches. At 2am you see by
  calling. Sometimes something calls back.
- **Listen:** go still and the world's own song becomes visible (the worksheet's NOTICE).
- **Answer:** match a voice that called you, and it trusts you.
- **Comfort:** some places ache, a chord left hanging; bring the note that lets them rest.

### Morgan's worksheet as the game

- **The loop:** notice, capture, extract, select, sing. Walk a place, gather what had gravity, sing
  it back at the season's end, and the place changes.
- **The cast**, from its template (it is, it came from, it wants, it knows something about):
  - The Mirror Pool wants to return to the ocean and knows about time.
  - The Knot wants to be undone and knows about ego.
  - Caravan No. 27 wants to trade and knows about harmony (27 is three fifths stacked).
  - Jeanne, 19, carries a compass that points wherever you decide home is.
  - The white cat waits in the road.

### Feel in the hands (from the first sketch)

- **Pointing is singing:** the right stick as a colour wheel that is also the circle of fifths.
  Close but off, you hear the wobble and see the figure turning; exactly right, it goes still and
  the third voice blooms.
- **Moving is rhythm:** run, jump, glide and bounce on the world's pulse.
- **Your choir is your body:** befriended voices travel with you; the chord you carry decides what
  you can do. Two voices that hold a lock long enough merge; the new creature's body is the figure
  of their chord.
- **Pressure:** storms drag you sharp; each year home drifts a comma (7° of hue) and you choose it
  again.

### Music facts kept from the first reply

- Octaves are the even numbers of the harmonic series: they feel whole because they take you nowhere
  new. New notes come from odd numbers. 27 is three fifths stacked; 7 is the note the twelve-note
  treaty has no room for.
- The comma exists because a power of three can never equal a power of two.
- Glowing lines on black are the cheapest beautiful thing this GPU draws.

### The first moment to build (proposed before this shape)

A dark field. You call; a ring of light goes out and touches nothing. You call again; far off,
something answers in a colour that isn't yours. You turn the stick toward it; the figure between
you slows and closes, and a third voice sounds and is drawn between you. It comes to you.

---

## Sources

- [Fextralife: TOTK controls](https://zeldatearsofthekingdom.wiki.fextralife.com/Controls)
- [StrategyWiki: TOTK controls](https://strategywiki.org/wiki/The_Legend_of_Zelda:_Tears_of_the_Kingdom/Controls)
- [ConsolePulse: abilities](https://consolepulse.com/nintendo/zelda/guides/zelda-totk-abilities-ultrahand-fuse-ascend-recall-guide)
- [Dot Esports: abilities and the wheel pausing the game](https://dotesports.com/zelda/news/all-abilities-and-how-to-get-them-in-zelda-tears-of-the-kingdom)
- [Fextralife: TOTK combat](https://zeldatearsofthekingdom.wiki.fextralife.com/Combat)
- [Thumbsticks: GDC 2017, the chemistry engine](https://www.thumbsticks.com/gdc-17-breath-of-the-wild-science-lies)
- [Tom's Guide: GDC 2017 talk](https://www.tomsguide.com/us/zelda-breath-wild-design,news-24586.html)
- [GameCube spec sheet (fill rate 648 Mpixel/s)](https://gamicus.gamepedia.com/File:Hardware-GameCube.png)
- [Sportskeeda: Puppycat's voice (Oliver)](https://sportskeeda.com/pop-culture/who-voices-bee-puppycat-everything-know-va-vocaloid-program-behind-characters)
- [Wikipedia: Bee and PuppyCat](https://en.wikipedia.org/wiki/Bee_and_PuppyCat)
- [Red Bull Music Academy: the rhythmicon](https://daily.redbullmusicacademy.com/2015/06/rhythmicon-feature)
- [Demaine et al.: Euclidean rhythms](https://users.monash.edu/~davidwo/papers/Demaine-etal-Rhythm-CGTA.pdf)
- Measured hardware numbers: `docs/hardware-target.md`.
