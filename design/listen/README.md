# Listening tests

Short sketches for Morgan's ears, made because Claude can't hear. Each clip settles one design
question. `python3 -I design/listen/make.py` rebuilds every clip (pure Python, no packages; 22,050
Hz mono WAV). The ideas behind them are in `../shape-2-volta.md` and `../shape-3-the-lake-ring.md`.

## The ear check (clips 1–8)

| clip | what it is | the question |
|---|---|---|
| 1-echoes-sour | today plus echoes kept 3 and 4 days, as Volta's arithmetic makes them | could you hear this for fifteen minutes? |
| 2-echoes-sweet | the same three voices retuned into today | and this? |
| 3-comma-and-swell | two tones a comma apart, then two tones 2 cents apart | is either beautiful, for a moment? |
| 4-seven-moods | one phrase in the seven modes, brightest to darkest | do they read as feelings? which feel like which powers? |
| 5-piano-then-ring | a major chord as a piano tunes it, then tuned pure | can you hear it ring? should locking in sound like that? |
| 6-home-then-longing | a phrase that comes home, then one that almost does | longing, or just wrong? |
| 7-the-day-rises | a motif that returns a fifth higher each "day" | does it lift, or feel restless? |
| 8-third-voice | two voices lock on a pure third, and a lower third voice appears | does it land? |

## The lands (clips 9–16)

Each tuning system played the way it sounds best.

| clip | what it is | the question |
|---|---|---|
| 9-land-just | home: pure ratios, ending on a barbershop seventh | does it ring? |
| 10-land-fifths | Pythagorean: a chant over an open fifth | ancient and strong, or thin? |
| 11-land-sweet-thirds | meantone: warm chords, then the wolf fifth alone for two seconds | is the wolf the right kind of awful? |
| 12-land-treaty | equal temperament: twelve chords falling through every key, landing exactly home | do you feel the closure? |
| 13-land-well-tempered | Werckmeister III: four chords in C, then the same four in F♯ | can you hear the keys' different colours? |
| 14-land-shimmer | bronze bars in pairs a few hertz apart, beating on purpose (as in Balinese gamelan) | beautiful, or seasick? |
| 15-land-no-octave | Bohlen–Pierce: thirteen steps of a 3:1, clarinet-like tone | alien in a good way? |
| 16-rhythm-becomes-pitch | a 3-against-2 rhythm speeds up until it becomes a fifth | does it show "rhythm and pitch are one thing"? |

## The wheel (clips 17–31)

Sketches for `../the-wheel.md`, `../experience-fixes.md` and `../the-way-home.md`. If there is
only time for five: 24, 18, 26, 22, 23.

| clip | what it is | the question |
|---|---|---|
| 17-two-ways-home | a full close, then an amen | two different endings, one that springs open and one that settles? |
| 18-home-the-long-way | walks home of two, three, four and five chords, then the whole key | does each longer walk feel bigger? is the whole key the best one? |
| 19-it-turns | a close that lands on its neighbour; then on a borrowed chord that walks home another way | a twist, or a mistake? |
| 20-borrowing-home | a phrase in D that borrows the chord on C for one bar and comes back | does stepping out and back feel like looking home? |
| 21-the-slide | home by a fifth, then home by a half step from the far side | does the second feel sly and sideways? |
| 22-stand-where-they-meet | three against five, then the low note under both comes in on the one | does the stumble turn into a groove? |
| 23-rising-doubled | an echo's tune at four dusks: three warnings, each a little longer, then the howl | can you hear the warnings, and bear them? is the fourth a howl? |
| 24-the-comma-in-time | a comma at middle C with a heartbeat at 107 a minute; then a third voice between the two; then a chord on it | could you hold this for a few seconds? does the third voice make it breathe? (clip 3 is the same comma with no pulse round it) |
| 25-twelve-mornings | twelve steps up by pure fifths in one breath, then the first note comes back beside the last | does it feel like the whole journey? is the arrival clear? |
| 26-one-note-seven-homes | one held note while home walks under it, brightest mood to darkest, then home | does the same note feel like seven things? which is which power? |
| 27-placed-and-true | four fork strikes as the game places them, then four as they ring when you were on the beat | can you hear the difference? would you chase it? |
| 28-two-tellings | a day sung back with its repeat: first the same, then different | one voice, then two? |
| 29-two-suns | five dawns that open a comma apart and close, each slower; a sixth that doesn't close | five mornings running: a pleasure, or a tax? |
| 30-be-the-ground | five reeds wandering; one low held note comes in; they settle onto it | does the low note feel like ground arriving? |
| 31-the-close-that-misses | a close that lands; the same close landing on the wolf fifth; then a third note between the wolf's two ends | does the miss hurt the right amount? does the third note mend it? |

Checked by measurement (Claude can't judge the sound itself):

- Clip 24 pulses 3.57 times a second while two voices hold the comma, which is exactly two to the
  beat at 107.08 beats a minute. Once the third voice is in, it pulses exactly once a beat.
- The warnings in clip 23 pulse at the same 3.57 a second.
- Rebuilding left clips 1–16 byte for byte as they were.

## From the game itself (clips 32 on)

Cut from the first evening as the scripted player plays it, by `game/tools/clips.py`: the game's
own sound at 48,000 Hz, not a sketch. Rebuilt whenever the evening changes.

| clip | what it is | the question |
|---|---|---|
| 32-water-sings-back | Hum hums at the edge of the bridge puddle; the water comes up in a ring and a cross and sings Hum's note back, about 4 dB louder as it stands | did the note bloom nicely as the water stood, or was it too much, or too little? |
| 33-the-bee | the bee working the clover a little way ahead of Hum, its hum the garden's note, falling as it goes by | does the bee sound like a bee you would want near you? |
| 34-underfoot | walking to the great aster over lawn and fallen leaves: dew ticks behind Hum, leaves ring underfoot in the garden's scale | pleasant to walk through, or fussy? |
| 35-wonder | home moved to wonder, the F below; Hum hums at the puddle sized for it, and it stands and sings F back | does home on wonder sound like another place than sunny home? |
| 36-the-amen | the swell, Gentle: Hum holds its note and never touches the stick; after a bar home drifts up a fifth beside the grey knots, and Hum lets go on the next downbeat: the amen lands, a chord from Hum, the knots sigh and settle asleep, and the garden answers | does letting go on the one feel like landing somewhere? |
| 37-placed-then-timed | a strike pressed well off the beat, which the game places on the next beat, its note alone; then the downbeat struck on time by the hands, its note with its octave, and the knots ringing harder | does the strike you time yourself sound like more power than the one the game placed? |
| 38-the-hose-opens | the hose stopped by its knot hums low and hollow, odd overtones only, from wherever you are; the knots settle and it springs open: an octave up, every overtone back, and the water runs down it and pours into the pool | did the hose sound like the same pipe, opened? |
| 39-a-stalk-brushed | Hum runs at the great aster and brushes its stalk: a short low knock where it touched, and the aster's bells ringing softly far overhead, each arriving when its sound has come down | did brushing the stalk sound like touching something that belongs to the bells? |
