# Promises of the whole game

_Part of the promise book (`../promises.md`). These hold everywhere, so each is proved again in
every land._

### `whole.scale` One to a hundred

- **Said:** `spec/world.md` "each as big as a country to Hum"
- **Stage:** 2
- **The moment:** You are the size of a seed. A blade of grass is a tree. A drop of water sits on
  your head like a hat. The hose is a tunnel you can walk through standing up, and it takes a
  quarter of an hour to walk. A pill bug is as big as you are. Nothing was scaled to look good:
  every thing is its real size, times a hundred, and you can check any of it against the real garden
  with a ruler.
- **Far:** masts, towers and one brass monument on the skyline, each of them something you could
  hold in your hand.
- **At its foot:** every thing has a part your own size: a hair on a stem, a grain of soil, a thread
  on the spigot.
- **Inside:** what is small in the real garden is a place: the bore of the hose, the cup of a
  flower, the hollow of a pot.
- **After:** you look at a real garden differently.
- **A cheat would be:** sizes chosen by what was easy to draw; a "country" you can run across in a
  minute; giant things that are plain copies of small ones, with no part at Hum's size.
- **Full size:**
  - `fact scale.one_to == 100` One number for the whole world. Hum stands one metre, which is one
    centimetre of the real garden.
  - `fact asters.tallest_m >= 150` The first thing built at this scale, and the tallest.
  - `owed` Every thing in a land's score gives its real size, and the score tool multiplies. Nothing
    in a score is sized by eye.
  - `owed` A run straight across any land takes at least five minutes (`size.md`).
- **Asks:** Standing in it, did you feel the size of a seed?

### `whole.true` Literally true

- **Said:** `SPEC.md` "One model of frequencies, phases and ratios drives the sound, the picture and
  the physics."
- **Stage:** 1
- **The moment:** You never catch the game faking. What you see ring is what you hear ring, as loud
  as it is bright, for as long. What pulls a thing toward you is the same number that makes it sound
  sweet with you. When you try something nobody would have thought to allow, it does what sound
  would do.
- **A cheat would be:** an animation that plays beside a sound; a list of which things answer which
  notes; a puzzle that only accepts the answer its maker thought of.
- **Full size:**
  - `test what lights a thing by ringing is what sounds it` One number per thing is both its light
    and its loudness.
  - `test a thing answers by its own overtones, whatever its family` No list of who answers whom.
  - `owed` A check over the source: no table in the rules that a law in `laws.md` could produce.
  - `owed` In every land, the scripted player solves one thing a way its score never names.
- **Asks:** Did anything ever look like one thing and sound like another?

### `whole.law1` Sympathy

- **Said:** `SPEC.md` "sound flows between things that share overtones"
- **Stage:** 1
- **The moment:** You ring one thing and others light up across the land that you never touched,
  each in its own colour, each as much as it shares with what you rang. You learn who is kin to whom
  by watching what answers. Later you use it: you can only move what your voice shares something
  with.
- **A cheat would be:** every thing of one kind lighting together; answers that don't depend on the
  note.
- **Full size:**
  - `test kin answer a call and strangers don't`
  - `test a thing answers by its own overtones, whatever its family`
  - `take` The scripted player calls and is answered.
  - `test a rung bell rings its kin, and they ring theirs, more faintly each time (law 1)` It flows
    between things, not only from Hum: each thing keeps its nearest strong kin, and a thing that
    rings rings them when its sound reaches them, more faintly by how much they share and how far it
    came; a thing just rung rests, so two kin never ring each other back and forth. A call's
    answers pass it on, and so does the bee's chime at a crown. In the Garden's proof field it adds
    little (twenty rings in the evening), since its bells are tuned to the home chord and nearly
    all answer the call themselves.
  - `owed` A puddle a ringing bell shares an overtone with stands for a moment in that shape, as it
    does for a call.
- **Asks:** When you rang one thing and others answered, could you tell why those?

### `whole.law2` Gravity

- **Said:** `SPEC.md` "an overtone falls toward the note that contains it"
- **Stage:** 2
- **The moment:** You put home under a seed's note and the seed comes to you across the ground. You
  put home over it and you are the one who is drawn. Nothing in the world is pushed by a button:
  things fall along the same lines that make a chord want to resolve.
- **A cheat would be:** a tractor beam with a musical skin: things that come when a button is held,
  whatever home is.
- **Full size:**
  - `owed` The pull on any thing is worked out from where home is and from that thing's own
    overtones, by the table in `laws.md`, for things no score lists.
  - `owed` Its truth as a sum: a fifth above falls to home; across the wheel is pushed away.
- **Asks:** Did moving home feel like tilting the ground?

### `whole.law3` Falling into step

- **Said:** `SPEC.md` "things at nearly the same rate pull each other together"
- **Stage:** 2
- **The moment:** You walk steadily and the pill bugs fall in behind you, one by one, until you are
  leading a parade. Two pendulums hung from one stem drift into time with each other while you
  watch.
- **A cheat would be:** followers that snap to a formation; clocks that are simply set equal.
- **Full size:**
  - `owed` Any two pendulums near enough in rate and joined by anything that carries a push close
    their gap at the rate `laws.md` gives. A test over made-up pairs.
  - `owed` A crowd of forty takes longer to fall in than a crowd of four, and you can watch it
    happen.
- **Asks:** Did the parade feel like something you earned by keeping steady?

### `whole.law4` Standing waves

- **Said:** `SPEC.md` "a driven thing shows still lines and bellies"
- **Stage:** 2
- **The moment:** You hum a pool's note and lines appear on the water where it isn't moving. You
  walk out on them. A different note draws a different bridge. Between the lines the water throws
  whatever lands on it.
- **A cheat would be:** a few stored patterns faded in; lines you can walk whatever note you hold;
  the same figure on every pool.
- **Full size:**
  - `owed` The figure on a round skin at each of its notes is the one the mathematics gives: rings
    and spokes in the right numbers. A test.
  - `owed` A pool of any outline in a score has its own figures, worked out from its outline by
    `game/tools/modes`.
  - `owed` The scripted player crosses a pool by its still lines, and falls in when it holds the
    wrong note.
- **Asks:** When the lines came up on the water, did you trust them enough to step out?

### `whole.law5` Cancelling and beating

- **Said:** `SPEC.md` "opposite sounds make silence, which is dark; near-misses beat, and the
  beating turns things"
- **Stage:** 2
- **The moment:** You sing a sound's mirror and it goes quiet, and where it was the world goes dark:
  you have made a place to hide. Two notes a hair apart swell and fade, and the figure between them
  turns, and that turning drives a wheel.
- **A cheat would be:** a stealth button; a wheel on a timer.
- **Full size:**
  - `owed` Silence is where the sums cancel, worked out from where the two sources stand, so it has
    a shape you can walk the edge of.
  - `owed` Two tones a known distance apart beat at the rate in `laws.md`, to within a hundredth of
    a beat a second, measured from the sound itself by `game/tools/ears`.
  - `owed` A wheel driven by a tempered pair turns once a beat; make the pair pure and it stops.
- **Asks:** Could you hear the beating that the wheel was turning to?

### `whole.law6` Travel

- **Said:** `SPEC.md` "sound moves at a speed you can see"
- **Stage:** 1
- **The moment:** You call and watch your call go: a ring of light running out over the ground at
  the speed of a fast bird. You see the far thing light when the ring reaches it, and you hear it
  later, by exactly as long as its sound takes to come back. Far is late. Tall is late too: a call
  climbs.
- **A cheat would be:** an echo effect with a fixed delay; light and sound arriving together from
  everywhere.
- **Full size:**
  - `fact sound.speed_m_s == 60` Ten times Hum's run.
  - `test an answer is heard when it has travelled there and back`
  - `test a call climbs a tower, and its bells are heard late by their height`
  - `take` The scripted player hears an answer after its travel time.
  - `owed` Walls give a phrase back. A thing that moves is heard bent. A note can be ridden.
- **Asks:** Could you tell how far away something was by how late it answered?

### `whole.law7` Building up

- **Said:** `SPEC.md` "push a thing at its own rate and it grows"
- **Stage:** 2
- **The moment:** You push an aster as tall as a cathedral, once, and nothing happens. You push
  again as it comes back. Again. By the sixth push the whole tower is swinging and its bells begin
  to ring by themselves. You did that with a voice the size of a seed, by being on time.
- **A cheat would be:** a meter that fills when a button is mashed; a swing that grows whatever the
  timing.
- **Full size:**
  - `owed` A push in time with a thing's own rate adds; a push against it takes away. A test: six
    pushes on the beat swing it further than sixty off it.
  - `owed` The scripted player rings the tallest aster by swinging it, and cannot by pushing at
    random.
- **Asks:** Did swinging something that big feel like timing, not strength?

### `whole.twice` Every cue twice

- **Said:** `SPEC.md` "the game can be played by ear alone or by eye alone" "A cue with only one of
  them does not compile." "A thing the player must notice is declared once, with its sound and its
  light together."
- **Stage:** 1
- **The moment:** You shut your eyes and can still play: you know where the answer came from, when
  the beat is, that something leans. You turn the sound off on a bus and can still play: everything
  you needed to hear is also light. And nothing ever makes a sound you can't see, or shows a light
  with no sound behind it: a far bell lights the moment your call reaches it and is heard exactly as
  late as it is far, every time, because the game has only one way of saying anything.
- **A cheat would be:** a caption for the sound and a beep for the picture, added afterwards for a
  few big moments; a sound effect played from one place in the code and its animation from another,
  kept in step by hand.
- **Full size:**
  - `test a cue can't be made with a sound and no light, or a light and no sound` The cue's type has
    two parts, a sound and a light, and neither has a default (`game/src/world/cue.zig`).
  - `test nothing sounds without its light: every sound in a scripted take was told as a cue`
    Thousands of steps of two scripted takes: every sound that reached the ears had been told with
    its light.
  - `test what lights a thing by ringing is what sounds it` One number rings a thing: it is heard as
    that number and seen as its square root.
  - `test an answer is heard when it has travelled there and back` The light is at the thing at
    once; the sound is late by the distance.
  - `fact cue.sounds_outside_tell == 0` One way out: nothing in the world's rules sends a sound on
    its way except `tell`, which takes a cue. The promise tool reads the source to count.
  - `owed` Two more scripted players: one given only what the sound says, one given only what the
    picture says. Each finishes the stage.
  - `owed` Every kind of sound the game grows goes the same way: strings, pipes, the lives' voices,
    strikes in a fight, the river's song. Each kind of light is drawn: now the glow and its halo,
    the ring on the ground, and the singer's swell.
  - `owed` Measured on the handheld from outside, with a phone filming: the light and the sound of
    one cue at no distance are within a twentieth of a second of each other.
- **Asks:** Play ten minutes with the sound off, then ten with your eyes shut. Could you?

### `whole.same` A take is its inputs

- **Said:** `SPEC.md` "The same hands make the same world and the same sound on every machine."
- **Stage:** 1
- **The moment:** A song you played a year ago plays again exactly, on your handheld, on your
  friend's, on a laptop, in a web page. Nothing you did is ever lost, because all the game keeps of
  it is your hands.
- **A cheat would be:** a recording of the sound; a replay that drifts.
- **Full size:**
  - `test the same hands make the same world`
  - `test the same cues make the same samples`
  - `fact same_take.identical == 1` The scripted takes give the same fingerprints on the laptop and
    on the purple.
  - `fact take.replays_same == 1` Takes are written and replayed.
  - `fact save.middle_same_end == 1` A save loaded in the middle reaches the same end.
- **Asks:** nobody: two machines answer it, and a person can't.

### `whole.alone` Whole alone, more together

- **Said:** `SPEC.md` "Together adds; it never takes."
- **Stage:** 6
- **The moment:** You finish the game by yourself and never meet a door that wanted a friend. Then a
  friend sits beside you with the other console, and the same world has a third note in it that was
  never there before.
- **A cheat would be:** content locked to two players; a second player who is only a helper.
- **Full size:**
  - `owed` The scripted player reaches every promise with no second console.
  - `owed` Every promise in `design/together.md`, sized at stage 6.
- **Asks:** Alone, did it ever feel like half a game?

### `whole.endless` The mornings never repeat

- **Said:** `SPEC.md` "the mornings never repeat"
- **Stage:** 5
- **The moment:** A year after the thirteenth morning you wake somewhere nobody has ever stood, in a
  key with a name nobody uses, and it is as carefully true as the first garden was.
- **A cheat would be:** the same twelve lands in new colours; random terrain with a tuning label.
- **Full size:**
  - `owed` A land made from its three numbers has its own material, metre, tuning and great shape,
    by rules, and no two of the first ten thousand are the same.
  - `owed` The same three numbers make the same land on every machine.
  - `owed` Each made land keeps every promise under "What every land owes".
- **Asks:** Past the lake, did a made land ever feel like filler?

### `whole.lights` Every land's lights across the water

- **Said:** `spec/world.md` "From any shore you see every land's lights across the water and hear
  the far ones late."
- **Stage:** 3
- **The moment:** You stand on the garden's shore at 2am. Round the whole lake there are lights,
  each in its land's colour, and you know every one. Something rings on the far side: you see it now
  and hear it a minute later, softer and lower.
- **A cheat would be:** a painted horizon; far sounds that arrive at once; lands that appear when
  you get close.
- **Full size:**
  - `owed` From every piece of every shore, lights of all eleven other lands are in the frame. The
    score tool counts them.
  - `owed` A thing rung on the far shore is heard after its distance at 60 m a second: about a
    minute straight across (`size.md`).
  - `owed` What is lit over there is what is truly sounding over there now, worked out from the
    morning's number.
- **Asks:** Looking across the water, did you want to go to one of those lights?

### `whole.good` It sounds good

- **Said:** `SPEC.md` "Consonant and beautiful by default."
- **Stage:** 2
- **The moment:** You leave it playing while you make tea, because the room is nicer with it on.
- **A cheat would be:** correct and unpleasant: true tunings rendered as thin beeps; roughness left
  sitting.
- **Full size:**
  - `fact ears.rough_longest_s <= 3` `game/tools/ears` on the whole first evening: nothing rough
    for two seconds together.
  - `fact ears.speaker_share >= 0.5` Nothing lost on a small speaker: most of the sound where it
    speaks.
  - `owed` Every sound has a yes in the room. The 31 clips in `design/listen/` are waiting there
    now.
- **Asks:** Would you leave it playing in the room?

### `whole.hands` Nothing asks the hands for the impossible

- **Said:** `SPEC.md` "Nothing ever needs the right stick and a face button at once."
- **Stage:** 2
- **The moment:** You never think about the controls. Whatever two things you want to do at once,
  there is a finger for each.
- **A cheat would be:** an audit done once on paper while the game quietly grows a combination that
  breaks it.
- **Full size:**
  - `owed` A test over the control table: for every pair of things that can be done together, a
    different digit does each.
  - `owed` The scripted player is given human limits: it may not use the right stick and a face
    button in the same step.
- **Asks:** Did your hands ever have to do something they couldn't?

### `whole.ear` The ear, before and after

- **Said:** `SPEC.md` "what a person can hear on the last morning that they could not on the first"
- **Stage:** 2
- **The moment:** Before the first evening the room plays you two fifths and asks which one is
  still. You guess. A hundred hours later it asks again and you don't guess: one of them is plainly
  turning and the other is plainly home. Nobody taught you. You walked there.
- **A cheat would be:** a quiz about music theory; a score that only measures time played.
- **Full size:**
  - `owed` Each person's first number, taken before their first evening. The check is in the room
    now, straight after it asks who is holding the handheld: a pure fifth against a wide one, the
    difference shrinking until it can't be told. Nobody has taken it yet.
  - `owed` The other two pairs: a still pair from a beating one on a third, and home from a comma
    sharp.
  - `owed` The same check after the thirteenth morning, and both numbers kept in the book.
- **Asks:** nobody: the two numbers answer it.
