# Promises of Hum's hands

_Part of the promise book (`../promises.md`). What `../../SPEC.md` section 8 says about the
controls,
sized before the stage that builds them._

### `hands.by-position` Face buttons by where they are

- **Said:** `SPEC.md` "Face buttons are named by position."
- **Stage:** 2
- **The moment:** You never look down. The bottom button jumps and the right one dodges on the
  purple, on the black, on any handheld of this family, whatever letters are printed on them.
- **A cheat would be:** trusting a controller database's names for the buttons; prompts that name a
  letter the thumb has to find.
- **Full size:**
  - `test the face buttons are found by the kernel's codes, as the purple has them` Each face button
    is found by the kernel's code for its position (`game/src/plat/plat.zig`, `Faces`); PortMaster's
    mapping for the R36S names them after the printed letters, and once had every one a place off.
  - `owed` A check in the room: the holder presses the bottom, right, left and top buttons when
    asked, and the log says each was found where it is, on each handheld.
- **Asks:** Did any button ever do something other than what its place said?

### `hands.map` Every input does what the table says

- **Said:** `SPEC.md` "left stick, L3 | move; click to hush (stop humming, go dark)" "right stick,
  R3
  | look; steers a wheel while one is open; click to lean in" "bottom face | jump; in the air, open
  or close the glide" "right face | dodge (on the beat: the pocket); talks when nothing threatens |
  sprint" "left face | strike with the fork | charge; let go on the beat" "top face | grab, talk,
  plant | carry; leaning in, keep a phrase" "L1 | last voice | the voice wheel, on the left stick"
  "R1 | call: a ring of light | the mood wheel, on the right stick; the place folds to the page" "L1
  and R1 | the clap | both wheels at once" "L2 | lock on, next target (it latches) | guard" "R2 | a
  short phrase | sing: the swell. A nudge of the right stick on a downbeat walks home one wedge; a
  half push leans the note" "D-pad down | sit and listen; seated, the pad is an instrument" "D-pad
  up | gather your echoes" "D-pad left | again: your last bar keeps playing beside you" "D-pad right
  | play a kept song" "Select, Start | the songbook; pause"
- **Stage:** 2
- **The moment:** By the end of the first evening your hands know the handheld: call, hum, walk,
  look. By the end of the Garden they know all of it, and nothing on the pad is a menu.
- **A cheat would be:** a button that opens a list of things to do.
- **Full size:**
  - `owed` A test for each row as it is built: the scripted player presses it and the world does
    what the row says, and nothing else. The call and the hum are built (`whole.law1`,
    `evening.breathe`), and the rows below; the rest come with the stage.
  - `test a knot lunges to arrive on its one; a dodge on that beat opens the pocket, and a lunge not
    dodged knocks Hum back`
    Right face: dodge, and on the beat the pocket.
  - `test a strike timed within an eighth of a beat lands at once with its octave; off the beat the
    game places it on the next beat, plain`
    Left face: strike with the fork, timed by you or placed by the game.
  - `test the clap: L1 and R1 within a tenth of a second, whichever first, each press once` L1 and
    R1: the clap, found where the presses are stamped.
  - `test a clap takes back a call begun just before it, and leaves a call made long before` A clap
    is a clap and not a call as well.
  - `owed` A tap and a hold on the same button are told apart by how long it is held, a third of a
    second, the same for every button.
- **Asks:** Was there ever a moment you didn't know which button to press?

### `hands.thumbs` The thumb audit

- **Said:** `SPEC.md` "Thumb audit. Moving and singing: left thumb, right index on R2, right thumb
  on
  the wheel." "Moving and fighting: left thumb, right thumb on the face buttons, lock-on latched so
  the camera needs no thumb, left index free to guard." "Wheels: an index finger holds, a thumb
  steers." "The clap: both index fingers." "Gliding: a tap opens it and a tap closes it." "Leaning
  in also happens by stopping: stand still facing a voice for one bar."
- **Stage:** 2
- **The moment:** In the middle of a fight you are walking, singing and turning home all at once,
  and
  your hands are never in each other's way.
- **A cheat would be:** a second action put on a thumb already busy, and a slower way to do it
  offered instead.
- **Full size:**
  - `owed` A check over the input table: every pair of things done together names its digits, and
    no digit is named twice (`CLAUDE.md`: "Nothing may need the right stick and a face button at
    once").
  - `owed` A test: the glide opens on one tap of the bottom face in the air and closes on the next.
  - `owed` A test: standing still facing a voice for one bar leans in, with no button.
- **Asks:** Did your hands ever have to do two things with one finger?

### `hands.no-fn` FN is never needed

- **Said:** `SPEC.md` "FN is never needed. Not every firmware delivers it."
- **Stage:** 2
- **The moment:** On a firmware that eats the FN key, nothing is missing.
- **A cheat would be:** a feature reachable only through FN.
- **Full size:**
  - `fact hands.fn_reads == 0` Nothing in the game reads the FN key (SDL's guide button): a check
    over the source.
- **Asks:** nobody: the source answers it.
