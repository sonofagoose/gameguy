# Promises of the workshop

> **Status, 2026-11-26.** History: part of the promise book, retired as a frame on 2026-11-25
> (Morgan: other models "treated the experiments as settled commitments and built process machinery
> on top of them"). The build still runs `spec/tools/promises.py --zig` to write the list the game's
> witness code reads; nothing else uses it. Don't extend it. What the game is: `design/the-game.md`.

_Part of the promise book (`../promises.md`). What stage 1 owes a person, as opposed to what it owes
the build (`../stages.md`)._

### `hands.voice-in-a-buffer` Your voice, at once

- **Said:** `SPEC.md` "Your own voice answers within one sound buffer."
- **Stage:** 1
- **Scene:** evening
- **The moment:** You press R2 and Hum is already humming. There is no gap to learn, nothing to
  lead. It is as immediate as humming yourself, so within a minute you stop thinking of the button
  and think of the note.
- **A cheat would be:** a voice that starts on the world's next step, a sixtieth of a second or more
  late, with a soft attack to hide it.
- **Full size:**
  - `test Hum's own call starts on the sample the hands were stamped with, and is not sounded twice`
    The sound thread reads R1 and R2 straight from the kernel before every buffer
    (`game/src/plat/presses.zig`) and starts Hum's call or hum on the buffer after the press; the
    world, a step later, tells the same sound on the stamped sample, and it is not sounded twice.
  - `test a take cut off while it was written is read as far as it got` Each change in a take keeps
    its stamp, so a replay starts the voice on the same sample every time.
  - `test the hands' clap sounds once and chokes the call begun just before it; a strike is never
    taken for a call`
    The clap too: the sound thread reads L1 with R1 and R2, finds the clap from the kernel's
    stamps, and starts it on the buffer after the second press; a call begun just before is
    choked, so the gesture is one sound. A strike, the pocket and the swell's step are Hum's own but
    only the world starts them, and they are never taken for a call.
  - `test a strike the hands timed sounds once, with its octave` The face buttons are read from
    the kernel with the shoulders, and a strike pressed well inside the beat's window starts on the
    buffer after the press, by the world's own sum of where the beat is.
  - `fact handheld.hands.most_ms <= 3` From the kernel seeing a press to the buffer that starts
    Hum's sound, the most of any press in a session on the handheld, from its log.
  - `owed` A let-go is heard at the world's next step, up to a sixtieth of a second late, because
    the world decides whether it ends the hum or locks the breath: the sound thread is to be told
    the lock's windows, so a let-go is heard at once too.
  - `owed` Button to sound, measured from outside with Morgan's phone filming the handheld, or with
    a headset if the jack records.
- **Asks:** When you hum, does it start the moment you press?

### `card.takes` The card is the world's memory

- **Said:** `SPEC.md` "Every take is kept, a save is made every dawn" "A take is its inputs."
- **Stage:** 1
- **The moment:** The battery dies in the middle of an evening. You charge it, start the game, and
  you are standing where you were, with everything you had done still done. Months later you pick
  any day out of the book and it plays again from your hands, note for note, on your handheld or
  anyone's.
- **A cheat would be:** one save file that is overwritten; a recording of the sound in place of the
  take.
- **Full size:**
  - `test a take written down and played back makes the same world, step for step` Ten bytes for
    each change of the hands, and nothing else.
  - `test a file that is not a take is refused`
  - `fact take.replays_same == 1` The walk to the great aster, written down and played back from its
    bytes: the same world and the same sound.
  - `fact take.file_replays_same == 1` The same take as a file, played back through the game itself:
    the promise's moment happens on the same step.
  - `fact take.bytes <= 65536` The whole scripted evening, nine minutes from the dark to wonder's
    puddle, is this small: twelve bytes for each change of the hands.
  - `fact take.kills_survived >= 100` Killed at a random moment a hundred times while it plays the
    first evening (`game/tools/kill_test.sh`), it goes on from where it was every time: the same
    world as the take played through from its first step, from the take's last dawn when it had
    one. The take is written as it is played, by a thread of its own that drains it to the card
    twenty times a second and makes the card hold it once a second; a dawn's save is written by the
    same thread after the hands that led to it.
  - `fact take.kill_most_lost_steps <= 299` Never more than five seconds of the evening lost.
  - `owed` On the handheld, a flat battery rather than a kill: the card holds the take once a
    second, but nobody has pulled the battery yet.
  - `test a save made in the middle of the evening and loaded again reaches the same end` The whole
    world is its bytes, with a print of its layout, so a build that has changed it refuses the save
    rather than misreading it.
  - `test a dawn's save is kept and opened again a hundred dawns later` And a damaged save is
    refused and changes nothing.
  - `fact save.middle_same_end == 1` The world kept at minute three of the walk, opened again and
    played on by the same hands: the same end, in the take tool.
  - `fact save.file_opens_same == 1` The same save as a file, opened by the game itself and played
    on by the take: the puddle is crossed on the same step.
  - `owed` After leaving on purpose the next start begins the evening again; choosing between going
    on and beginning again waits for the songbook.
  - `owed` A person's take played back on the handheld gives the same fingerprints as on the laptop.
  - `owed` Measured on the handheld: writing the take never makes a frame late or a gap in the
    sound.
- **Asks:** nobody: a pulled battery answers it.

### `light.hue` One set of numbers for sound and light

- **Said:** `SPEC.md` "Pitch class is hue, by fifths."
- **Stage:** 1
- **Scene:** asters
- **The moment:** After an hour you can read the garden's notes by eye. Green is home. Things a
  fifth up are a step warmer, a fifth down a step cooler, and what clashes with home is the colour
  straight across from it. Brightness is loudness, so a quiet thing is dim and silence is black. You
  never learned a legend; it was simply always true.
- **A cheat would be:** colours chosen by an artist; brightness animated by hand.
- **Full size:**
  - `test a note's colour goes round the wheel by fifths`
  - `test what lights a thing by ringing is what sounds it`
  - `frame evening-answer` Kin of home lit in home's colour and its neighbours'; nothing lit that
    isn't sounding.
  - `owed` Octave is height and timbre is the texture of a line, in the renderer, for every family.
- **Asks:** Could you tell which bells were kin to your note by their colour?

### `light.beam` The beam

- **Said:** `SPEC.md` "A figure is brightest where its beam slows to turn."
- **Stage:** 1
- **The moment:** Everything looks drawn by one moving point of light, the way an oscilloscope
  draws. Where the point turns, the line is brightest. What has just sounded leaves a glow that
  fades over a breath, so you can see what happened a moment ago as well as what is happening.
- **A cheat would be:** plain lines with a blur over the top.
- **Full size:**
  - `frame dark-ring` The ring's afterglow behind it, and none in front.
  - `owed` Brightness along a line follows the beam's speed, for every figure the wheel and the
    voices draw.
  - `owed` The afterglow doesn't smear when the view turns: what glows is the thing, not the screen.
- **Asks:** Did it look drawn by light, or like lines on a screen?
