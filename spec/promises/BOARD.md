# The board

_Where every claim and every promise stands today. `spec/tools/promises.py` writes this on every
build. It reads each sentence of the specification as a claim, so nobody lists them, and it works
out each rung from what the build proved, what the handhelds logged and what was looked at, so
nobody types one in. What the words mean is in `../promises.md`. Every claim is in `CLAIMS.md`._

## Claims: every sentence a player is promised

| | sentences |
|---|---|
| in the specification | 2160 |
| a promise speaks for it | 672 |
| **kept** | **0** |
| no promise speaks for it yet | 1488 |

| stage | claims | spoken for | kept | open |
|---|---|---|---|---|
| 2 | 658 | 656 | 0 | 2 |
| 3 | 955 | 13 | 0 | 942 |
| 4 | 274 | 2 | 0 | 272 |
| 5 | 194 | 1 | 0 | 193 |
| 6 | 79 | 0 | 0 | 79 |

| document | claims | spoken for | kept |
|---|---|---|---|
| `SPEC.md` | 281 | 213 | 0 |
| `spec/laws.md` | 152 | 152 | 0 |
| `spec/world.md` | 459 | 58 | 0 |
| `spec/people.md` | 161 | 37 | 0 |
| `spec/size.md` | 82 | 82 | 0 |
| `spec/years.md` | 96 | 0 | 0 |
| `spec/together.md` | 66 | 0 | 0 |
| `spec/sky.md` | 473 | 10 | 0 |
| `spec/shape.md` | 286 | 16 | 0 |
| `spec/texture.md` | 104 | 104 | 0 |

## Promises: what speaks for the claims

| rung | promises |
|---|---|
| sized: its moment, its cheat, its full size and its question written | 140 of 140 |
| proven: every measure passes today and nothing is owed | 2 |
| reached: the scripted player met it by playing | 8 |
| felt: Morgan, holding the handheld, answered yes | 16 |
| graded full by a fresh reader | 0 |
| **kept** | **0** |

## Waiting for hands

On the handheld, in the room (Ports, GameguyRoom), the walk puts a person in each of these and
asks its question.

| promise | it asks | answers so far |
|---|---|---|
| `fight.kinds` Wolves, knots and greys | When you moved home to where their threads met, did the knots stop stumbling? | none |
| `evening.black` Black, and a drip | Did the screen look switched off until you called? | jj: no; morgan: yes |
| `evening.call` You call, and you are answered | When you called in the dark and something answered, did it feel like being answered? | morgan: yes |
| `evening.breathe` You breathe with it, and it locks | When the figure stopped, did it feel like the two of you locking? | morgan: yes |
| `evening.in` "Oh. You're in." | When the world stood up, did you say something out loud? | morgan: yes |
| `evening.instrument` Everything is an instrument | Did you start ringing things just to hear what they were? | morgan: yes |
| `garden.land` The Garden, home | Is the Garden somewhere you are glad to wake up? | morgan: no |
| `garden.ground` What the Garden's ground wears | Did the ground under you feel different from one patch to the next? | morgan: yes |
| `garden.asters` Asters as tall as cathedrals | Is it as tall as a cathedral? | morgan: yes |
| `garden.w01` The answering field | Did the answers coming in from far away make the garden feel big? | morgan: yes |
| `garden.w04` The puddle bridge | When the lines came up on the water, did you trust them enough to step out? | morgan: yes |
| `hands.view` The view follows, and goes where you want it | Could you always see what you wanted to see, without fighting the view? | morgan: no |
| `hands.songbook` The songbook teaches without words | When you were lost, did the songbook show you what to do without telling you? | morgan: no |
| `card.ground` The ground remembers | Coming back to it, could you see where you had been? | morgan: yes |
| `sky.dawn` The first dawn | Did you stop to watch the sky come up? | morgan: no |
| `sky.bee` The bee | When the bee went past, did its note drop? | morgan: no |
| `texture.frame` What makes a frame beautiful | Is every frame something you would want to look at? | none |
| `texture.light` Light is loudness | Could you tell what was loud by looking? | morgan: yes |
| `wheel.home` The wheel decides where home is | When the wheel opened, could you see where home would go before you let go? | morgan: yes |
| `hands.voice-in-a-buffer` Your voice, at once | When you hum, does it start the moment you press? | morgan: yes |
| `light.hue` One set of numbers for sound and light | Could you tell which bells were kin to your note by their colour? | morgan: no |

## Every promise

| promise | stage | speaks for | proven | reached | felt | graded | kept | what stands in the way |
|---|---|---|---|---|---|---|---|---|
| `arc.one-breath` The game in one breath | 2 | 6 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `arc.day` A day is a song | 2 | 9 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `arc.instruments` Every thing is an instrument | 2 | 5 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `card.light` Why nothing on the card was a picture | 2 | 5 | no | - | - | no | no | 1 owed |
| `card.no-copies` Nothing is a copy | 2 | 5 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `card.kept` Nothing is forgotten | 2 | 8 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `card.years` A card is a number of years | 2 | 14 | no | - | - | no | no | 2 owed; same_take.identical == 1  (is 0) |
| `card.carried` The handheld can carry it | 2 | 2 | no | - | no | no | no | 1 owed; handheld.asters.late == 0  (is 2); no yes from Morgan yet |
| `fight.beat` On the beat | 2 | 4 | no | - | no | no | no | frame evening-pocket: today's build has not dumped it; test "a strike timed within an eighth of a beat lands at once with its octave; off the beat the game places it on the next beat, plain"; no yes from Morgan yet |
| `fight.looper` The looper in a fight | 2 | 2 | no | - | no | no | no | 1 owed; frame evening-afterimage: today's build has not dumped it; frame evening-clap: today's build has not dumped it; Morgan said no |
| `fight.transform` Nothing dies in a fight | 2 | 2 | no | - | yes | no | no | frame evening-swell: today's build has not dumped it; frame evening-grey: today's build has not dumped it |
| `fight.kinds` Wolves, knots and greys | 2 | 3 | no | - | no | no | no | 1 owed; frame evening-knots: today's build has not dumped it; no yes from Morgan yet |
| `fight.bosses` Bosses are pieces of music | 2 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `fight.gentle` Gentle or Fierce | 2 | 1 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `evening.black` Black, and a drip | 2 | 2 | no | - | yes | no | no | 2 owed |
| `evening.call` You call, and you are answered | 2 | 2 | no | yes | yes | no | no | 3 owed; handheld.evening.late == 0  (is 704) |
| `evening.breathe` You breathe with it, and it locks | 2 | 5 | no | yes | yes | no | no | 2 owed; frame evening-figure: it has changed since it was looked at (by 3.1 of 255 a channel); frame evening-locked: it has changed since it was looked at (by 3.7 of 255 a channel) |
| `evening.in` "Oh. You're in." | 2 | 6 | no | - | yes | no | no | 2 owed; frame evening-rising: it has changed since it was looked at (by 7.6 of 255 a channel); frame evening-far: it has changed since it was looked at (by 17.2 of 255 a channel) |
| `evening.instrument` Everything is an instrument | 2 | 2 | no | - | yes | no | no | 2 owed; frame evening-answer: it has changed since it was looked at (by 3.3 of 255 a channel) |
| `evening.knot` The knot, and the first fight | 2 | 11 | no | - | yes | no | no | 2 owed; test "a strike timed within an eighth of a beat lands at once with its octave; off the beat the game places it on the next beat, plain"; frame evening-open: today's build has not dumped it |
| `evening.dusk` The river sings your day back | 2 | 3 | no | - | no | no | no | 4 owed; no yes from Morgan yet |
| `garden.land` The Garden, home | 2 | 14 | no | - | no | no | no | 7 owed; Morgan said no |
| `garden.ground` What the Garden's ground wears | 2 | 6 | no | - | yes | no | no | 4 owed; frame evening-far: it has changed since it was looked at (by 17.2 of 255 a channel); frame evening-foot: it has changed since it was looked at (by 12.8 of 255 a channel) |
| `garden.asters` Asters as tall as cathedrals | 2 | 1 | no | yes | yes | no | no | 3 owed; asters.hum_px_walking <= 26  (is 45.458); frame evening-far: it has changed since it was looked at (by 17.2 of 255 a channel) |
| `garden.great` The Hose | 2 | 6 | no | - | no | no | no | 6 owed; no yes from Morgan yet |
| `garden.w01` The answering field | 2 | 1 | no | - | yes | no | no | 2 owed |
| `garden.w02` The seed that follows | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w03` The parade | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w04` The puddle bridge | 2 | 1 | no | yes | yes | no | no | 4 owed; ears.pool_adds_db >= 3  (is 0.037); frame evening-pool: it has changed since it was looked at (by 4.0 of 255 a channel) |
| `garden.w05` The quiet ball | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w06` The far shore, late | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `garden.w07` The swing | 2 | 1 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `garden.w08` The hose's octave | 2 | 1 | no | - | no | no | no | 2 owed; Morgan said no |
| `garden.w09` The drip's secret | 2 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w10` The third man | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w11` Three against two | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w12` The pot | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `hands.by-position` Face buttons by where they are | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `hands.map` Every input does what the table says | 2 | 14 | no | - | no | no | no | 2 owed; test "a strike timed within an eighth of a beat lands at once with its octave; off the beat the game places it on the next beat, plain"; Morgan said no |
| `hands.thumbs` The thumb audit | 2 | 7 | no | - | no | no | no | 2 owed; test "the bottom face jumps five metres, and in the air opens the glide, which sinks slowly and spends breath"; no yes from Morgan yet |
| `hands.view` The view follows, and goes where you want it | 2 | 1 | no | - | no | no | no | 2 owed; Morgan said no |
| `hands.songbook` The songbook teaches without words | 2 | 4 | no | - | no | no | no | 2 owed; Morgan said no |
| `hands.no-fn` FN is never needed | 2 | 1 | yes | - | - | no | no | not graded |
| `lands.shape` The world's shape | 2 | 11 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `lands.two-faces` Every place has two faces | 2 | 3 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `lands.every-land` What every land has | 2 | 8 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `lands.garden-bowl` The Garden is a bowl | 2 | 10 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `laws.things` What a thing is | 2 | 7 | no | - | - | no | no | 2 owed |
| `laws.sympathy` Law 1: sympathy | 2 | 10 | no | - | no | no | no | 4 owed; no yes from Morgan yet |
| `laws.standing-waves` Law 4: standing waves | 2 | 10 | no | - | no | no | no | 3 owed; frame evening-pool: it has changed since it was looked at (by 4.0 of 255 a channel); no yes from Morgan yet |
| `laws.building-up` Law 7: building up | 2 | 9 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `texture.materials` What a thing is made of | 2 | 17 | no | - | no | no | no | 2 owed; frame evening-pool: it has changed since it was looked at (by 4.0 of 255 a channel); no yes from Morgan yet |
| `laws.families` The families | 2 | 12 | no | - | - | no | no | 4 owed |
| `laws.gravity` Law 2: gravity | 2 | 17 | no | - | no | no | no | 4 owed; no yes from Morgan yet |
| `laws.in-step` Law 3: falling into step | 2 | 10 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `laws.cancelling` Law 5: cancelling and beating | 2 | 15 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `laws.travel` Law 6: travel | 2 | 14 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `laws.sound-and-light` The table of sound and light | 2 | 11 | no | - | no | no | no | 2 owed; frame evening-bridge: it has changed since it was looked at (by 14.9 of 255 a channel); no yes from Morgan yet |
| `laws.home` Home over the laws | 2 | 15 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `laws.tuning` Tuning | 2 | 15 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `laws.ears` Limits for the ears | 2 | 7 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `loop.river` The river sings your day back | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `loop.echoes` Echoes | 2 | 4 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `loop.release` What you let go becomes the place | 2 | 3 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `loop.dreams` Dreams join paths | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `loop.pools-remember` Pools hold what happened beside them | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `loop.book` A page a day | 2 | 2 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `loop.card` A card is a number of years | 2 | 3 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `loop.mornings` Days are mornings played | 2 | 1 | yes | - | - | no | no | not graded |
| `card.ground` The ground remembers | 2 | 7 | no | - | yes | no | no | 6 owed; frame evening-ground: it has changed since it was looked at (by 15.4 of 255 a channel); handheld.asters.late == 0  (is 2) |
| `people.rounds` Each life keeps its own time | 2 | 5 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `people.helping` Helping is the day's five steps | 2 | 7 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `people.sung` Nobody is explained | 2 | 2 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `people.ties` Ties, duets and other lives | 2 | 3 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `people.a-life` How a life works | 2 | 23 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `people.garden-eight` The Garden's eight | 2 | 9 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `people.blank` Left blank on purpose | 2 | 5 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `picture.looks-as-it-sounds` How a thing looks is how it sounds | 2 | 3 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `picture.interval` An interval is a figure | 2 | 4 | no | - | no | no | no | 1 owed; ears.third_note_db_over_quiet >= 30  (is 20.952); no yes from Morgan yet |
| `picture.afterglow` Afterglow is memory | 2 | 2 | no | - | no | no | no | 1 owed; frame evening-answer: it has changed since it was looked at (by 3.3 of 255 a channel); no yes from Morgan yet |
| `picture.backlight` The backlight is the sun | 2 | 3 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `picture.physics` Made from the same physics | 2 | 2 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `picture.speaker` The speaker is the floor | 2 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `picture.seeing` A seeing option | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `rules.human-first` Human first | 2 | 2 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `rules.consonant` Dissonance going somewhere | 2 | 2 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `rules.ears` Morgan's ears judge every sound | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `rules.no-tables` Nothing matched by hand | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `rules.no-notes` You never choose a note | 2 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `rules.transform` Nothing dies | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `rules.no-hud` Nothing on the screen that isn't in the world | 2 | 2 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `rules.lines` Lines of light | 2 | 3 | no | - | no | no | no | 1 owed; beauty.place_black_least >= 0.5  (is 0.4163); no yes from Morgan yet |
| `rules.alone` Whole alone | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `rules.original` Original | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `rules.morgans-layer` Morgan's layer stays his | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `scale.one-to-a-hundred` One to a hundred | 2 | 28 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `scale.ring` The ring round the lake | 2 | 13 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `sky.dawn` The first dawn | 2 | 7 | no | yes | no | no | no | 5 owed; frame evening-far: it has changed since it was looked at (by 17.2 of 255 a channel); frame evening-horn: it has changed since it was looked at (by 17.9 of 255 a channel); Morgan said no |
| `sky.bee` The bee | 2 | 3 | no | yes | no | no | no | 3 owed; frame evening-bee: it has changed since it was looked at (by 11.9 of 255 a channel); Morgan said no |
| `texture.frame` What makes a frame beautiful | 2 | 4 | no | - | no | no | no | 4 owed; beauty.place_black_least >= 0.5  (is 0.4163); asters.hum_px_walking <= 24  (is 45.458); no yes from Morgan yet |
| `texture.light` Light is loudness | 2 | 3 | no | - | yes | no | no | 4 owed; frame evening-answer: it has changed since it was looked at (by 3.3 of 255 a channel) |
| `texture.one-rule` How a thing looks is how it sounds | 2 | 10 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `texture.at-rest` A line at rest | 2 | 5 | no | - | no | no | no | 2 owed; frame evening-climb: nobody has looked at it yet; no yes from Morgan yet |
| `texture.sounding` A line that sounds | 2 | 20 | no | - | no | no | no | 2 owed; frame evening-pool: it has changed since it was looked at (by 4.0 of 255 a channel); frame evening-bridge: it has changed since it was looked at (by 14.9 of 255 a channel); no yes from Morgan yet |
| `texture.tuning-seen` Tuning, seen | 2 | 4 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `texture.silence` Silence, seen | 2 | 4 | no | - | no | no | no | 2 owed; beauty.place_black_least >= 0.5  (is 0.4163); no yes from Morgan yet |
| `texture.surfaces` Surfaces, when there are only lines | 2 | 8 | no | - | no | no | no | 2 owed; frame evening-foot: it has changed since it was looked at (by 12.8 of 255 a channel); frame evening-far: it has changed since it was looked at (by 17.2 of 255 a channel); no yes from Morgan yet |
| `texture.sound-grain` The texture of the sound | 2 | 8 | no | - | no | no | no | 2 owed; ears.third_note_db_over_quiet >= 30  (is 20.952); no yes from Morgan yet |
| `texture.across-time` Across time | 2 | 6 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `texture.beautiful` A beautiful frame, checked | 2 | 15 | no | - | no | no | no | 2 owed; beauty.place_black_least >= 0.5  (is 0.4163); no yes from Morgan yet |
| `wheel.home` The wheel decides where home is | 2 | 3 | no | - | yes | no | no | 2 owed; frame evening-wheel: it has changed since it was looked at (by 22.9 of 255 a channel) |
| `wheel.groove` Each mood is a groove | 2 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `wheel.borrow` The dark wedges | 3 | 2 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `voices.five` Five voices | 2 | 4 | no | - | no | no | no | 4 owed; no yes from Morgan yet |
| `swell.walk` The swell walks home | 2 | 3 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `swell.touch` Push hard for bright | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `swell.lean` The lean | 3 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `hands.told-apart` R1 and R2 told apart | 2 | 12 | no | - | yes | no | no | 2 owed; frame evening-wheel: it has changed since it was looked at (by 22.9 of 255 a channel); frame evening-swell: today's build has not dumped it |
| `breath.one` One breath | 2 | 3 | no | - | no | no | no | 3 owed; Morgan said no |
| `whole.scale` One to a hundred | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `whole.true` Literally true | 1 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `whole.law1` Sympathy | 1 | 1 | no | yes | no | no | no | 1 owed; no yes from Morgan yet |
| `whole.law2` Gravity | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `whole.law3` Falling into step | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `whole.law4` Standing waves | 2 | 1 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `whole.law5` Cancelling and beating | 2 | 1 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `whole.law6` Travel | 1 | 1 | no | yes | no | no | no | 1 owed; no yes from Morgan yet |
| `whole.law7` Building up | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `whole.twice` Every cue twice | 1 | 3 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `whole.same` A take is its inputs | 1 | 1 | no | - | - | no | no | same_take.identical == 1  (is 0) |
| `whole.alone` Whole alone, more together | 6 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `whole.endless` The mornings never repeat | 5 | 1 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `whole.lights` Every land's lights across the water | 3 | 1 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `whole.good` It sounds good | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `whole.hands` Nothing asks the hands for the impossible | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `whole.ear` The ear, before and after | 2 | 1 | no | - | - | no | no | 3 owed |
| `hands.voice-in-a-buffer` Your voice, at once | 1 | 1 | no | - | yes | no | no | 2 owed; handheld.hands.most_ms <= 3  (is not reported) |
| `card.takes` The card is the world's memory | 1 | 2 | no | - | - | no | no | 4 owed |
| `light.hue` One set of numbers for sound and light | 1 | 1 | no | - | no | no | no | 1 owed; frame evening-answer: it has changed since it was looked at (by 3.3 of 255 a channel); Morgan said no |
| `light.beam` The beam | 1 | 1 | no | - | no | no | no | 2 owed; frame dark-ring: it has changed since it was looked at (by 2.2 of 255 a channel); no yes from Morgan yet |
