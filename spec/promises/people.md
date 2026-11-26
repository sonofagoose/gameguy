# Promises of the people

> **Status, 2026-11-26.** History: part of the promise book, retired as a frame on 2026-11-25
> (Morgan: other models "treated the experiments as settled commitments and built process machinery
> on top of them"). The build still runs `spec/tools/promises.py --zig` to write the list the game's
> witness code reads; nothing else uses it. Don't extend it. What the game is: `design/the-game.md`.

_Part of the promise book (`../promises.md`). What `../../SPEC.md` section 11 says, sized before the
stage that builds the Garden's eight. `../people.md` and `../years.md` hold their tunes, rounds and
wants; Morgan's own layer (the vine, the pool's edge, the chair) is never filled in._

### `people.rounds` Each life keeps its own time

- **Said:** `SPEC.md` "Each has a tune, a round and a want. The round is where it is on which
  morning: a cycle of 3, 4, 5 or 7 mornings, and two that take 13 and 17." "The want is an ending
  its tune can't reach." "Each land has eight, and a reason they sing together: the table in 6.3."
  "Lives are sums. Where a life is, and what it is singing, is worked out from the morning's
  number."
  "An almanac page in the songbook shows any morning to come."
- **Stage:** 2
- **The moment:** Someone on the porch hums half a tune every third evening and stops in the same
  place. You learn to be there on the third evening.
- **A cheat would be:** a quest marker; a life that waits for you to come.
- **Full size:**
  - `owed` A test: where a life is and what it sings on any morning is a sum from the morning's
    number and its round, with nothing stored; the almanac shows the same sum for mornings to come.
  - `owed` The Garden's eight, each with its tune, its round and its want, written in the Garden's
    score (`people.md`).
- **Asks:** Did you learn when someone would be there?

### `people.helping` Helping is the day's five steps

- **Said:** `SPEC.md` "Helping is the day's five steps. Notice who is there today." "Lean in while
  they sing, and keep the phrase." "Find what it is missing: the other half is somewhere else or
  some other morning, in another life, a place, a wonder or one of your own echoes." "At dusk, when
  the land gathers, sing with them and land the cadence their tune needed." "What it changes. Their
  part joins the land's dusk song for good, they lend you a small voice, and the river sings them
  in your night." "A land with all eight sings its whole song." "On the thirteenth morning every
  round lines up and all twelve songs are one."
- **Stage:** 2
- **The moment:** You heard Snail's half-tune at noon and the other half in a pool by the shed. At
  dusk you sing them together, land the cadence it was missing, and from then on Snail's part is in
  the Garden's dusk song every night.
- **A cheat would be:** a fetch quest with a song as the item.
- **Full size:**
  - `owed` A test: the scripted player notices, keeps, finds, sings and lands the cadence for all
    eight of the Garden's lives, and each one's part joins the dusk song.
  - `owed` Each life helped lends a small voice (`voices.five`); the river sings it in the night
    (`loop.river`).
- **Asks:** Did helping someone feel like it changed something?

### `people.sung` Nobody is explained

- **Said:** `SPEC.md` "Nobody is explained. Every line is sung, in the speaker's vowel, with one
  line
  of caption at most." "The seven moods are your seven answers."
- **Stage:** 2
- **The moment:** Box Elder tells you something, sung in its ah; you answer in tenderness, and it
  understands.
- **A cheat would be:** dialogue boxes.
- **Full size:**
  - `fact hud.text_lines <= 1` One line of words in play, at most.
  - `owed` A test: every life's line is a phrase in its own vowel; the hands answer only with a
    mood.
- **Asks:** Did you understand people without being told?

### `people.ties` Ties, duets and other lives

- **Said:** `SPEC.md` "Each is tied to others across the lake, and when two lives meet they sing a
  duet made from their two tunes." "Once you have helped a life you can live a morning as it: its
  body, its ears, its own speed of time." "Over years the lives change into things that keep their
  tunes, and new lives are born singing what was handed down."
- **Stage:** 2
- **The moment:** You live a morning as Snail: the garden's song is a blur of high notes, and the
  morning is over in two minutes.
- **A cheat would be:** a costume over Hum's own body and ears.
- **Full size:**
  - `owed` A test: a duet is made from two tunes by the rules for two voices (`years.md`).
  - `owed` A morning as Pill, as Snail, as Moss, as the Ants: three numbers each, a rate for time, a
    band for hearing and a kind of body (`years.md`, "Being them").
  - `owed` Lives changing over years, by rule (stage 5 and after).
- **Asks:** When you were someone else, did the garden sound different?

### `people.a-life` How a life works

- **Said:** `spec/people.md` "Everyone is made of something ordinary: a peg, a marble, a bottle cap,
  a
  screen door." "Nobody has a face. Nobody is explained." "A tune. Each life has a short tune of its
  own, sung in its own vowel, and a body that is the figure of its note against home." "A round.
  Where it is on which morning." "Most stay in one place." "Some go round three, four, five or seven
  places, one a morning; a few take twelve, thirteen or seventeen." "A round is a sum from the
  morning's number, so the almanac can show any morning to come." "A want. An ending its tune can't
  reach by itself." "Notice who is there today." "Capture: lean in while they sing, and keep the
  phrase." "Extract: on the page, a kept phrase shows what it is made of and where it stops short."
  "Select: find what it is missing." "It is always somewhere: another life, another morning, a
  place, a wonder, one of your own echoes." "Sing: at dusk, when the land gathers, sing with them
  and
  land the ending." "What it changes. Their part joins the land's dusk song for good." "They lend
  you
  a small voice: one colour of one of the five." "The river sings them in your night." "Each land's
  eight are its band: a ground, a pulse, a tune, a third, and four colours." "A land with all eight
  sings its whole song at dusk." "Twelve songs, ninety-six parts." "A life goes on past its first
  ending (years.md): two more wants, ties to other lives, duets when they meet, a morning you can
  live as it, and over years a change into something that keeps its tune." "Nothing here is a chore
  list. Nobody asks. A life sings what it sings, where it is, and the player who never helps anyone
  still reaches the thirteenth morning." "The lands are thinner for it, and the lake is lower."
- **Stage:** 2
- **The moment:** A clothes-peg on a line sings half a tune and stops; nobody asks you anything. You
  notice, you keep the phrase, you find its other half, and at dusk the peg's part is in the song.
- **A cheat would be:** a quest log; a life with a face and a speech bubble.
- **Full size:**
  - `fact hud.text_lines <= 1` Nobody is explained in words.
  - `owed` A test for each step of the day's five (`people.helping`): notice, capture, extract,
    select, sing, played by the scripted player for the Garden's eight.
  - `owed` Each life's body drawn as the figure of its note against home, from something ordinary,
    with no face.
  - `owed` A test: the player who helps nobody still reaches the thirteenth morning, with the lands
    thinner and the lake lower.
- **Asks:** Did you help someone because you wanted to, not because you were asked?

### `people.garden-eight` The Garden's eight

- **Said:** `spec/people.md` "Each table: who, what they are, their round, what their tune can't
  reach, what helps, and what they lend." "Pill | a pill bug that rolls up at any surprise | 3:
  Garden, Alfalfa, Porch | a march that loses a beat every time it curls | a steady pulse beside it
  for one whole phrase | a soft tick" "Snail | carries a spiral; a morning late for everything | 7:
  down the east shore and back | arriving while the song is still being sung | keep its phrase and
  sing it at the gathering ahead of it | a long slow line" "the Twins | two asters on one stem |
  stay
  | they sing one tune a beat apart and each thinks the other is late | the clap, on the one they
  share | a voice that answers a beat later" "Moss | a patch of moss | stays | being heard: it
  swallows its own voice | set the pot over it | the softest start to a note" "Sprinkler | a
  spinning
  sprinkler head | stays; goes round in five while the garden counts four | someone who counts with
  it | strike where five and four meet | a count of five" "the Ants | a file of ants, many as one |
  4: Garden, Bell Meadow, Aster Steps, Porch | a work song: they stumble on each other | lead them,
  by walking | a crowd's voice" "Peg | a sprung clothes-peg on a line, holding nothing | stays | the
  other half of its tune: its sock is under a seat in the Chrome Nave | carry the sock's half back |
  a snap on the off-beat" "Nozzle | the brass end of the hose | stays | the top line: it goes sharp
  when the sun warms it | plant something to shade it | the bright top"
- **Stage:** 2
- **The moment:** Sprinkler goes round in five while the Garden counts four; you strike where five
  and four meet, and it lends you a count of five.
- **A cheat would be:** eight lives with the same help and the same reward.
- **Full size:**
  - `owed` The Garden's eight in its score, each with its round, its want, what helps and what it
    lends, and a test that the scripted player helps each one by what helps it.
  - `owed` Each life's want reached by a law, not a list: Sprinkler by law 3 (five against four),
    Moss by law 1 (the pot), Nozzle by tuning (it goes sharp in the sun).
- **Asks:** Which of the eight did you love?

### `people.blank` Left blank on purpose

- **Said:** `spec/people.md` "Who the vine is." "Who sat on the pool's edge." "Who sat in the
  chair."
  "Where Jeanne has been." "What the fly wants."
- **Stage:** 2
- **The moment:** The vine sings, someone has sat on the pool's edge and in the chair, the fly wants
  something; the game never says.
- **A cheat would be:** a caption, or a line in the songbook, that fills them in.
- **Full size:**
  - `owed` A check over the scores and the songbook: none of the five is named or explained; Morgan
    reads what the game says of them and says it is still his (`rules.morgans-layer`).
- **Asks:** Is it still yours?
