# Promises of the first evening

_Part of the promise book (`../promises.md`). `SPEC.md` 6.1, beat by beat. These are the first
twenty minutes anyone has with the game, so each one is held to its largest reading._

### `evening.black` Black, and a drip

- **Said:** `SPEC.md` "Black, and a drip." "The backlight itself is down, so the black is black."
  "Low on the screen, a small bone-white shape in reeds, breathing."
- **Stage:** 2
- **Scene:** dark
- **The moment:** You start the game and think the handheld has switched itself off. It hasn't. The
  screen's own light is down to almost nothing, so black is the black of a dark room. Somewhere a
  drop falls, and falls again, not quite evenly. Low on the screen something small and bone-white is
  breathing in reeds. You lean toward it. Nothing tells you what to press.
- **A cheat would be:** a dark grey picture on a lit screen; a title card; a prompt.
- **Full size:**
  - `fact dark.first_backlight <= 20` The backlight's first level, out of 255. Measured: at 20 the
    handheld draws 195 mA, against 388 at full (`docs/hardware-target.md`).
  - `owed` The drip: one drop, uneven, from one place you can turn toward.
  - `owed` Hum breathing, low in the frame, with reeds beside it that you can only just see.
  - `owed` No text and no mark on the screen that isn't in the world.
- **Asks:** Did the screen look switched off until you called?

### `evening.call` You call, and you are answered

- **Said:** `SPEC.md` "You call (tap R1)." "A ring of light runs out over the ground and shows reeds
  and a coiled hose." "The second call is always answered"
- **Stage:** 2
- **Scene:** dark
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
  - `take` The scripted player calls, and an answer reaches it after its travel time.
  - `frame dark-ring` A ring on the ground with what it has passed still lit and what it hasn't
    reached still dark.
  - `fact handheld.dark.late == 0` On the handheld every frame of it is on time.
  - `owed` The second call's answer: Drip's own ring coming back in teal, and the ripple that shows
    which way.
  - `owed` Hum's own voice starts within one sound buffer of the button.
- **Asks:** When you called in the dark and something answered, did it feel like being answered?

### `evening.breathe` You breathe with it, and it locks

- **Said:** `SPEC.md` "You find it and breathe with it." "Stand still beside it and the view leans
  in." "Hold R2 to hum and let go on its tick." "Between you a flat figure turns: three lobes by
  two." "Four breaths together and the figure stops dead." "A third note sounds under you both that
  neither of you is singing."
- **Stage:** 2
- **The moment:** You stand beside the small thing that answered. The view leans in. It ticks, and
  you hold R2 and hum and let go on its tick, clumsily, then less clumsily. Between the two of you a
  figure of light is turning: three lobes one way, two the other. Each breath it turns slower. On
  the fourth it stops dead, and under both your notes a third one sounds, lower, that neither of you
  is singing. It is the first time in the game anything has held still.
- **A cheat would be:** a timing bar; a figure that plays a "success" animation; a third note that
  is just a sample played on cue.
- **Full size:**
  - `owed` The figure is drawn from the two voices themselves: its lobes are their ratio, its
    turning is how far apart they are.
  - `owed` The third note is the difference between them, there in the sound because of what the two
    are doing, and gone the moment one of them drifts.
  - `owed` The scripted player locks in four breaths; a scripted player with poor timing takes
    longer and still gets there.
  - `owed` The view leans in when you stand still beside it, as it leans back at an aster's foot
    now.
- **Asks:** When the figure stopped, did it feel like the two of you locking?

### `evening.in` "Oh. You're in."

- **Said:** `SPEC.md` "The drop falls on your head and stays." "Until now the world has been a page
  seen from above." "Now it tilts back and stands up around you" "The page and the place are one
  world on one hinge." "Hold the wheel and it lies down to be read."
- **Stage:** 2
- **Scene:** asters
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
  - `frame asters-page` The page: Hum a mark on it, an aster in plan as a ring of its own bells, the
    call's ring crossing.
  - `frame asters-rising` The hinge half open, with the one line of text, large, and no other text
    anywhere.
  - `frame asters-far` The place, standing: towers beyond open ground and Hum small before them.
  - `owed` What sets it off: the drop landing on Hum's head. In the proof the page stands by itself
    after two and a half seconds.
  - `owed` Something tall in the frame while it rises, so the rising is seen: the tops go out of the
    frame before they stop.
  - `owed` The line in the style book's own face and size, checked against `design/look.md`.
  - `owed` On the handheld: every frame of the rise on time.
- **Asks:** When the world stood up, did you say something out loud?

### `evening.instrument` Everything is an instrument

- **Said:** `SPEC.md` "Everything is an instrument." "whatever shares your note answers across the
  garden in its own light" "A still pool shows lines on its surface when you hum its note, and you
  can walk on them."
- **Stage:** 2
- **Scene:** asters
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
  - `frame asters-answer` Crowns lit in their own colours, the kin bright and the rest dark.
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
