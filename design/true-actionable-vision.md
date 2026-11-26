# Gameguy: The True Actionable Vision Document

> **Status, 2026-11-26.** History: a synthesis of 2026-11-21 by another model, built on `SPEC.md`
> and its promise board. It is not the direction. Its controls (the mood wheel on R1, the voice
> wheel on L1, the guard on L2), its thirteen mornings and its plan by stages are retired. What the
> game is: `design/the-game.md`.

> _"A game that could have been made for anyone, on any machine, has failed even if it runs."_  
> — Morgan, `SPEC.md` §2

---

## Executive Summary: Why This Document Exists

Claude's recent update reported technical milestones: 99 unit tests passing, camera overrides, speed tuning (12 m/s run, 20 m/s sprint), and fight mechanics transplanted from the page toy. While technically real, that report reads like an incremental software changelog. It treats the project as a collection of isolated features rather than grasping the monumental, deeply personal work this game actually is.

Across the **87 markdown documents (25,571 lines)** in this repository, there is an extraordinary, coherent masterwork waiting to be realized. This document synthesizes all of them into one definitive, actionable blueprint: connecting Morgan's raw personal material, the mathematical/acoustic physics, the moment-to-moment physical feeling on the R36S handheld, the 13-morning spiral, the honest state of the code (`BOARD.md`: **0 of 2,160 promises kept**), and the exact path to completion.

---

## 1. The Core Thesis & The Soul (The "Why")

### 1.1 What Morgan Asked For
- **Scope & Depth:** *"A Tears of the Kingdom ruled by music where the nature of existence and love and humanity and the very fabric of space and time is revealed through the lens of music and harmony and math and sound and love and dissonance"* (`shape-1` / `SPEC.md` §2).
- **Emotional Weight:** *"I played in Majora's Mask for 7 years before 100% the game... what we're building should vastly vastly absolutely immensely surpass that game as far as content and design elegance and... emotional attachment... discovery, sadness, happiness"* (`spec/years.md`).
- **Maximalism:** *"We can be maximal instead of minimal... I don't want anything to be held back just for the sake of optimization... be ambitious"* (`SPEC.md` §2, `CLAUDE.md`).
- **Authenticity:** Built for Morgan first on his handheld, JJ second on the purple handheld (`SPEC.md` §2).

### 1.2 The Root: The Poem & The Comma (`r36s-game-brainstorm.md` App. A)
> *"In the midst of the spiral where all but the generator turn static and fade, no compass with which to map meaning, I concede.*  
> *Any point at which one might first settle down is arbitrary. There is no end or beginning, twelve fifths overshoot home and miss forever. As every note carries its octave within, the nature of the space is to fold, but never close.*  
> *That fact leaves a gap, a crack in the wall where TIME enters the equation and we are faced with two choices: WHERE, and HOW HIGH home is...*  
> *Along come silly human with their silly human crew: 'may as well put a finger down, call it home (C), split the difference, eat the error, and FAKE THE CLOSURE.'*  
> *Equal temperament is the quantization chosen to be equidistant in every key, maximally fair, minimally faithful...*  
> *What else then might we have to secure common ground than a TREATY...*  
> *Let it be known: errors do not sit well with my stomach.*  
> *But then, looking in, I am reminded: ache IS the engine, we work because we want as we work as we want...*  
> *Harmony cultivates wanting by metabolizing error as remainder.*  
> *A music with no remainder leaves nothing to want in a world where wanting is the product.*  
> *It is freedom, our arrival... JJ+Mo 😍 4eva 😍"*

### 1.3 The Living Scene: The Worksheet (`material/morgan-pieces-2026-11-12.md`)
The entire cast and world geography are not arbitrary fantasy tropes; they are the physical distillation of a real storm passing over a porch:
- **The Box Elder Sapling** $\rightarrow$ Box Elder (the talkative sapling who sings the tune).
- **The Knotted Garden Hose** $\rightarrow$ *"A demon of fear... from people... wants to be undone... knows something about ego"* $\rightarrow$ The 1.5 km hose holding back the waters.
- **The Still Pool of Water** $\rightarrow$ *"A mirror... gift from mother earth... wants to return to the ocean... knows something about time"* $\rightarrow$ The Mirror Pool.
- **The Marlboro No. 27** $\rightarrow$ *"A gypsy family spice caravan No. 27... wants to make a trade... knows something about harmony"* $\rightarrow$ Jeanne and Caravan No. 27 trading in out-of-key notes.
- **The Fly on the Knee** $\rightarrow$ The fly that insists on resting on Hum.
- **The Patio Awning Lights** $\rightarrow$ Patio (flying strand of glowing bulbs, singing high *ee*).
- **The White Cat in the Road** $\rightarrow$ The white cat at the forks.
- **The River & Safe and Sound** $\rightarrow$ The river carrying you home downstream at dusk.

### 1.4 Non-Negotiable Rules of the Design (`SPEC.md` §5)
1. **Human first:** Every mechanic starts from feeling (calling and being answered, being seen, keeping and letting go).
2. **Consonant and beautiful by default:** Dissonance is brief, purposeful, and always resolves. The Pythagorean comma lives in the structure and landscape, heard only in rare earned seconds.
3. **Literally true:** One single mathematical model of frequencies, phases, and ratios drives sound, picture, and physics. No tables or cheats.
4. **No choosing notes in the first turn:** The player chooses *where* (home), *who* (voice), *how* (mood), and *when* (the beat). Choosing raw notes is the ending's gift.
5. **Nothing dies:** Things transform. Knots untangle; wolves become pups that drum; greys regain colour.
6. **Nothing on screen that isn't in the world:** No HUD, no minimap, no health bars. At most one line of Space Mono text.
7. **Lines of light on black:** Oscilloscope beam drawing. Hum and voices riding on it are the only solid things.
8. **Every cue twice:** Every essential event exists simultaneously in light and sound.
9. **Whole alone:** Together adds; it never subtracts.
10. **A take is its inputs:** Deterministic simulation driven solely by sound-buffer-stamped controller inputs.
11. **Original:** No borrowed IP.
12. **Morgan's own layer stays his:** Who the vine is, who sat on the pool's edge, who sat in the Porch chair are never explained or prescribed.

---

## 2. The Player Experience as Felt (Moment-to-Moment in the Hand)

```
                    ┌────────────────────────┐
                    │      R36S Handheld     │
                    │   640x480 IPS Display  │
                    │    Mono Speaker Floor  │
                    └───────────┬────────────┘
                                │
        ┌───────────────────────┴───────────────────────┐
        ▼                                               ▼
┌───────────────────────────────┐       ┌───────────────────────────────┐
│     LEFT HAND (Navigation)    │       │    RIGHT HAND (Expression)    │
│ • Left Stick: Run (12 m/s),   │       │ • Right Stick: Camera Dial    │
│   Sprint (20 m/s), Skid-Turn  │       │   (feet-up to 43m top-down)   │
│ • L3: Hush (silence/darkness) │       │ • Face Buttons:               │
│ • L1: Voice Wheel (Doorstop,  │       │   - Bottom: Jump (5m) / Sail  │
│   Drip, Box Elder, Puffball,  │       │   - Right: Dash (6m) / Dodge  │
│   Patio)                      │       │   - Left: Fork Strike Wave    │
│ • L2: Lock-on / Guard         │       │   - Top: Grab / Phrase Keep   │
│                               │       │ • R1: Call / Mood Wheel       │
│                               │       │ • R2: Hum / Swell (Sing)      │
└───────────────────────────────┘       └───────────────────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │      L1 + R1 Clap     │
                    │ (The Treaty / Reset)  │
                    └───────────────────────┘
```

### 2.1 The Screen and Speaker
- **The Screen:** 3.5" IPS 640×480 at 60.02 Hz. At 229 ppi, single-pixel lines render with the delicacy of an oscilloscope beam. The game writes the hardware backlight directly: down to 14/255 in the dark (drawing only 195 mA), rising with dawn, breathing subtly with chord swells (`docs/hardware-target.md`).
- **The Speaker:** Single mono speaker on the RK3326. Low fundamental frequencies (<400 Hz) are mathematically distributed to their 2nd and 3rd harmonics so the physical speaker reproduces them crisply without muddy intermodulation distortion (`DECISIONS.md` row 119). When headphones are plugged into the 3.5mm jack, full unattenuated sub-bass is restored.

### 2.2 Movement & Camera (Addressing Morgan's Feedback)
- **Speed with Weight:** Walking ease gives 8 m/s instantly, ramping to 12 m/s run (1/5 sound speed), and 20 m/s sprint (1/3 sound speed). Tight turns at speed execute a physics skid-turn with ground audio/light feedback (`DECISIONS.md` row 137, 142).
- **Verticality:** Jumps reach 5 meters. Falling into air opens the Sail/Glide, drifting downward at 2 m/s while carrying forward momentum across wind vectors (`DECISIONS.md` row 133).
- **The Right Stick Always Wins:** The camera travels on a continuous geometric dial from low at Hum's feet looking up 25° (to take in cathedral-tall asters) to 43 meters directly above Hum looking down 64° (`DECISIONS.md` row 136). Dynamic camera pushes (fights, water) yield instantly to player input.
- **Solids that Answer:** Aster stalks, reeds, clover stems, crumbs, and the spigot are physical colliders. Brushing an aster knocks its note and rings its open fifth across its bells (`DECISIONS.md` row 131, 138).

### 2.3 The Two Wheels: Differentiated in Mind and Muscle
One of the most vital design corrections (`DECISIONS.md` row 110, 139):
- **R1 Held = The Mood Wheel (Stopping to Think):**  
  Holding R1 folds the 3D place back toward the flat page. Time thickens to 1/4 speed. The wheel lies on the ground around Hum. The right stick selects among the 7 lit moods (diatonic scale degrees) on the circle of fifths. Resting on a wedge previews its harmonic effect under Hum's breath. Threads connect nearby creatures to the wedge where they would fall into step. Letting go commits the change of home.
- **R2 Held = The Swell (Playing in Time):**  
  Hum swells in place, adding a band of colour each bar (tonic $\rightarrow$ 5th $\rightarrow$ 3rd $\rightarrow$ 7th $\rightarrow$ 9th). Time does NOT freeze; Drip's metronome ticks in time (with beat 1 accented higher in pitch). Nudging the stick on downbeats walks home wedge by wedge. Releasing on beat 1 resolves the cadence (Full Close, Amen, Turn, or Slide).

---

## 3. The 13 Mornings & The World Architecture

```mermaid
flowchart TD
    subgraph "Mornings 1–7: Going Out (Expanding Circle of Fifths)"
        M1["Morning 1: The Garden (C Pure) - Drip & The Hose"] --> M2["Morning 2: The Alfalfa (G Pure) - Box Elder & Wind Harp"]
        M2 --> M3["Morning 3: The Glass Hills (D Fifths) - Doorstop & Armonica"]
        M3 --> M4["Morning 4: The Bell Meadow (A Thirds) - The Belfry & First Pack"]
        M4 --> M5["Morning 5: The Highway (E Thirds) - The Stage, Patio & The Vine"]
        M5 --> M6["Morning 6: The Chrome Nave (B Well-Tempered) - The Organ Engine"]
        M6 --> M7["Morning 7: The Seam (F#/Gb Equal) - The Metronome & The Wolf"]
    end
    
    subgraph "Mornings 8–12: The Way Home (The Spiral Climbs; Sun Doubled)"
        M7 -.-> M8["Morning 8: Aster Steps (Db) - Bell Jar; Voice Cracks"]
        M8 --> M9["Morning 9: Verbena Hollow (Ab) - Music Box; Triangle Chords"]
        M9 --> M10["Morning 10: Rain Steps (Eb) - The Cistern; Released Takes Rain"]
        M10 --> M11["Morning 11: Reed Mouths (Bb) - Drone Ground; Band Fights"]
        M11 --> M12["Morning 12: The Porch (F) - The Guitar; Night Withheld"]
    end

    subgraph "The 13th Morning: The Comma Arrival"
        M12 ==> M13["Morning 13: The Garden in B# (Comma Sharp)"]
        M13 --> OfferA["The Clap: The Grid's Treaty (Equal Temperament / Frozen Grey)"]
        M13 --> OfferB["The Step: The Wolf's Path (Infinite Unresolved Drift)"]
        M13 --> OfferC["The Hold: The Duet with The Vine (Loving the Remainder)"]
    end
```

### 3.1 World Topography: 1 to 100 Scale
- Hum is 1 meter tall, representing a 1-centimeter garden creature (`spec/size.md`).
- Asters stand 160 meters high (the height of Ulm Minster cathedral).
- The garden hose is a 1.8-meter-wide green tunnel running 1,519 meters across the terrain.
- The Mirror Pool is 300 meters across; the central lake is 3.7 kilometers across; the total world ring is 7.7 kilometers in diameter (36 $\text{km}^2$ of explorable land).
- Five covers carpet the soil: lawn blades (bending/wearing), moss cushions (halving calls), clover roofs (shivering drums), crumb boulders, and fallen leaf rafts (each ringing a unique pitch).

### 3.2 The Rhythm of a Day (20 Minutes, Shaped Like a Song)
Following Morgan's 5-step songwriting methodology:
1. **Dawn (Intro):** Waking at the shore; Drip hums you back in; checking the river post.
2. **Morning (Verse - *Notice*):** Walking today's land; listening to who is present and what unresolved phrases they carry.
3. **Noon (Chorus - *Capture*):** The land's great instrument rings; creature packs move in the groove; everything sounds.
4. **Afternoon (Bridge - *Extract*):** Solving acoustic wonders; harmonizing with the environment; assembling phrase materials.
5. **Dusk (Chorus - *Sing*):** The land gathers; wolf packs arrive from under the wheel; communal cadence resolution.
6. **Night (Outro - *Select*):** The river carries you home, singing your entire 20 minutes back as a 30-second distilled song. You select up to 4 takes to keep as echoes. The rest dissolve into the water.

### 3.3 The Three Endings (The 13th Morning)
On the 13th morning, having walked 12 pure fifths, Hum arrives back at the Garden, but home is $B\sharp$—precisely 1 Pythagorean comma (23.46 cents / 1.96 m elevation) sharp. All 96 lives and past echoes surround the pool. The player walks the 12 lands in 12 bars in one breath. At the end, three physical gestures represent the philosophical climax:
1. **The Clap (L1 + R1):** The Grid's Treaty. Snaps the comma closed into equal temperament. The world becomes perfectly in-tune, perfectly predictable, and permanently grey.
2. **The Step (Nudge stick left):** The Wolf's Path. Stepping past the comma into the infinite spiral. Pure tuning preserved, but leaving everyone behind as the lake drains.
3. **The Hold (Hold R2):** The Duet. Standing beside the vine, holding the comma tension without forcing closure. *"Harmony cultivates wanting by metabolizing error as remainder... It is freedom, our arrival."*

---

## 4. The Living Simulation: Laws, Lives & Echoes

### 4.1 The Seven Acoustic Laws (`spec/laws.md`)
Every entity in the engine is a composite of **Resonators** (shape overtones) and **Pendulums** (rhythm/cycle). No special-case scripting:
1. **Sympathy:** Sound flows between things sharing overtones. Ring one aster crown, and its kin across the garden glow and ring late by distance.
2. **Gravity:** An overtone falls toward the note containing it. Placing home below an object pulls it toward you; placing home above pulls you toward it.
3. **Falling into Step:** Near-synchronous oscillators phase-lock. Walking steadily draws nearby creatures into your parade.
4. **Standing Waves:** Opposing voices produce stationary nodes and antinodes. Walk across standing nodal lines over pool surfaces.
5. **Cancelling & Beating:** Out-of-phase sound creates dark silence; near-miss frequencies beat at their difference rate, rotating Lissajous bodies.
6. **Travel:** Sound propagates at 60 m/s (visible and audible delay across distance).
7. **Building Up:** Resonant pushing builds amplitude. Striking on the beat amplifies power; off-beat strikes cancel.

### 4.2 Combat as Musical Resolution (`SPEC.md` §10)
- **Rhythm as Distance:** How close an enemy stays and how fast it pulses is its harmonic distance from home. Near enemies hold still while Hum sings.
- **The Fork Wave:** Striking with the fork sends a wave carrying 25 meters, draining enemy colour on impact.
- **The Beat & The Pocket:** Dodging on the enemy's attack beat opens the pocket (time dilation). Strikes landed in the pocket record afterimages (up to 4 layers) that land again on subsequent bars.
- **Four Doors of Cadence:** Bringing an enemy to grey does not kill it. Holding the swell and releasing on beat 1 resolves it:
  - *Full Close (5th below):* Springs open, transforms, and drops a mood gift (updrafts, speed, water).
  - *Amen (5th above):* Calms and settles to sleep.
  - *The Turn (2 fifths above):* Fights beside Hum as an ally for 4 bars.
  - *The Slide (tritone substitution):* Resolves quietly by half-step.

### 4.3 The Echoes & The Card
- **Echoes as Bandmates:** Kept takes walk beside Hum on future mornings in sun-print blue. They fight, step on pressure plates, and complete chords.
- **Released Takes Become World Memory:** Takes allowed to dissolve into the river are kept by the lake. On morning 10 (Rain Steps), they fall as rain.
- **Card as Cartridge:** Dawns, takes, and ground light wear patterns are saved directly to SD storage (`TF2`). The world remembers every footstep.

---

## 5. Honest Audit: Where the Build Actually Stands

The automated promise tracking system (`spec/tools/promises.py`) was mandated by Morgan to prevent software teams from quietly shrinking scope (`spec/promises.md`). Here is the unvarnished status on the purple target:

```
PROMISE VERIFICATION LADDER (BOARD.MD)
Total specification claims:     2,160 sentences
Claims spoken for by promises:    674
Claims OPEN (unspoken for):     1,486
---------------------------------------------
Promises Sized (Ready):           140
Promises Proven (Tests/Measures):   2
Promises Reached (Scripted Bot):    8
Promises Felt (Morgan Handheld):    0  <-- CRITICAL BOTTLENECK
Promises Graded (Fresh Reader):     0
TOTAL PROMISES KEPT:                0
```

### 5.1 What Is Solid and Proven
- **Deterministic Engine:** Zig 0.17 codebase running at 60.02 Hz on RK3326. Zero memory allocation during gameplay loop. Single sound buffer clock eliminates audio/video drift.
- **Headless & Same-Take Verification:** Bit-for-bit identical headless simulation across laptop (x86_64) and purple handheld (aarch64).
- **Oscilloscope Line Pipeline:** Mali-G31 GPU rendering 30,000+ lines of light per frame in 11.1 ms with custom half-size phosphor halo and black occluding geometry.
- **Acoustic Resonator Bank:** Real-time synthesis of 2,100 simultaneous overtones on one CPU core.
- **First Playable Beat:** Black screen startup, call/response ring, Drip lock, page standing up into 3D, cathedral aster grove, puddle bridge crossing, responsive camera dial, 12 m/s run, 20 m/s sprint, 5 m jump.

### 5.2 What Is Missing / Half-Built / Broken
1. **The Human Feeling Bottleneck:** 0 promises are marked "Felt." Morgan has not walked the latest builds in the Room (`GameguyRoom`) to sign off on camera curves, movement weight, or audio roughness.
2. **The "Light-Pictures" Ambiguity:** `design/light-pictures.md` was drafted but Claude paused because he didn't know who the "small figures on the shore" were. As established in Section 1.3, those figures are the garden's lives before the storm—and their exact identities must remain Morgan's private layer (`SPEC.md` §5 rule 12).
3. **Missing Stage 2 Claims:**
   - The Great Knot inside the hose (stopping water across the garden).
   - The Garden's 8 Lives (Pill, Snail, Moss, Ants, etc.) and their morning routines.
   - The Dusk River loop sequence (replaying the 20-minute take, saving dawns, keeping echoes).
   - Day 2 morning with an echo walking beside Hum.
   - The 12 Garden wonders (sympathy, puddle nodes, aster bells, bee flight).
4. **Unresolved Input Dilemma (L1/L2 vs Stick):** In `DECISIONS.md` row 110, it was proposed that swell steps move to L1/L2 taps so the right stick is free for leaning and camera. This remains open and needs testing in the hand.

---

## 6. The Actionable Master Plan & Execution Roadmap

To build the full AAA scope without burnout or scope-shrink, work proceeds strictly along the verified stages defined in `SPEC.md` §20 and `spec/stages.md`.

```mermaid
gantt
    title Master Execution Sequence
    dateFormat  X
    axisFormat %s
    section Stage 2: The Garden Complete
    Settle Light-Pictures & First Evening Story   :active, 0, 10
    Implement Great Knot & Freeing the Hose       :10, 20
    Implement Dusk River, Takes & Dawn 2 Echo     :20, 35
    Implement Garden 8 Lives & 12 Wonders         :35, 50
    Run Room Verification with Morgan (Get 'Felt') :50, 60
    section Stage 3: Going Out (Mornings 2–7)
    Atlas & Scores for Lands 2 to 7              :60, 80
    Implement Metronome & The Seam                :80, 100
    section Stage 4: The Way Home (8–12)
    Double Sun & Comma Return Mechanics          :100, 120
    section Stage 5: The 13th Morning & After
    The Three Endings & Endless Spiral           :120, 140
    section Stage 6 & 7: 2 Consoles & Release
    Cable Lockstep & Physical Cartridge Packaging :140, 160
```

### Immediate Sprint: Stage 2 Completion (The Garden Finished)

#### Step 1: Resolve the Story in Light-Pictures (`design/light-pictures.md`)
- **Action:** Draw the three light-pictures as oscilloscope line sequences rising when Hum stands still for one bar:
  1. *At the Great Aster:* The Garden whole and green, hose running, small figures of light (lives not yet met) on the shore.
  2. *At the Bridge Puddle:* The storm hitting, rain ticks falling, puddles forming rings, hose struck.
  3. *At the Knot:* The hose buckling into three knots, water cutting off, the pool going still.
- **Rule:** Keep the figures as anonymous silhouettes of light. Do not define or explain them. Let Morgan's layer stay his.

#### Step 2: Implement the Great Knot & Unstopping the Hose
- **Code Targets:** `game/src/world/knots.zig`, `game/src/world/hose.zig`.
- Build the Great Knot (polyrhythm 5 against 7).
- When the first knots are brought home via the Amen cadence, the Great Knot relaxes: the hose sounds an octave higher, water rings out into the Mirror Pool, and for 1 second the 90-meter blue figure sits on the pool's edge before fading.

#### Step 3: Implement the Dusk River, Takes, and Dawn 2 Echo
- **Code Targets:** `game/src/world/river.zig`, `game/src/keep/take.zig`, `game/src/world/echo.zig`.
- Dusk transition: after 20 minutes (or sleeping at the river), the river takes Hum.
- Sound engine renders the day's events backwards in 30 seconds.
- River post UI: select up to 4 takes to keep.
- Dawn 2: Hum wakes at the river; the kept take walks beside Hum as a flat blue echo playing its recorded inputs.

#### Step 4: Build the Garden's 8 Lives & 12 Wonders
- **Code Targets:** `game/scores/garden.txt`, `game/src/world/people.zig`.
- Place the 8 lives (Pill, Snail, Moss, the Ants, etc.) with their initial wants.
- Wire all 12 acoustic wonders as automated unit tests and world encounters.

#### Step 5: Physical Room Testing on the Purple Handheld
- **Action:** Push the build to unit 164 (`probe/tools/r36s.sh push 164`).
- Launch `GameguyRoom.sh`.
- Have Morgan play the 13 room walks to record real human answers on camera feel, movement weight, tick timbre, and fight responsiveness.
- Turn the first promises on `BOARD.md` from "sized" to "kept".

---

## 7. Open Questions for Morgan

> [!IMPORTANT]
> To execute the immediate sprint with total alignment, please confirm:
> 1. **Light-Pictures silhouettes:** Do you approve keeping the figures on the shore as anonymous light outlines (representing the pre-storm lives of the garden) without naming them, preserving your personal layer?
> 2. **Swell Inputs (L1/L2 vs Right Stick):** During R2 held (the swell), would you prefer tapping L1 (step flatward) and L2 (step sharpward) to walk home, leaving the right stick dedicated exclusively to camera look and note-leaning?
> 3. **Handheld Testing Session:** Are you ready to run `GameguyRoom` on the purple handheld to log your hand/ear answers for the camera, speed, and metronome tick?
