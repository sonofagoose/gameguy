# The board

_Where every claim and every promise stands today. `spec/tools/promises.py` writes this on every
build. It reads each sentence of the specification as a claim, so nobody lists them, and it works
out each rung from what the build proved, what the handhelds logged and what was looked at, so
nobody types one in. What the words mean is in `../promises.md`. Every claim is in `CLAIMS.md`._

## Claims: every sentence a player is promised

| | sentences |
|---|---|
| in the specification | 2150 |
| a promise speaks for it | 664 |
| **kept** | **0** |
| no promise speaks for it yet | 1486 |

| stage | claims | spoken for | kept | open |
|---|---|---|---|---|
| 2 | 648 | 648 | 0 | 0 |
| 3 | 955 | 13 | 0 | 942 |
| 4 | 274 | 2 | 0 | 272 |
| 5 | 194 | 1 | 0 | 193 |
| 6 | 79 | 0 | 0 | 79 |

| document | claims | spoken for | kept |
|---|---|---|---|
| `SPEC.md` | 271 | 205 | 0 |
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
| sized: its moment, its cheat, its full size and its question written | 139 of 139 |
| proven: every measure passes today and nothing is owed | 2 |
| reached: the scripted player met it by playing | 8 |
| felt: Morgan, holding the handheld, answered yes | 0 |
| graded full by a fresh reader | 0 |
| **kept** | **0** |

## Waiting for hands

On the handheld, in the room (Ports, GameguyRoom), the walk puts a person in each of these and
asks its question.

| promise | it asks | answers so far |
|---|---|---|
| `fight.kinds` Wolves, knots and greys | When you moved home to where their threads met, did the knots stop stumbling? | none |
| `evening.black` Black, and a drip | Did the screen look switched off until you called? | jj: no |
| `evening.call` You call, and you are answered | When you called in the dark and something answered, did it feel like being answered? | none |
| `evening.breathe` You breathe with it, and it locks | When the figure stopped, did it feel like the two of you locking? | none |
| `evening.in` "Oh. You're in." | When the world stood up, did you say something out loud? | none |
| `evening.instrument` Everything is an instrument | Did you start ringing things just to hear what they were? | none |
| `garden.land` The Garden, home | Is the Garden somewhere you are glad to wake up? | none |
| `garden.ground` What the Garden's ground wears | Did the ground under you feel different from one patch to the next? | none |
| `garden.asters` Asters as tall as cathedrals | Is it as tall as a cathedral? | none |
| `garden.w01` The answering field | Did the answers coming in from far away make the garden feel big? | none |
| `garden.w04` The puddle bridge | When the lines came up on the water, did you trust them enough to step out? | none |
| `hands.songbook` The songbook teaches without words | When you were lost, did the songbook show you what to do without telling you? | none |
| `card.ground` The ground remembers | Coming back to it, could you see where you had been? | none |
| `sky.dawn` The first dawn | Did you stop to watch the sky come up? | none |
| `sky.bee` The bee | When the bee went past, did its note drop? | none |
| `texture.frame` What makes a frame beautiful | Is every frame something you would want to look at? | none |
| `texture.light` Light is loudness | Could you tell what was loud by looking? | none |
| `wheel.home` The wheel decides where home is | When the wheel opened, could you see where home would go before you let go? | none |
| `hands.voice-in-a-buffer` Your voice, at once | When you hum, does it start the moment you press? | none |
| `light.hue` One set of numbers for sound and light | Could you tell which bells were kin to your note by their colour? | none |

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
| `fight.beat` On the beat | 2 | 3 | no | - | no | no | no | frame evening-pocket: it has changed since it was looked at (by 10.0 of 255 a channel); ears.strike_placed_octave_db <= -30  (is -29.2); no yes from Morgan yet |
| `fight.looper` The looper in a fight | 2 | 2 | no | - | no | no | no | 1 owed; frame evening-afterimage: it has changed since it was looked at (by 8.9 of 255 a channel); frame evening-clap: it has changed since it was looked at (by 10.5 of 255 a channel); no yes from Morgan yet |
| `fight.transform` Nothing dies in a fight | 2 | 2 | no | - | no | no | no | frame evening-swell: it has changed since it was looked at (by 11.7 of 255 a channel); frame evening-grey: it has changed since it was looked at (by 9.4 of 255 a channel); no yes from Morgan yet |
| `fight.kinds` Wolves, knots and greys | 2 | 3 | no | - | no | no | no | 1 owed; frame evening-knots: it has changed since it was looked at (by 8.3 of 255 a channel); no yes from Morgan yet |
| `fight.bosses` Bosses are pieces of music | 2 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `fight.gentle` Gentle or Fierce | 2 | 1 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `evening.black` Black, and a drip | 2 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `evening.call` You call, and you are answered | 2 | 2 | no | yes | no | no | no | 3 owed; handheld.evening.late == 0  (is 359); no yes from Morgan yet |
| `evening.breathe` You breathe with it, and it locks | 2 | 5 | no | yes | no | no | no | 2 owed; frame evening-locked: it has changed since it was looked at (by 2.2 of 255 a channel); no yes from Morgan yet |
| `evening.in` "Oh. You're in." | 2 | 5 | no | - | no | no | no | 2 owed; frame evening-far: it has changed since it was looked at (by 3.7 of 255 a channel); no yes from Morgan yet |
| `evening.instrument` Everything is an instrument | 2 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `evening.knot` The knot, and the first fight | 2 | 10 | no | - | no | no | no | 2 owed; frame evening-open: it has changed since it was looked at (by 10.4 of 255 a channel); frame evening-edge: it has changed since it was looked at (by 16.4 of 255 a channel); no yes from Morgan yet |
| `evening.dusk` The river sings your day back | 2 | 3 | no | - | no | no | no | 4 owed; no yes from Morgan yet |
| `garden.land` The Garden, home | 2 | 14 | no | - | no | no | no | 7 owed; no yes from Morgan yet |
| `garden.ground` What the Garden's ground wears | 2 | 6 | no | - | no | no | no | 4 owed; frame evening-far: it has changed since it was looked at (by 3.7 of 255 a channel); frame evening-foot: it has changed since it was looked at (by 2.8 of 255 a channel); no yes from Morgan yet |
| `garden.asters` Asters as tall as cathedrals | 2 | 1 | no | yes | no | no | no | 3 owed; frame evening-far: it has changed since it was looked at (by 3.7 of 255 a channel); frame evening-foot: it has changed since it was looked at (by 2.8 of 255 a channel); no yes from Morgan yet |
| `garden.great` The Hose | 2 | 6 | no | - | no | no | no | 6 owed; no yes from Morgan yet |
| `garden.w01` The answering field | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w02` The seed that follows | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w03` The parade | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w04` The puddle bridge | 2 | 1 | no | yes | no | no | no | 4 owed; frame evening-bridge: it has changed since it was looked at (by 3.2 of 255 a channel); no yes from Morgan yet |
| `garden.w05` The quiet ball | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w06` The far shore, late | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `garden.w07` The swing | 2 | 1 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `garden.w08` The hose's octave | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w09` The drip's secret | 2 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w10` The third man | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w11` Three against two | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `garden.w12` The pot | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `hands.by-position` Face buttons by where they are | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `hands.map` Every input does what the table says | 2 | 16 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `hands.thumbs` The thumb audit | 2 | 6 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `hands.songbook` The songbook teaches without words | 2 | 4 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `hands.no-fn` FN is never needed | 2 | 1 | yes | - | - | no | no | not graded |
| `lands.shape` The world's shape | 2 | 11 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `lands.two-faces` Every place has two faces | 2 | 3 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `lands.every-land` What every land has | 2 | 8 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `lands.garden-bowl` The Garden is a bowl | 2 | 10 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `laws.things` What a thing is | 2 | 7 | no | - | - | no | no | 2 owed |
| `laws.sympathy` Law 1: sympathy | 2 | 10 | no | - | no | no | no | 4 owed; no yes from Morgan yet |
| `laws.standing-waves` Law 4: standing waves | 2 | 10 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `laws.building-up` Law 7: building up | 2 | 9 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `texture.materials` What a thing is made of | 2 | 17 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `laws.families` The families | 2 | 12 | no | - | - | no | no | 4 owed |
| `laws.gravity` Law 2: gravity | 2 | 17 | no | - | no | no | no | 4 owed; no yes from Morgan yet |
| `laws.in-step` Law 3: falling into step | 2 | 10 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `laws.cancelling` Law 5: cancelling and beating | 2 | 15 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `laws.travel` Law 6: travel | 2 | 14 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `laws.sound-and-light` The table of sound and light | 2 | 11 | no | - | no | no | no | 2 owed; frame evening-bridge: it has changed since it was looked at (by 3.2 of 255 a channel); no yes from Morgan yet |
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
| `card.ground` The ground remembers | 2 | 7 | no | - | no | no | no | 6 owed; frame evening-ground: it has changed since it was looked at (by 3.5 of 255 a channel); handheld.asters.late == 0  (is 2); no yes from Morgan yet |
| `people.rounds` Each life keeps its own time | 2 | 5 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `people.helping` Helping is the day's five steps | 2 | 7 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `people.sung` Nobody is explained | 2 | 2 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `people.ties` Ties, duets and other lives | 2 | 3 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `people.a-life` How a life works | 2 | 23 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `people.garden-eight` The Garden's eight | 2 | 9 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `people.blank` Left blank on purpose | 2 | 5 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `picture.looks-as-it-sounds` How a thing looks is how it sounds | 2 | 3 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `picture.interval` An interval is a figure | 2 | 4 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `picture.afterglow` Afterglow is memory | 2 | 2 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
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
| `rules.lines` Lines of light | 2 | 3 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `rules.alone` Whole alone | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `rules.original` Original | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `rules.morgans-layer` Morgan's layer stays his | 2 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `scale.one-to-a-hundred` One to a hundred | 2 | 28 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `scale.ring` The ring round the lake | 2 | 13 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `sky.dawn` The first dawn | 2 | 7 | no | yes | no | no | no | 5 owed; frame evening-far: it has changed since it was looked at (by 3.7 of 255 a channel); frame evening-horn: it has changed since it was looked at (by 5.0 of 255 a channel); no yes from Morgan yet |
| `sky.bee` The bee | 2 | 3 | no | yes | no | no | no | 3 owed; frame evening-bee: it has changed since it was looked at (by 10.2 of 255 a channel); no yes from Morgan yet |
| `texture.frame` What makes a frame beautiful | 2 | 4 | no | - | no | no | no | 4 owed; beauty.page_black_least >= 0.8  (is 0.7874); no yes from Morgan yet |
| `texture.light` Light is loudness | 2 | 3 | no | - | no | no | no | 4 owed; no yes from Morgan yet |
| `texture.one-rule` How a thing looks is how it sounds | 2 | 10 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `texture.at-rest` A line at rest | 2 | 5 | no | - | no | no | no | 2 owed; frame evening-climb: nobody has looked at it yet; no yes from Morgan yet |
| `texture.sounding` A line that sounds | 2 | 20 | no | - | no | no | no | 2 owed; frame evening-bridge: it has changed since it was looked at (by 3.2 of 255 a channel); no yes from Morgan yet |
| `texture.tuning-seen` Tuning, seen | 2 | 4 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `texture.silence` Silence, seen | 2 | 4 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `texture.surfaces` Surfaces, when there are only lines | 2 | 8 | no | - | no | no | no | 2 owed; frame evening-foot: it has changed since it was looked at (by 2.8 of 255 a channel); frame evening-far: it has changed since it was looked at (by 3.7 of 255 a channel); no yes from Morgan yet |
| `texture.sound-grain` The texture of the sound | 2 | 8 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `texture.across-time` Across time | 2 | 6 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `texture.beautiful` A beautiful frame, checked | 2 | 15 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `wheel.home` The wheel decides where home is | 2 | 3 | no | - | no | no | no | 2 owed; frame evening-wheel: it has changed since it was looked at (by 3.7 of 255 a channel); no yes from Morgan yet |
| `wheel.groove` Each mood is a groove | 2 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `wheel.borrow` The dark wedges | 3 | 2 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
| `voices.five` Five voices | 2 | 4 | no | - | no | no | no | 4 owed; no yes from Morgan yet |
| `swell.walk` The swell walks home | 2 | 3 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `swell.touch` Push hard for bright | 2 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `swell.lean` The lean | 3 | 2 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
| `hands.told-apart` R1 and R2 told apart | 2 | 7 | no | - | no | no | no | 2 owed; frame evening-wheel: it has changed since it was looked at (by 3.7 of 255 a channel); frame evening-swell: it has changed since it was looked at (by 11.7 of 255 a channel); no yes from Morgan yet |
| `breath.one` One breath | 2 | 3 | no | - | no | no | no | 3 owed; no yes from Morgan yet |
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
| `hands.voice-in-a-buffer` Your voice, at once | 1 | 1 | no | - | no | no | no | 2 owed; handheld.hands.most_ms <= 3  (is not reported); no yes from Morgan yet |
| `card.takes` The card is the world's memory | 1 | 2 | no | - | - | no | no | 4 owed |
| `light.hue` One set of numbers for sound and light | 1 | 1 | no | - | no | no | no | 1 owed; no yes from Morgan yet |
| `light.beam` The beam | 1 | 1 | no | - | no | no | no | 2 owed; no yes from Morgan yet |
