# Promises of the first evening

_Part of the promise book (`../promises.md`). `SPEC.md` 6.1, beat by beat. These are the first
twenty minutes anyone has with the game, so each one is held to its largest reading._

### `evening.black` Black, and a drip

- **Said:** `SPEC.md` "Black, and a drip." "The backlight itself is down, so the black is black."
  "Low on the screen, a small bone-white shape in reeds, breathing."
- **Stage:** 2
- **Scene:** evening
- **The moment:** You start the game and think the handheld has switched itself off. It hasn't. The
  screen's own light is down to almost nothing, so black is the black of a dark room. Somewhere a
  drop falls, and falls again, not quite evenly. Low on the screen something small and bone-white is
  breathing in reeds. You lean toward it. Nothing tells you what to press.
- **A cheat would be:** a dark grey picture on a lit screen; a title card; a prompt.
- **Full size:**
  - `fact dark.first_backlight <= 20` The backlight's first level, out of 255. Measured: at 20 the
    handheld draws 195 mA, against 388 at full (`docs/hardware-target.md`).
  - `frame evening-black` Nothing on the screen but Hum, small and bone-white. No text, no mark that
    isn't in the world.
  - `test the second call is answered by the drip, late by the distance there and back` The drip is
    out there from the first second: it ticks 72 times a minute, every other tick a little late, and
    each tick is one cue, a flash where it is and a plink that arrives late by how far off it is.
  - `owed` Hum breathing, low in the frame, with reeds beside it that you can only just see.
  - `owed` On the handheld, in a dark room: the screen looks switched off, and the drip can be heard
    and turned toward (Morgan's yes).
- **Asks:** Did the screen look switched off until you called?

### `evening.call` You call, and you are answered

- **Said:** `SPEC.md` "You call (tap R1)." "A ring of light runs out over the ground and shows reeds
  and a coiled hose." "The second call is always answered"
- **Stage:** 2
- **Scene:** evening
- **The moment:** You press R1 and a ring of light runs away from you over the ground. Where it
  passes, things stand up out of the dark for a moment: reeds, a coil of hose. The ring fades at its
  edge. You are alone. You call again, and this time, far off, something calls back: a ring in
  another colour coming toward you, and a ripple on the ground between you that points the way.
  Whatever is kin to your note has answered too, each late by its distance, so the dark is suddenly
  full of places.
- **Far:** the answer's ring, small and teal, where there was nothing.
- **At its foot:** the ripple on the ground, pointing.
- **After:** you call all the time, for the pleasure of it, and to see.
- **A cheat would be:** a flash that lights the whole screen at once; an answer that plays the
  moment you press; a marker that points at the goal.
- **Full size:**
  - `test an answer is heard when it has travelled there and back`
  - `test the second call is answered by the drip, late by the distance there and back` The first
    call is not answered. The second is, two seconds later: one second for the call to reach it and
    one for its own ring to come back.
  - `take` The scripted player calls twice, and the drip's ring reaches it.
  - `frame evening-page` The first call: a ring crossing the dark page, with what it has passed
    still lit behind it and nothing lit ahead of it.
  - `frame evening-drip` The second call's answer: a teal ring coming back from far off.
  - `fact handheld.evening.late == 0` On the handheld every frame of it is on time.
  - `owed` What the ring shows: reeds and a coiled hose, where now there are pebbles, crumbs and the
    plans of asters.
  - `owed` The ripple on the ground that shows which way is drawn for two seconds; whether it is
    enough to find the drip by is for a person to say.
  - `owed` Hum's own voice starts within one sound buffer of the button.
- **Asks:** When you called in the dark and something answered, did it feel like being answered?

### `evening.breathe` You breathe with it, and it locks

- **Said:** `SPEC.md` "You find it and breathe with it." "Stand still beside it and the view leans
  in." "Hold R2 to hum and let go on its tick." "Between you a flat figure turns: three lobes by
  two." "Four breaths together and the figure stops dead." "A third note sounds under you both that
  neither of you is singing."
- **Stage:** 2
- **Scene:** evening
- **The moment:** You stand beside the small thing that answered. The view leans in. It ticks, and
  you hold R2 and hum and let go on its tick, clumsily, then less clumsily. Its note is a fifth
  above yours and a hair flat, so the two of you beat, and between you a figure of light is turning:
  three lobes one way, two the other. Each breath together it comes a little truer, and the beating
  and the turning slow by the same amount, because they are the same thing. On the fourth it stops
  dead. Both your notes hold by themselves, and under them is a third one, lower, that neither of
  you is singing. It is the first time in the game anything has held still.
- **A cheat would be:** a timing bar; a figure that plays a "success" animation; a third note that
  is just a sample played on cue.
- **Full size:**
  - `test four breaths on the tick bring the drip's fifth true, and the figure stops` Its note
    starts four hundredths of a semitone flat and comes a quarter of the way home with each breath;
    the figure turns at the rate the two notes beat, which is nought when they are true.
  - `test two voices together make a third between them, and one alone makes none` The third note is
    in the sound's own chain: the difference of the two notes, there only while both sound.
  - `take` The scripted player finds the drip, breathes with it on its tick four times, and they
    lock.
  - `frame evening-figure` Hum and the drip on the page with the figure between them, turning.
  - `frame evening-locked` The same, still.
  - `fact evening.breaths_to_lock == 4`
  - `owed` A player with poor timing takes longer and still gets there, and nothing ever tells them
    they missed.
  - `owed` The third note measured from the sound by `game/tools/ears`: for C and the true G above
    it, C an octave down, and heard on the handheld's own speaker (Morgan's yes).
  - `owed` The view leaning in as it does for anyone you stand beside, not only here.
- **Asks:** When the figure stopped, did it feel like the two of you locking?

### `evening.in` "Oh. You're in."

- **Said:** `SPEC.md` "The drop falls on your head and stays." "Until now the world has been a page
  seen from above." "Now it tilts back and stands up around you" "The page and the place are one
  world on one hinge." "Hold the wheel and it lies down to be read."
- **Stage:** 2
- **Scene:** evening
- **The moment:** The drop falls on your head and stays. Until this second the world has been a page
  you looked down on: you were a small ring on it, an aster was a burst of coloured dots, a boulder
  was a pencilled outline. Now the page tilts back, and everything drawn on it stands up from
  exactly where it lay, and keeps standing up, past the top of the screen. The burst of dots was the
  crown of a tower, seen from above. There is a sky and the day is coming up in it. You are very
  small and you are in it. Hold R1 and it all lies down to be read again, and you know both are the
  same place.
- **Far:** on the page, every thing in the land at once, as its own plan.
- **At its foot:** the nearest stalk, thicker than you are tall, rising out of the mark that was its
  plan.
- **After:** whenever you hold the wheel the world lies down, and you read on it where you have
  been, in the light you left.
- **A cheat would be:** a cut to a 3D level; a fade; a map screen; a hinge that only the first
  screen uses.
- **Full size:**
  - `test the page stands up slowly enough to be watched, and lies down while R1 is held` More than
    three seconds to rise; under a second to lie down; back up when R1 is let go.
  - `frame evening-page` The page: Hum a mark on it, an aster in plan as a ring of its own bells,
    the
    call's ring crossing.
  - `frame evening-rising` The hinge half open: the nearest aster has already risen out of the top
    of
    the frame while the rest are still coming up, with the one line of text, large, and no other
    text anywhere.
  - `frame evening-far` The place, standing: towers beyond open ground and Hum small before them.
  - `test four breaths on the tick bring the drip's fifth true, and the figure stops` What sets it
    off: when the two have locked and their notes have held, the drop lands on Hum's head and the
    page begins to stand.
  - `owed` The line in the style book's own face and size, checked against `design/look.md`.
  - `owed` On the handheld: every frame of the rise on time.
- **Asks:** When the world stood up, did you say something out loud?

### `evening.instrument` Everything is an instrument

- **Said:** `SPEC.md` "Everything is an instrument." "whatever shares your note answers across the
  garden in its own light" "A still pool shows lines on its surface when you hum its note, and you
  can walk on them."
- **Stage:** 2
- **Scene:** evening
- **The moment:** You call again, to see what the standing world does with it. The ring runs out
  over the ground and up every stalk it meets. Whatever is kin to your note lights in its own colour
  and rings in its own voice, near things at once and far things late, so that one call becomes half
  a minute of bells arriving from further and further away. You realise nothing here is scenery.
- **A cheat would be:** a few special objects that react; one bell sound for everything; all of it
  at once.
- **Full size:**
  - `test a thing answers by its own overtones, whatever its family`
  - `test what lights a thing by ringing is what sounds it`
  - `fact asters.bells >= 800` How many separate bells the proof field holds, each with its own note
    and place.
  - `frame evening-answer` Crowns lit in their own colours, the kin bright and the rest dark.
  - `owed` Strings, pipes, bars, skins and bottles beside the bells, each answering by its own
    shape.
  - `owed` The pool that shows its lines when you hum its note.
- **Asks:** Did you start ringing things just to hear what they were?

### `evening.knot` The knot, and the first fight

- **Said:** `SPEC.md` "The hose is knotted, and the knot is moving." "Three small knots stumble at
  you." "Hold R1: time thickens, the place folds back to a page" "Point there and let go." "Now they
  dance in three and in five over a one that you are singing." "Strike on the one." "Dodge on the
  beat and time opens into a pocket." "A grey knot leans; hold R2 while the swell builds, and let go
  on the one." "It springs open." "The hose, unstopped, sounds an octave higher and brighter than it
  did." "For a second a blue figure sits on the pool's edge."
- **Stage:** 2
- **The moment:** Three small knots stumble at you, out of time with each other and with you. You
  hold R1: time thickens, the place lies down, and on the wheel their threads cross on one wedge.
  You point there and let go, and now they are dancing, in three and in five, over a one that you
  are singing. You strike on the one and it rings. You dodge on the beat and time opens. The grey
  knot leans; you hold the swell and let go on the one, and it springs open. Water runs. The whole
  hose, two and a half kilometres of it, sounds an octave higher.
- **A cheat would be:** enemies with health bars and a music track; a wheel that pauses the game for
  a menu; the hose's change as a swapped sound.
- **Full size:**
  - `owed` Every strike rings the knot at its own note, in key, and a strike you time yourself rings
    fuller than one the game placed.
  - `owed` The pocket: a dodge on the beat opens it, and the scripted player can't open it off the
    beat.
  - `owed` The hose's octave is the pipe's own sum: stopped, odd overtones only; opened, all of them
    and an octave up. A test.
  - `owed` Thumbs: the fight is played without the right stick and a face button together.
  - `owed` The blue figure on the pool's edge, for one second, with no face and no name. Who it is
    stays Morgan's.
- **Asks:** Did a strike you timed yourself feel like power?

### `evening.dusk` The river sings your day back

- **Said:** `SPEC.md` "The river carries you home and sings your day back in half a minute." "You
  keep a take." "A post carved in the world's old script offers a repeat sign or a bracket."
- **Stage:** 2
- **The moment:** The light goes. The river takes you, and as it carries you it sings: your own
  calls, your own strikes, the breath that locked, in the order you made them, folded into half a
  minute that is plainly a song and plainly yours. Nobody else's evening sounds like it. At the bank
  a post offers you two marks. You keep the take.
- **A cheat would be:** a jingle; a recap made of stock phrases; the same song for everyone.
- **Full size:**
  - `owed` The song is made only from the take's own hands, by a rule, so two different evenings
    give two different songs and the same evening gives the same one.
  - `owed` It lasts between 25 and 35 seconds whatever the evening held.
  - `owed` `game/tools/ears` finds nothing rough in a hundred of them made from scripted evenings.
  - `owed` The post, in the world's old script, with its two marks: a repeat sign and a bracket.
- **Asks:** Did the river's song sound like your evening?
