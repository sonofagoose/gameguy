# Promises of the card

> **Status, 2026-11-26.** History: part of the promise book, retired as a frame on 2026-11-25
> (Morgan: other models "treated the experiments as settled commitments and built process machinery
> on top of them"). The build still runs `spec/tools/promises.py --zig` to write the list the game's
> witness code reads; nothing else uses it. Don't extend it. What the game is: `design/the-game.md`.

_Part of the promise book (`../promises.md`). What `../size.md` says the card's room is for, sized
before the stages that fill it. Takes and saves are in `workshop.md`; the loop and the book in
`loop.md`._

### `card.light` Why nothing on the card was a picture

- **Said:** `spec/size.md` "Why nothing on the card was a picture. Two decisions made the game
  light."
  "Its look is lines of light on black, and a line is two points and a colour: thirty thousand of
  them, a whole view, are one megabyte." "Its sound is made from resonators as it plays, so nothing
  is recorded." "A game built that way has nothing to paint and nothing to tape, and the whole of it
  fits in a few gigabytes however large its world is." "That lightness is room, and the room is
  spent. Not on padding: on the two things a light game can afford that a heavy one can't."
- **Stage:** 2
- **The moment:** The game's program and its sounds would fit on a floppy disk's worth of a card;
  everything else on the card is your world, kept.
- **A cheat would be:** filling the card with padding to look big.
- **Full size:**
  - `owed` Measured as the build makes it: the program, the scores and the sounds as data under 0.1
    GB; a whole view's lines about a megabyte.
- **Asks:** nobody: the sizes answer it.

### `card.no-copies` Nothing is a copy

- **Said:** `spec/size.md` "No thing in the world is an instance of a model." "Every aster, every
  leaf, every blade of grass and crumb of soil is its own shape, made once by the score's rules and
  kept on the card, and it stays as it is left." "The blade you bent on the first evening is still
  bent seven years later." "A path you walk every morning wears into the grass." "A leaf that was
  struck too hard hangs lower for good."
- **Stage:** 2
- **The moment:** Seven years in, the blade you bent on the first evening is still bent, and the
  path
  you walk every morning has worn into the lawn.
- **A cheat would be:** one blade of grass drawn ten thousand times; changes that reset.
- **Full size:**
  - `owed` Every thing its own shape, made once by the score's rules, kept on the card and loaded
    as Hum walks (`spec/stages.md`, stage 1).
  - `owed` A test: a blade bent, a path worn and a leaf struck too hard stay as they were left,
    across a save, a hundred dawns on.
- **Asks:** Did the world keep your marks?

### `card.kept` Nothing is forgotten

- **Said:** `spec/size.md` "Every dawn is kept. The save made each dawn is never thrown away." "Any
  morning of your life in the game can be opened from the book and walked again as it was, with your
  own past self walking it beside you, because a take is its inputs." "Someone you met in the first
  week and who has since changed (years.md) is still there on the morning you met them." "Your book
  is kept as sound and as paper. Each day's river song is written to the card as sound, with its
  separate voices beside it, and its page at print size." "Put the card in a computer and it is an
  album and a book with a song and a page for every day you played." "Your friends' worlds are kept.
  After a visit (together.md) each card holds the other's world as it stood that day." "You can walk
  in it when they are not there." "Every place has its own true echo."
- **Stage:** 2
- **The moment:** You open the book at the morning you met Drip and walk it again, with your own
  past
  self walking beside you.
- **A cheat would be:** a recorded video of the morning.
- **Full size:**
  - `test a dawn's save is kept and opened again a hundred dawns later` Every dawn is kept, and
    opens.
  - `fact save.middle_same_end == 1` A morning opened again plays out as it did, from its take.
  - `owed` A morning walked again with your past self beside you: the day's take played by a second
    Hum (`loop.echoes`).
  - `owed` Each day's river song written to the card as sound with its voices, and its page; the
    card an album and a book in a computer (`loop.book`).
  - `owed` Friends' worlds kept after a visit (stage 6); each place's true echo (`picture.physics`).
- **Asks:** Did it feel like the game remembered everything?

### `card.years` A card is a number of years

- **Said:** `spec/size.md` "All estimates, to be measured as stage 1 and stage 2 build each part."
  "the program, the scores, the sounds as data | under 0.1 GB" "every thing's own shape, at every
  distance it is seen from: about 12,600 pieces of world | 4 GB" "the ground's old light: a 256 by
  256 picture for each piece, 25 cm to a dot | 3 GB" "the echoes | 2.5 GB" "as it arrives | about 10
  GB" "each day played: the take, what the dawn keeps of the world's changes, the song as sound with
  its voices, the page | 25 to 45 MB" "each friend's world | 1 to 4 GB" "32 GB (the two units have
  these now) | 420 to 760 days | one to two years" "64 GB | 1,100 to 1,960 days | three to five
  years" "A card is a number of years. When one fills, the oldest dawns are thinned to their takes
  alone, a few hundred kilobytes each, from which any of them can be made again." "Nothing is ever
  lost; the oldest mornings just take a while to open." "The same world on every card. What the
  rules read is the same on a 32 GB card and a 64 GB one." "Two consoles with different cards make
  the same take."
- **Stage:** 2
- **The moment:** Years in, the card is nearly full; the oldest mornings open a little slower, and
  every one of them is still there.
- **A cheat would be:** deleting old days to make room.
- **Full size:**
  - `fact save.bytes <= 1000000` A dawn's save, measured: 366,776 bytes, well inside the estimate of
    what a day keeps.
  - `fact same_take.identical == 1` The same world on two machines.
  - `owed` Each line of the table measured as it is built, and the years a 32 GB and a 64 GB card
    hold worked out from the measures.
  - `owed` A test: a full card thins its oldest dawns to their takes alone, and any of them is made
    again from its take.
- **Asks:** nobody: the sizes answer it.

### `card.carried` The handheld can carry it

- **Said:** `spec/size.md` "The handheld can carry it (measured, docs/hardware-target.md): the card
  reads 43 MB a second with next to no interrupts; a picture the size of one piece's ground uploads
  in about 1.3 ms" "If he ever wants his own playing in the world, the room is there: an hour of it
  is 0.7 GB."
- **Stage:** 2
- **The moment:** Hum walks across the Garden and the world arrives under its feet with no pause and
  no late frame.
- **A cheat would be:** a loading screen between pieces.
- **Full size:**
  - `fact handheld.asters.late == 0` The walk through the proof field with the ground's picture
    drawn under it: every frame on time on the handheld.
  - `owed` Pieces of land read from the card as Hum walks, every frame on time (stage 1).
- **Asks:** Did you ever wait for the world?
