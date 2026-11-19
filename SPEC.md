# gameguy: the specification

_Working title of the game: **Oh. You're in.** They are the first words anyone says in it. Morgan
names the game; other candidates are in `DECISIONS.md`._

_Written on 2026-11-19 by Fable, from every document in this repository, as the outcome of the
planning session that Part 0 of the brainstorm asks for. This file is decided, not a brainstorm:
where it disagrees with an older document, this wins. Morgan edits it, and his edits win over
everything._

## 1. Objective

Build a complete, original game for the R36S family of handhelds: the largest and most complete
version the material supports. It is done when a scripted player can play it from the first evening
to the thirteenth morning with no errors, every place has been looked at, and Morgan has played it
on his handheld (section 21).

## 2. Why

- **Who it is for.** Morgan first, on the only console he owns. JJ second, on the purple one. Third,
  anyone with an R36S or a clone who is willing to try it.
- **What it is made from.** Morgan's own work:
  - the poem (brainstorm, Appendix A), where the circle of fifths is a spiral that never closes,
    home is a place you choose, and "ache IS the engine";
  - noodles, where the wheel never turns and changing key is travel;
  - wasatch, where a lake decides whether the music may come home;
  - the worksheet (`material/`), where a pool, a knotted hose, a sapling and a fly on the knee
    become a cast;
  - his favourite games, most of all Majora's Mask, Tears of the Kingdom and Outer Wilds.
- **The test,** from his brief: "A game that could have been made for anyone, on any machine, has
  failed even if it runs."
- **What he asked for,** in his words:
  - "a Tears of the Kingdom ruled by music where the nature of existence and love and humanity and
    the very fabric of space and time is revealed through the lens of music and harmony and math and
    sound and love and dissonance";
  - "deep and beautiful and challenging and calming and puzzling";
  - "heartfelt and wondrous but still actually addictingly fun";
  - one console or two "without trade-offs";
  - "a seriously AAA game... like the scope of Tears of the Kingdom";
  - "maximize this project's experience, beauty, impact, possibility space, and the human
    experience, **be ambitious**".

## 3. Which source wins

1. Morgan, in a session.
2. This file, and the files in `spec/`.
3. `DECISIONS.md`.
4. The design documents, newest first: `the-whole-game.md`, `together.md`, `the-card.md`,
   `drawn-in-light.md`, `the-page-and-the-place.md`, `the-wheel.md`, `the-way-home.md`,
   `experience-fixes.md`, `thirteenth-morning.md`, `memory-in-rhythm.md`, `look.md`, and shapes 3, 2
   and 1. They hold the detail and the reasons. Where this file is silent, they stand.
5. The brainstorm.

`spec/ideas.md` lists every idea in those documents and where it lives now. Nothing in `toys/` is
the game: the toys proved things, and the game reuses what they proved (section 19).

## 4. The game in one breath

You are Hum, a small plaster creature who can sing one note, in a world drawn in lines of light
where everything that sounds shines and silence is dark. The world is a garden after a storm, seen
from a seed's height: twelve lands round a lake, one for each key, and every thing in them is an
instrument that obeys the real laws of sound. Each morning comes a pure fifth higher. Each night a
river carries you home, sings your day back, and lets you keep four of your past selves as a band.
About a hundred lives keep their own cycles round the lake, each with a tune it can't finish. Twelve
mornings on, home comes back a hair too warm, and what you do with that small difference, alone or
with someone holding the other console, is the ending. After it you have a voice of your own, and
the mornings never repeat.

## 5. The rules of the design

1. **Human first.** Every part starts from something a person feels: calling and being answered,
   being seen, losing a voice and finding it, keeping and letting go. The mechanic and the code come
   after.
2. **It sounds good.** Consonant and beautiful by default. Dissonance is brief and always going
   somewhere. The comma is felt in the story and the world, and heard only in a few earned seconds.
   Fable can't hear, so Morgan's ears judge every sound idea from a short sketch on the handheld's
   own speaker.
3. **Literally true.** One model of frequencies, phases and ratios drives the sound, the picture and
   the physics. Nothing is matched by hand, and no effect is looked up in a table that the laws in
   `spec/laws.md` could produce.
4. **In the first turn you never choose a note.** You choose a moment, a home, a voice and a mood,
   and everything lands in key and in time. Choosing notes is the ending's gift.
5. **Nothing dies.** Things transform. You can't die either: the sun sets on you.
6. **Nothing on the screen that isn't in the world.** No meters, no map screen, no menus in play. At
   most one line of text, large.
7. **Lines of light on black,** drawn the way an oscilloscope's beam draws. Hum and the voices
   riding on it are the only solid things. No human faces. The style book's rules hold
   (`design/look.md`).
8. **Every cue twice.** Whatever the player needs to know is in the sound and in the light, so the
   game can be played by ear alone or by eye alone. The code enforces it (section 15).
9. **Whole alone.** No door, fight or land needs a second console. Together adds; it never takes.
10. **A take is its inputs.** The same hands make the same world and the same sound on every
    machine.
11. **Original.** No existing game's world, characters, music or look.
12. **Morgan's own layer stays his.** Who the vine is, who sat on the pool's edge and in the chair,
    and the odd and even passage are never filled in for him.

## 6. What playing it is

### 6.1 The first evening

1. **Black, and a drip.** The backlight itself is down, so the black is black. Low on the screen, a
   small bone-white shape in reeds, breathing.
2. **You call** (tap R1). A ring of light runs out over the ground and shows reeds and a coiled
   hose. The second call is always answered: far off, a ring comes back in teal, and a ripple on the
   ground shows which way.
3. **You find it and breathe with it.** Stand still beside it and the view leans in. Hold R2 to hum
   and let go on its tick. Between you a flat figure turns: three lobes by two. Four breaths
   together and the figure stops dead. A third note sounds under you both that neither of you is
   singing.
4. **"Oh. You're in."** The drop falls on your head and stays. That's Drip. Until now the world has
   been a page seen from above. Now it tilts back and stands up around you: reeds, a spigot, asters
   as tall as cathedrals, a sky with the day coming up in it, in the key of C.
5. **Everything is an instrument.** Your call rings whatever it passes, and whatever shares your
   note answers across the garden in its own light. A still pool shows lines on its surface when you
   hum its note, and you can walk on them.
6. **The hose is knotted, and the knot is moving.** Three small knots stumble at you. Hold R1: time
   thickens, the place folds back to a page, and on the wheel the strands' threads cross on one
   wedge. Point there and let go. Now they dance in three and in five over a one that you are
   singing. Strike on the one. Dodge on the beat and time opens into a pocket. A grey knot leans;
   hold R2 while the swell builds, and let go on the one. It springs open. Water runs. The hose,
   unstopped, sounds an octave higher and brighter than it did. For a second a blue figure sits on
   the pool's edge.
7. **Dusk.** The river carries you home and sings your day back in half a minute. You keep a take. A
   post carved in the world's old script offers a repeat sign or a bracket.

### 6.2 A day

A day is about twenty minutes, shaped like a song, and it follows the five steps of Morgan's
worksheet. The music and the sun are the clock. You can stop anywhere.

| hour | song | what the day asks | the worksheet's word |
|---|---|---|---|
| dawn | intro | wake at the garden; Drip hums you back in; the river post | |
| morning | verse | walk the day's land; listen to who is there today | notice |
| noon | chorus | the land's great instrument, its packs, everything sounding | capture |
| afternoon | bridge | what your kept phrases are made of; wonders; who wants what | extract |
| dusk | chorus | the land's people gather for the reason they sing; the pack comes | sing |
| night | outro | the river sings your day back; keep four; Repeat or Onward | select |

### 6.3 The turn

Thirteen mornings, each a pure fifth higher, each rising over the next land round the lake.
`spec/world.md` has every land in full.

| morning | land | key | tuning | why they sing there | its great instrument | what is new |
|---|---|---|---|---|---|---|
| 1 | the Garden | C | pure | the morning song | the Hose | Drip; wonder and sunny home; stand where they meet |
| 2 | the Alfalfa | G | pure | the work song | the Wind Harp | Box Elder; drive |
| 3 | the Glass Hills | D | pure fifths | the vigil | the Armonica | Doorstop; cool soul; the first borrow is home |
| 4 | the Bell Meadow | A | sweet thirds | the wedding dance | the Belfry | tenderness; the caravan; the first pack; a walk of three |
| 5 | the Highway | E | sweet thirds | the blues at 2am | the Looper, at the Stage | Patio; fierceness; the vine sings your third; the lean |
| 6 | the Chrome Nave | B | well-tempered | the hymn | the Organ under the hood | the old machines; the turn |
| 7 | the Seam | F♯/G♭ | equal | the market and the march | the Piano | the Metronome; the ferry; the Wolf in the crack |
| 8 | the Aster Steps | D♭ | well-tempered | the lament | the Bell Jar | Break: your voice cracks, and opens |
| 9 | Verbena Hollow | A♭ | sweet thirds | the serenade | the Music Box | a chord is a triangle; the close that misses |
| 10 | the Rain Steps | E♭ | sweet thirds | the remembering | the Cistern | Puffball; what you let go comes back as rain |
| 11 | the Reed Mouths | B♭ | pure fifths | the chant | the Mouth Organ | be the ground; your band fights for you |
| 12 | the Porch | F | pure | the porch song | the Guitar | the oldest echo; the night that doesn't close |
| 13 | the Garden | B♯ | pure, a comma sharp | everyone | | the whole turn in one breath; the clap, the step, the hold |

- **Going out, mornings 1 to 7:** a new voice, a new mood and a new land each morning
  (`design/thirteenth-morning.md`).
- **The way home, mornings 8 to 12:** the garden's note comes back onto the wheel a comma sharp and
  walks one wedge a morning toward home. The sun rises doubled. Each morning has one thing to face
  and none is a boss to beat (`design/the-way-home.md`).
- **The thirteenth morning:** three gestures you have made all game, each carried to its end. The
  clap is the Grid's offer, the step is the Wolf's, and the hold is the duet
  (`design/the-wheel.md`). The two bleak ones can be taken, and the river offers the morning again.
- **Repeat or Onward.** Any morning can be lived again. Its events restart, what you resolved stays
  resolved, and your kept selves walk beside you.

### 6.4 After

- **Your own voice.** Seated, the right stick points at a note and Hum sings it. The fifths are the
  ones you walked, the third is the one you were given, and the seventh comes from the caravan. "It
  is freedom, our arrival."
- **Each night** you choose up a fifth, down a fifth, or stay.
- **Past the lake,** lands by thirds and then by sevenths that never repeat, made from rules and
  from songs (`spec/world.md`).
- **The spiral goes on.** The true near-misses are real places: 41 fifths out, home comes back a
  fifth of a semitone flat; 53 out, 3.6 hundredths sharp; 306; and 665, where two tones swell once
  in 87 seconds.
- **The sky, the deep, the Shimmer, the islets and the forty octaves** for whoever goes looking.

### 6.5 How long

A target, not a measurement: 60 to 100 hours to see the first turn fully, with most mornings lived
several times. After it there is no end.

## 7. The laws

Every thing in the world is a resonator with the overtones of its shape, or a pendulum, or both.
Seven laws hold for all of them and for Hum. `spec/laws.md` has the numbers.

| law | in a sentence | what it lets you do |
|---|---|---|
| 1. Sympathy | sound flows between things that share overtones | ring one thing and everything kin to it answers; you can only move what your voice shares something with |
| 2. Gravity | an overtone falls toward the note that contains it | put home under a thing and it comes to you; put home over it and you go to it |
| 3. Falling into step | things at nearly the same rate pull each other together | lead a parade; bind parts into one machine; tune a crowd to your drone |
| 4. Standing waves | a driven thing shows still lines and bellies | walk the still lines; be thrown by the bellies; hold things in the air between two voices |
| 5. Cancelling and beating | opposite sounds make silence, which is dark; near-misses beat, and the beating turns things | hide; clamp with a pure pair; drive a wheel with a tempered pair |
| 6. Travel | sound moves at a speed you can see | send a phrase to a wall and get it back; hear the far shore late; ride a note |
| 7. Building up | push a thing at its own rate and it grows | swing a giant; ring a tower; break glass; or take the swing out |

- **Home is laid over the laws.** The wheel decides where home is, and law 2 then says what every
  thing is to you. The canon's table of relations (kin, a fifth above falls to you, a third warms,
  across pushes away) is what the laws do in the simplest cases, and it stays the short version:
  "beside it, it comes home; on it, it's with you; across, it flies; a third round, it warms."
- **Building is instrument-making.** Join resonators and pendulums and they become machines that
  play themselves: a string stretched between two stalks, a bottle on a pipe, a pinned wheel that
  plucks a comb.
- **Every thing has a tune,** and what you do to the tune you do to the thing: move it up or down
  and the thing moves; sing it backwards and the thing runs back; sing it slower and the thing
  slows.

## 8. Hum's hands

Face buttons are named by position.

| input | tap | hold |
|---|---|---|
| left stick, L3 | move; click to hush (stop humming, go dark) | |
| right stick, R3 | look; steers a wheel while one is open; click to lean in | |
| bottom face | jump; in the air, open or close the glide | |
| right face | dodge (on the beat: the pocket); talks when nothing threatens | sprint |
| left face | strike with the fork | charge; let go on the beat |
| top face | grab, talk, plant | carry; leaning in, keep a phrase |
| L1 | last voice | the voice wheel, on the left stick |
| R1 | call: a ring of light | the mood wheel, on the right stick; the place folds to the page |
| L1 and R1 | the clap | both wheels at once |
| L2 | lock on, next target (it latches) | guard |
| R2 | a short phrase | sing: the swell. A nudge of the right stick on a downbeat walks home one wedge; a half push leans the note |
| D-pad down | sit and listen; seated, the pad is an instrument | |
| D-pad up | gather your echoes | |
| D-pad left | again: your last bar keeps playing beside you | |
| D-pad right | play a kept song | |
| Select, Start | the songbook; pause | |

- **Thumb audit.** Moving and singing: left thumb, right index on R2, right thumb on the wheel.
  Moving and fighting: left thumb, right thumb on the face buttons, lock-on latched so the camera
  needs no thumb, left index free to guard. Wheels: an index finger holds, a thumb steers. The clap:
  both index fingers. Gliding: a tap opens it and a tap closes it. Nothing ever needs the right
  stick and a face button at once.
- **Leaning in also happens by stopping:** stand still facing a voice for one bar.
- **Your own voice answers within one sound buffer.** Hands are stamped with the time of the sound
  card's clock, and Hum's breath starts on the next buffer (section 19).
- **FN is never needed.** Not every firmware delivers it.

## 9. The wheel, the voices, the breath

`design/the-wheel.md` stands in full. In brief:

- **You can sing one note. The wheel decides where home is.** Seven lit wedges are seven moods and
  seven powers: wonder (Lift), sunny home (Bind), drive (Drive), cool soul (Flow), tenderness
  (Remember), fierceness (Strike), the darkest (Break). They never move under the thumb. The ring of
  twelve notes turns behind them one notch each morning, so the wheel is also a compass, a calendar
  and a sky.
- **Each mood is also a groove.** Seven lit of twelve is the pattern of the scale and of a bell
  rhythm played across West and Central Africa. Where home sits decides where the pattern starts, so
  each mood has its own feel and each land's creatures move in it.
- **Five dark wedges are borrowing.** Reach under the horizon and home visits a note that has set,
  for one phrase, and the land comes with it. The first borrow, home on the third morning, is free.
- **Five voices are who sings,** bass to treble: Doorstop (oo), Drip (oh), Box Elder (ah), Puffball
  (eh), Patio (ee). Low voices move heavy things and the ground; high ones move light things, the
  air and you. Each voice's overtones decide what it can reach (law 1).
- **Small voices.** Each life you help lends a colour of one of the five.
- **The swell** (hold R2) grows a colour each bar. A nudge on the downbeat walks home one wedge and
  brings what you pass with it. Where home is when you let go decides which of four cadences lands:
  the full close, the amen, the turn, the slide.
- **Push hard for bright, gently for tender.** How far the stick is pushed is how loud and bright
  the note is.
- **The lean.** From the fifth morning, a half push toward a neighbouring wedge bends the held note
  toward it. It always resolves when you let go.
- **One breath** pays for singing, the wheels, sprint and glide, and silence refills it. Dodging and
  guarding are free. A breath holds three homes at first and grows by one each time you land a
  longer walk, up to seven; the ferry makes eight.

## 10. Fights

- **On the beat.** Every hit rings the enemy at its own note. Dodge on the beat and the pocket
  opens. A strike you time yourself rings fuller than one the game placed.
- **The looper in a fight.** Each bar you stay in the pocket, your last bar's strikes keep landing
  beside you as an afterimage, up to four layers. The clap cashes them in: everything near resets to
  the same point in its cycle.
- **Nothing dies.** Hits drain colour, a grey creature leans, and a cadence on the downbeat brings
  it home. The mood you bring it home in is the gift it leaves.
- **Wolves** are made of the comma. **Knots** are fear, tangled rhythms. **Greys** are the Grid's
  soldiers, on the grid exactly; swing breaks them and standing a third away brings their colour
  back.
- **Bosses are pieces of music:** the Great Knot (five against seven), the Metronome (it learns you;
  swing breaks it), the Wolf at the Seam (every echo you turned away from). Each great instrument
  has its own trial on Fierce.
- **Gentle or Fierce,** chosen any night. Gentle widens the timing and the ledges, leans home for
  you, and lets most fights end by comfort.

## 11. People

About a hundred lives (`spec/people.md`).

- **Each has a tune, a round and a want.** The round is where it is on which morning: a cycle of 3,
  4, 5 or 7 mornings, and two that take 13 and 17. The want is an ending its tune can't reach.
- **Each land has eight,** and a reason they sing together: the table in 6.3.
- **Helping is the day's five steps.** Notice who is there today. Lean in while they sing, and keep
  the phrase. Find what it is missing: the other half is somewhere else or some other morning, in
  another life, a place, a wonder or one of your own echoes. At dusk, when the land gathers, sing
  with them and land the cadence their tune needed.
- **What it changes.** Their part joins the land's dusk song for good, they lend you a small voice,
  and the river sings them in your night. A land with all eight sings its whole song.
- **On the thirteenth morning** every round lines up and all twelve songs are one.
- **Lives are sums.** Where a life is, and what it is singing, is worked out from the morning's
  number. An almanac page in the songbook shows any morning to come.
- **Nobody is explained.** Every line is sung, in the speaker's vowel, with one line of caption at
  most. The seven moods are your seven answers.

## 12. The world

`spec/world.md` is the atlas. In brief:

- **The ring:** twelve lands round a lake, in the order of the circle of fifths, the garden at the
  north. Each has a key, a tuning, a material that sets its physics, a metre, a tradition named in
  the songbook, a river to free, a great instrument to go inside, eight lives, twelve wonders, a
  noon face and a 2am face.
- **One continuous place.** From any shore you see every land's lights across the water, and hear
  the far ones late.
- **The lake:** to sail, with islets tuned in finer steps and the Shimmer, a bronze grove that beats
  on purpose. Its level is the world's memory: low, phrases end on almost-endings; each freed river
  raises it.
- **The Seam:** the one city, on a bridge over the crack where the lake drains, running on the
  beating it agreed to share.
- **The sky** is a ladder of overtones whose rungs shrink for ever. **The deep** is its mirror, and
  at its bottom is a country with no octave.
- **The forty octaves** are places: inside a petal, the planets, the beginning, and light.
- **144 wonders,** twelve to a land: each is one true thing about sound, found by doing it.
- **After the thirteenth morning,** lands by thirds and sevenths, and the long spiral.

## 13. The loop, memory and the card

`design/the-whole-game.md` ("The loop and the river"), `design/experience-fixes.md` and
`design/the-card.md` stand. In brief:

- **At dusk** the river sings your day back, backwards from a big win. You keep up to four takes as
  echoes. The rest walk into the water, and the water keeps them.
- **Echoes** are flat blue selves that walk, fight and sing beside you, always retuned into today.
  They age by mornings travelled, set and rise on the wheel, and on their eleventh dusk step in
  front of you: let it go, sing it again, or turn away.
- **What you let go becomes the place.** A released take plays through the lake again and again
  until only the lake's own ringing is left. Pools play it back for a phrase, the vine hums it, and
  on the tenth morning it rains.
- **The Grid is a day that changed nothing.** Only that sets grey.
- **Dreams** join paths. **Sleep** eases what you practised. **Pools** hold what happened beside
  them: each of a pool's overtones is one memory, and the deeper ones need notes you don't have yet.
- **The card is the world's memory.** Every take is kept, a save is made every dawn, and the
  handheld keeps its own copy. The book has a page a day. Songs leave as sound, as notes and as
  separate tracks.
- **The handheld doesn't know how long it was off** (measured). Days are counted in mornings played,
  never by the calendar.

## 14. Two consoles

`design/together.md` stands: letters, side by side, visits over the cable, Drip's seat, trading
fours, the water you share. Added:

- **Their voice is your depth.** Alone, a body's depth is the note between its own note and home.
  With the other console linked, what they sing is that third note.
- **The comma in real air.** Each console holds one tone, a comma apart, and the beating happens in
  the room between the two speakers. It needs no cable.
- **Lent voices.** Six short sounds (a hum and five vowels) recorded on a phone and put on the card,
  and Hum sings in your own voice. The built voices are complete without it.
- **Songs are seeds.** A phrase played at the river grows a friend's plant in your garden. It can be
  passed on by ear or by a photo of the page.
- **If the jack takes a headset's microphone** (not yet known), the game can hear you: the hush seat
  is heard, and seated, Hum can follow your voice. Nothing depends on it.

## 15. Sound and picture

- **One set of numbers.** Pitch class is hue, by fifths. Octave is height. Loudness is brightness,
  and silence is dark. An interval is the figure between two voices: still when pure, turning at the
  beat rate when tempered. Timbre is the texture of a line. Phase is things moving together. Depth
  is the third note.
- **The beam.** Things that sound leave a short afterglow. A figure is brightest where its beam
  slows to turn. Afterglow is memory: a low lake forgets and trails die fast.
- **The page and the place** are one world on one hinge. Hold the wheel and it lies down to be read.
- **The backlight is the sun.** The game sets the screen's backlight itself: nearly off in the first
  dark, low at 2am, up at noon, and breathing a little with the music. It is more than half of what
  the idle handheld draws, so dark hours are also long hours on the battery. Morgan's eyes decide
  whether the breathing stays.
- **Made from the same physics.** Every sound is resonators being struck, bowed, blown or sung: no
  recordings are needed. Each place's echoes are worked out from its shape and kept on the card.
- **The speaker is the floor.** Low voices are built from upper overtones and the ear supplies the
  root. Nothing essential is in stereo or deep bass. Headphones add space.
- **Every cue twice, in code.** A thing the player must notice is declared once, with its sound and
  its light together. A cue with only one of them does not compile.
- **Out of tune is never blur.** It is two crisp copies sliding against each other on the beat, or
  flat where it should be deep.
- **A seeing option:** heavier lines and a lifted floor for blacks.

## 16. Scope

- **In:** everything in sections 4 to 15 and in `spec/`.
- **Later, and nothing depends on them:** a microphone or an instrument over USB (the kernel has the
  drivers; nothing has been plugged in); more than two consoles through a hub; rumble, if a motor
  turns out to be fitted; builds for other platforms (`docs/other-platforms.md` has the rules that
  keep them possible, and the game keeps those rules from the start).
- **Out:** a network; anything that needs a second console; recorded music; any human face; any
  existing game's world.
- **Must not change without Morgan:** the rules in section 5, and the list of his calls in section
  17.

## 17. What proceeds without asking, and what is Morgan's

- **Proceeds:** every technical choice; everything in this file; building, testing and measuring on
  the laptop and the purple; committing and pushing to the private repository; writing each decision
  and its reason in `DECISIONS.md`.
- **Needs his word first:** anything on the black while he is testing on it; changing the
  repository's visibility; switching a port's 5 V on (never with a computer on that port); anything
  that would erase a card or a unit's storage.
- **His calls, with the default this file takes until he says otherwise:**

| call | default |
|---|---|
| the name | "Oh. You're in." |
| who the vine is; who sat on the pool's edge; who sat in the chair | left blank |
| which of his words appear | "Oh. You're in." and Jeanne's three lines |
| the odd and even passage; the moth | out |
| how much of the style book's world comes in | the Stage, the Highway and the Chrome Nave as lands; no seal or sigil redrawn |
| recorded sound | none; lent voices optional |
| the Grid's and the Wolf's endings | real, takeable, and the river offers the morning again |
| the thirteenth morning with two consoles | each with their own vine, side by side |
| release to other R36S owners | built so it can be; whether and how is his |
| by ear | every sound, from the room (section 21) |

## 18. Evidence

Measured numbers the design rests on (`docs/hardware-target.md`; `probe/results/`):

| what | measured |
|---|---|
| a frame | 17.1 ms at 58.46 Hz; a 60.02 Hz mode exists |
| cores for the game | three; the fourth takes the storage interrupts |
| overtones one core renders in half a 2.67 ms buffer | about 2,100 at the purple's throttled clock, bit for bit the same as on the laptop |
| picture | 30,000 lines of light a frame in 11.1 ms, and 40,000 in 13.2 ms, every frame on time, with black shapes and all three passes (`game/` on the purple); three render passes at most, because each costs a fixed amount |
| the page toy's whole frame | 1,400 marks in 1.3 to 3.6 ms of one core |
| memory | 918 MiB, about 815 free when a game starts |
| the card | reads 43 MB/s with next to no interrupts; a 64 KB save in 9.5 ms |
| the cable between two units | 0.47 ms round trip, none lost in 5,050 |
| one take, every machine | world and sound identical on the laptop, the purple, WebAssembly and C builds |
| the backlight | 208 of 388 mA at idle; settable from a program |
| the clock | does not count while the unit is off |
| a microphone on the board | none |
| the rumble line | can be driven; whether a motor is fitted is not known |

Still to be measured, and by what:

| what | how |
|---|---|
| button to sound, button to picture | the room, with Morgan's phone filming, or a headset if the jack records |
| a headset's microphone through the jack; a motor on the rumble line; the breathing backlight; the speaker's loudness | the room, with Morgan's hands, eyes and ears |
| drift between two units' sound clocks; a link that lasts hours; the cable pulled | stage 6, with the black hosting |
| a place's baked echoes: size and cost | stage 2, on the Garden |

Estimates are marked as estimates wherever they appear. A number in this file or in `spec/` that is
neither measured nor marked is a mistake.

## 19. The engine

`spec/engine.md` has it in full. In brief:

- **Zig, on a clean slate,** in `game/`. The toolchain and the same-take proof already exist in Zig.
  It reuses what the toys proved: `toys/common/` for the platform, the launchers' three fixes
  (storage interrupts on their own core, clocks pinned, real-time sound), the phosphor from
  `toys/page/src/gfx.zig`, and `toys/wheel/tools/same-take.zig`.
- **The world steps 60 times a second and takes only hands.** It never reads a clock, the screen or
  the sound card. Hands are stamped in samples of the sound card's clock, so a take is a list of
  stamped hands and nothing else.
- **Sound follows the world's count.** One bank of resonators renders everything: rung things,
  strings, pipes and sung vowels. The world tracks each resonator's loudness 60 times a second for
  the rules and the picture; the sound thread renders the same overtones 48,000 times a second.
- **The picture** is lines kept on the GPU in pieces, loaded from the card as you walk, with black
  shapes that hide what is behind them, drawn in three passes with the phosphor.
- **The world is written as scores:** one text file per land, which tools turn into places. A land
  can be regenerated, looked at from above and from inside, and fixed.
- **Sounds are data.** Every instrument and voice is a small text file of overtones, so Morgan can
  shape them without touching the engine.
- **The thirteen rules** of `docs/other-platforms.md` hold from the first line.

## 20. Stages

`spec/stages.md` has each stage's contents and proof.

1. **The workshop and the engine.**
2. **The first evening and the Garden,** finished: every verb, the Hose, the Garden's eight lives
   and twelve wonders, the river, one echo, a second morning beside yourself.
3. **Going out:** mornings 2 to 7.
4. **The way home:** mornings 8 to 12.
5. **The thirteenth morning and after:** the three endings, your own voice, the lattice, the sky,
   the deep, the long spiral.
6. **Two consoles.**
7. **The book, lent voices, and release.**

Each stage ends the same way: the whole game so far played through by the scripted player with no
errors; frames from every place dumped and looked at; the measuring tools run on every new sound;
the same-take test passed on the laptop and the purple; a session on the purple logged; everything
committed and pushed; `PROGRESS.md` brought up to date; and Morgan's hands on it. After stages 2, 5
and 7, a reader with fresh context grades the build against this file.

## 21. Verification

The ladder from Part 0, each rung catching what the ones below can't:

1. **It builds:** `game/build.sh`, from a clean checkout.
2. **Rules tests:** the world and the sound have no platform code and are tested without a screen.
3. **A scripted player** plays the game so far, with no screen, and reports numbers.
4. **Any error on the console** means the build is broken.
5. **The frames:** after each round of drawing, dump them, look, name the weakest thing, fix it.
6. **Ears by measurement:** roughness, loudness, balance and what survives a small speaker, for
   every new sound. This cannot say a sound is good. It can say a sound is rough, quiet or missing.
7. **A fresh reader** grades the build against this file. The builder never grades itself.
8. **Morgan, on the handheld.** The room (`game/tools/room/`) is where his answers are logged: a
   clip or a moment, and a button for yes, no or again. This is the only rung that says the game is
   good.

## 22. Starting a build session

A build session opens with this file, `PROGRESS.md` and the brief below, which is Part 0's brief
brought up to date. One owner builds. An agent is used only for bounded side-work and for the
fresh-context grading, never more than two at once.

```text
THE JOB
Build the game specified in SPEC.md, from the stage PROGRESS.md names. You are its
designer and its owner. Be ambitious: build the largest, most complete version the
specification describes, not the smallest thing that satisfies it. Where the
specification is silent, decide in line with its section 5, and record the decision and
its reason in DECISIONS.md.

THE WHY
This game is for Morgan, on the only console he owns. Its heart is his own work: music
as a coordinate system, the circle of fifths as a spiral that never closes, home as a
place you choose. A game that could have been made for anyone, on any machine, has
failed even if it runs.

THE RULES
- SPEC.md section 5 holds, all twelve.
- Hardware: docs/hardware-target.md. Build against the purple.
- Controls: SPEC.md section 8. Before calling a control done, name the digit that
  performs each of any two things done at once.
- This codebase is yours. Keep the rules in plain, tested code with no platform in it.
- Do not stop while work from the stage is still owed. Ordinary obstacles are yours to
  work through. A boundary in SPEC.md section 17 is to be left alone and reported.
- Never estimate how long anything will take, and never trim the stage to save effort.
- Every few tool calls, one line on where things stand.
- Commit and push each finished piece. Keep PROGRESS.md true.

DONE
The stage's proof in spec/stages.md, shown, not asserted: the command, the run, the
frames you looked at, the numbers, and what only Morgan can judge.
```
