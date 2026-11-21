# Review: Claude's status report and the light-pictures draft

## What this document is

Morgan asked for a fresh eye on two things:
1. Whether Claude's status report shows full understanding of the project's state.
2. Whether `design/light-pictures.md` tells the right story, and who the small figures on the shore are.

This plan lays out what I found after reading the specification, the progress, the decisions, the design canon, and the light-pictures draft. It's a review, not a code plan — there's nothing to build yet.

---

## 1. On Claude's report: what it gets right, what it misses

### What it gets right

The feature list maps accurately to what's in `PROGRESS.md` and `DECISIONS.md`. Specifically:

| Claude says | The record says |
|---|---|
| Right stick always wins the camera | `DECISIONS.md` row 142: "the view's own lifts yield whenever the right stick is held" |
| Running 12 m/s, sprinting 20 m/s | `DECISIONS.md` row 142: "the run is a fifth of the speed of sound (12 m/s), the sprint a third (20 m/s)" |
| Jumps 5 m | `DECISIONS.md` row 142: "the jump is 5 m in a second" |
| Right face tap = 6 m dash | `DECISIONS.md` row 142: "a dash of 6 m in 0.15 s" |
| Strike's wave reaches 25 m | `DECISIONS.md` row 143: "out to 25 m, weaker with distance (down to 0.4 of it)" |
| Fight mechanics from GameguyPage | `DECISIONS.md` row 144: "the page toy's rules, made the world's law" |
| Drip leads after the place stands | `DECISIONS.md` row 145: "once the place stands, Drip hops off Hum's head over the coil" |
| R1 = mood wheel (circle of fifths), R2 = swell | `SPEC.md` §9, `DECISIONS.md` row 139 |
| L1 voice wheel not built yet | `DECISIONS.md` row 110: "Proposed, his call" — still waiting on Morgan |

The 99-tests-pass and "scripted evening plays through" claim is consistent with the codebase structure (test infrastructure exists, the scripted player is a core verification tool).

### What it misses or skims

> [!IMPORTANT]
> The report reads like a **changelog**. It doesn't engage with the design's own questions, the promise system's current state, or what Morgan asked for and hasn't answered yet.

Specific gaps:

1. **No mention of promises.** The board (`BOARD.md`) shows **0 promises kept**, 674 spoken for, 1,486 still unspoken. Stage 2 has 658 claims all spoken for but none kept. The report doesn't say where the stage stands against its own guard. This matters because `SPEC.md` §20 says a stage isn't done until every claim it owes is kept.

2. **No mention of what's waiting on Morgan.** The room has walks nobody has answered. The ear test hasn't been taken. The room walks for the new features (camera, movement, the wheels) haven't been played. Morgan's first evening showed problems that led to this round of work — the report doesn't ask what he thinks of the fixes.

3. **The "still to do" list is incomplete against the stage.** The report names three items:
   - songbook pages for the dash and the strike's wave
   - three knots on a row of fifths + packs
   - L1 voice wheel

   But `PROGRESS.md` rows 72–75 list many more open items for the work already begun:
   - the GPU's remaining late frames on the purple
   - lock-on with L2
   - the lean in two phases
   - the hose's rail
   - blades bending and wearing paths, moss and low crumbs to stand on, leaves tipping
   - every thing's shape against home and the preview re-forming shapes
   - the swell's steps on L1/L2 (Morgan's call)
   - the ground's light fading while the lake is low
   - fact lines in the log, one hands reader
   - the ground picture's extent worked out with a header
   - sprint and glide by need (teaching)
   - Morgan's hands on it (the room walks)
   - a first play by JJ

4. **"On two wheels" is imprecise.** The report says "R1 held is the mood wheel, and it is the circle of fifths." More precisely: R1 opens the wheel, the place folds toward the page, time thickens, and the right stick steers among wedges. It's not a held-and-steer in the usual sense — it's a mode change. The distinction matters because the whole design hinges on R1 and R2 feeling fundamentally different (`DECISIONS.md` row 110, row 139). The report doesn't convey that R2 (the swell) is *playing in time* while R1 is *stopping to think*.

5. **No engagement with the design questions the new features raise.** The fight mechanics now come from the page toy's rules — but the page toy left three things untested: "three creatures on a run of fifths walked home in one swell, packs in the garden" and the unresolved question of whether matching home to enemies is a chore. The report lists the first two as "still to do" but doesn't name the design risk.

### My read

Claude's report is accurate as a list of what was built. It is not a design review. The concern that "he didn't quite take the time to read enough" seems warranted: the report doesn't reflect the depth of `SPEC.md` §20–21's verification ladder, the promise system's actual state, or the open design questions that the specification and the decisions document carefully track. A builder who fully grasped the situation would report against the stage's own claims, not just the features.

---

## 2. On the light-pictures: the story and the figures

### The draft

[light-pictures.md](file:///home/moth/Projects/gameguy/design/light-pictures.md) proposes three pictures, drawn as the oscilloscope's beam draws, each rising when Hum stands still at a place for a bar:

1. **At the great aster's foot:** the garden before the storm — whole, green, water flowing, small figures of light along the shore.
2. **At the bridge puddle's edge:** the storm — rain as falling ticks, puddles opening as rings, the hose struck and jerking.
3. **At the hose's knot:** the hose tangling into the three knots, water stopping, the pool going black.

### Is this the right story?

> [!TIP]
> The three pictures are a cause-and-effect sequence: **the garden was whole → a storm broke it → the hose knotted and the water stopped.** This is the right spine for the garden's backstory.

It aligns with:

- `SPEC.md` §4: "The world is a garden after a storm"
- `SPEC.md` §6.1: the knotted hose, the knots that stumble, the water that runs when they open, the blue figure that appears for one second when it does
- The worksheet's core image: "a pool, a knotted hose, a sapling and a fly on the knee"
- `design/the-whole-game.md`: "asters, the Mirror Pool, the knotted hose"
- The whole design's principle (§5 rule 6): "nothing on the screen that isn't in the world" — these pictures *are* in the world, they're memories the garden holds

The story is small and right. Three pictures is the right number: beginning, catastrophe, aftermath. Each is placed at the thing it's about (the great aster shows the whole garden, the puddle shows the rain, the knot shows the knotting). The form — faint lines of light that rise and sink — is exactly the oscilloscope-beam drawing style (`design/drawn-in-light.md` rule 1: "if it sounds, it shines"). These are memories the garden is singing back.

### What to consider

**The pacing.** The draft says each picture "plays once in about eight seconds." That's good — it's shorter than a verse, long enough to read. But the player finds these by standing still for a bar (about 2 seconds at the garden's tempo). That means the garden rewards stillness with story. This is exactly what the game's first evening needs: Morgan's first play had him running past everything. These pictures are reasons to stop.

**The order.** A player walking Drip's path (great aster → bridge puddle) sees pictures 1 and 2 before meeting the knots. Picture 3 is at the knot itself, so the player sees the knotting just before or after the first fight. That's the right order: you see what was lost, then what broke it, then you face the thing that broke it. The story and the gameplay converge at the same place.

**What's not in the story.** The draft deliberately leaves out: who made the garden, why the storm came, and what the small figures were. This is correct. `SPEC.md` §5 rule 12: "Morgan's own layer stays his." The light-pictures show *what happened*, not *why* or *to whom*. The blue figure on the pool's edge (`SPEC.md` §6.1, `DECISIONS.md` row 125) appears for one second when the hose opens — that moment is earned by gameplay, not given by exposition.

### Who are the small figures on the shore?

> [!IMPORTANT]
> This is Morgan's question to answer. But here is what the design says about what they *could* be, and what matters about the choice.

What the specification says about figures in the garden:

- **The blue figure on the pool's edge** (`SPEC.md` §6.1, `DECISIONS.md` row 125): "at the garden's size, as a person sits by a garden pond: about ninety metres to the top of its head... Lines only, two rings for a head and nothing in them; there at once and gone at once, for one second." Who it is is Morgan's (`SPEC.md` §17).
- **The Garden's eight lives** (`spec/people.md`): Pill, Snail, Moss, the Ants, and others — small creatures who keep their own cycles.
- **The vine** (`SPEC.md` §11): "blurred and doubled out of tune, a body in tune" — present in the garden on mornings 1, 5, 9, 13.

The small figures in light-picture 1 are described as "lives, not yet met" — which means they're the garden's inhabitants *before the storm*. This is the garden in its old state, when everything worked and the water ran. The figures could be:

1. **The garden's own eight lives, as they were.** This is the simplest reading. Before the storm they were whole, along the shore, near the water. After, they're scattered and cycling.
2. **Figures left blank for Morgan.** The draft names them "small figures of light" and nothing more. Like the blue figure on the pool's edge, like who sat in the chair at the Porch, these could be Morgan's to fill — people from his own layer, placed in the garden's past.
3. **Echoes of the player's own future.** This is the boldest reading and probably wrong for a first picture the player hasn't earned. But `drawn-in-light.md` rule 4 says "afterglow is memory," and in the game's logic, the garden remembers everything that happened in it.

**My recommendation:** leave the figures unnamed in the design. Let them be "small figures of light along the shore" — recognisable as *lives*, not recognisable as *specific* lives. When the player has helped the garden's eight, they can come back and see the picture again and perhaps now recognise them. If Morgan wants to place his own figures there (the vine, someone from his life), the picture is open to it without being committed to it.

This keeps `SPEC.md` §5 rule 12 (Morgan's layer stays his) and §5 rule 6 (nothing on screen that isn't in the world).

---

## 3. What needs Morgan's word

| question | why it matters |
|---|---|
| Are these three the garden's story? | The design won't be drawn until he says yes |
| Who are the small figures? | His call per §17 — they're in the same category as the blue figure and the chair |
| Has he played the new build on the purple? | The room walks are waiting; 0 promises are kept; the fixes to camera, movement, and fights need his hands |
| Does the swell's step move to L1/L2? | `DECISIONS.md` row 110: "proposed, his call" — this changes the hands fundamentally |

---

## User Review Required

> [!IMPORTANT]
> **This is a review, not a build plan.** There are no code changes to make. The two actions are:
> 1. Tell Claude what you think of the light-pictures (the story is sound; the figures are yours to name or leave open).
> 2. If you agree with the gaps I identified in Claude's report, consider asking Claude to report against the promise board and the stage's open items rather than just listing features.

## Open Questions

> [!CAUTION]
> **The room walks are accumulating.** The board shows 0 promises kept, 0 felt by Morgan. The camera, movement, fights, and guidance have all been rebuilt — but until someone plays them in the room and answers the questions, they aren't proven. This is the verification ladder's bottleneck.

> [!IMPORTANT]
> **L1/L2 for the swell's steps** is still proposed, not decided. Claude's report says "the L1 voice wheel isn't built yet" but doesn't surface the deeper question: are the swell's steps moving off the right stick? This changes how every fight plays. If Morgan decides yes, the fights that were just shipped will feel different again.
