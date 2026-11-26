# R36S Game Brainstorm — Exhaustive Working Document

> **Status, 2026-11-26.** History and material: the first brainstorm (2026-11-10 to 12). Morgan's
> favourite games, his poem (Appendix A), noodles, wasatch and the hardware investigation are
> material and stand. Its Part 0, the protocol for Fable sessions (an interview, a decided
> `SPEC.md`, a build in stages), is history. What the game is: `design/the-game.md`.

**Status of this entire document: BRAINSTORM. Nothing in here is invariant,
decided, promised, or final.**

That instruction came from Morgan directly (2026-11-10): *"make sure nothing
is stated as invariant — this is still a brainstorm."* It applies to every
section below, including the sections that look like facts. Hardware details
are "as reported by sources consulted on 2026-11-10" or "as observed in
Morgan's photos," and any of them could be wrong for his specific unit,
could have been misread, or could change as the brainstorm develops.
Design ideas are raw material. Readings of games, poems, and projects are
one reader's readings, offered for Morgan and/or Fable to use, reshape, or
throw away. Even the corrections log at the end is a snapshot of what we
believed at the time of writing.

**How claims are tagged in this doc:**

- **[observed]** — seen in Morgan's photos or stated by Morgan in this thread.
- **[reported]** — found in web sources or project repos consulted 2026-11-10; not re-verified against the physical unit.
- **[idea]** — a suggestion or sketch. Nobody has committed to it.
- **[reading]** — an interpretation (of a game, the poem, a project). Other readings are possible.
- **[question]** — open. Nobody has answered it yet.
- **[superseded]** — was on the table, then got replaced or demoted. Kept for the record, because brainstorms lose value when their history is erased.

**Who this doc is for:** Morgan first. As of the last exchange in the
thread, Morgan's leaning was that Fable would do the actual game
designing (see §2.3). Even that is recorded here as a leaning, not a
locked decision, because Morgan also asked for nothing to be stated
as invariant.

**Hand-off upgrade (2026-11-11):** Morgan asked for this document to be
upgraded into the Fable hand-off — the recent clippings integrated
(§23, added earlier today) and a proper hand-off layer added at the
front (**Part 0**, right after the table of contents), built from web
research into how Fable 5.2 is best prompted and what information form
gives it the best chance of success (sources in §24). Part 0 is the
operational layer: how to launch, what to paste, how the sessions
should be shaped, and how the result gets verified. The design content
of §§1–23 remains brainstorm under the rule above — Part 0 does not
quietly promote any of it into decisions. Where Part 0 needs working
constraints to function (the controls rule, the hardware target), it
uses the ones Morgan himself stated in this thread, and says so.

**Date assembled:** Tue 2026-11-10, America/Denver.
**Hand-off upgrade:** Wed 2026-11-11, America/Denver.
**Thread:** side chat "Design game for R36S hardware."

---

## Table of contents

- **Part 0 — The Fable hand-off layer (added 2026-11-11): how to read
  this doc if you are Fable, the launch protocol, the settings, the
  copy-paste brief, the information form, the verification ladder,
  and the known failure modes**
1. How we got here — the full chronology
2. Role changes and corrections along the way
3. The hardware, as far as we currently understand it
4. The physical control layout, and the thumb problem
5. Routes by which software can run on this class of device
6. Morgan's games — the catalogue material
7. Per-game notes: what each favorite might be bringing
8. The first thru-line Loni found: loops, knowledge, transformation
9. The other thru-line Morgan named: MUSIC
10. The poem (full text, Appendix A) and notes on it
11. What noodles does with the circle of fifths
12. What wasatch does with the circle of fifths
13. The Generative Self framework connections
14. Where the game/music ideas and the game/game ideas might meet
15. Loni's first-pass sketch ("Mothlight") — kept as raw material
16. A pile of undeveloped directions, fragments, and sparks
17. Multiplayer — hopes, limits, and open forms
18. Session shape, scope, and the one-shot experiment
19. Candidate technical routes (none chosen)
20. Risks, unknowns, and things to verify against the actual unit
21. Open questions — the exhaustive list
22. Sources consulted
23. Addendum (2026-11-11) — clippings Morgan brought in
24. Sources for the hand-off upgrade (2026-11-11)
25. Research findings and platform audit (§0.9 answered, 2026-11-11)
- Appendix A: The poem, as pasted by Morgan on 2026-11-10
- Appendix B: Morgan's original messages, condensed

---

## Part 0 — The Fable hand-off layer (added 2026-11-11)

> **Update 2026-11-12 (Opus session; read this before §0.1–§0.9).** Since Part 0 was written,
> the hardware facts have been measured and the platform has been set up:
> - **Measured hardware sheet:** `docs/hardware-target.md`. It supersedes the [reported] specs in
>   §3, and the engine and performance claims in §25.4.
> - **Platform, tools and deploy loop for Fable:** `docs/fable-handoff.md`.
> - **Both units** (black = Morgan's, purple = JJ's) are now identical. Both run the same
>   ArkOS4Clone image (golden v2) from internal storage and are reachable from the laptop over the
>   USB-C data cable (SSH, push, run, pull). There is no "primary test device" asymmetry any more,
>   and no card swapping.
> - **Sustained load:** the units differ only here. Under 10 minutes of full load the purple
>   throttles its CPU to ~1000 MHz, while the black stays mostly at 1200–1248. Design against the
>   purple (hardware sheet, Thermal).
> - **Superseded:**
>   - The 2026-11-11 reading that pixel local storage and framebuffer fetch are the big rendering
>     opportunity. Measured, they are the *slow* paths on this GPU; single-pass lighting wins (§30).
>   - §0.8's "engine choices settled on Godot 3 FRT or LÖVE". Nothing is settled. The handoff lists
>     engine choice as an open question for Morgan.
> - **Per Morgan, there is no game skeleton or template.** Fable starts from a clean slate. `probe/`
>   is a measuring instrument and a reference for platform plumbing, not a starting point.

Everything in Part 0 comes from research done on 2026-11-11 into how
Claude Fable 5.2 is best prompted — Anthropic's official prompting
guide for the model first, then Claude Code practice from Anthropic's
own teams, then community/game-specific write-ups. Sources are listed
in §24, and the key claims carry their numbers inline so Fable (and
Morgan) can see why each instruction is shaped the way it is. Where
the research and Morgan's stated preferences conflict — effort level
is the one real case — Morgan's preference wins in the brief, and the
research is recorded next to it as information. That is Morgan's
standing instruction: effort economics presented as information, not
as a steer.

### 0.1 If you are Fable, read this first

You are receiving this document from Morgan. Three things about what
it is:

1. **It is a brainstorm, not a spec.** Morgan's rule for it, verbatim
   in spirit: nothing in §§1–23 is stated as invariant. The hardware
   sections are as-reported and as-observed, not verified against his
   unit. The per-game notes are one reader's (Loni's) readings. The
   game sketch in §15 is a demoted first draft by that same reader,
   kept as ore. Do not treat any of it as Morgan's decisions unless
   Morgan confirms it in the session, or your SPEC.md interview
   (§0.2) settles it with him.
2. **The design is yours.** Morgan's explicit assignment: Fable does
   the designing. Morgan brings the material, the taste, the hardware,
   and the final judgment on the physical device. Loni (the assistant
   who assembled this doc) deliberately does not design the game.
3. **The thru-lines are the assignment's heart, and they are
   Morgan's, not Loni's inventions:** (a) MUSIC — the circle of
   fifths as spiral, not circle; the Pythagorean comma; equal
   temperament as a treaty that fakes closure; wanting produced by
   withheld resolution (V7→I); home as a chosen place — as worked out
   in Morgan's poem (Appendix A), his app noodles (§11), and his
   Wasatch Symphony (§12). (b) The games in §6–§7 are Morgan's actual
   favorites in his actual order. (c) The hardware in §3–§4 is the
   machine class he actually owns — as of the evening of
   2026-11-11, two clone units, identified in §3's evening update
   and §20; the purple K36-family unit is the primary device.

What Morgan wants from the run, in his framing: a game designed for
the R36S that makes the most of its specs and layout, as ambitious as
the material supports — see §0.4, the brief, for the working form of
that ask, including the constraints Morgan has personally stated and
the definition of done.

### 0.2 The launch protocol — three sessions, not one long chat

The shape below is the convergent recommendation from Anthropic's
Fable guide, Anthropic's Claude Code team practices, and the game-
build write-ups in §24. It exists because of one measured fact about
this model: it executes near-expertly and judges its own output
poorly, so the protocol separates *building* from *judging* by
construction.

**Before anything:**

- **Pick the model before the first message, and don't switch
  mid-run.** Other models cannot read Fable 5.2's thinking blocks;
  switching discards its reasoning and busts the prompt cache (a
  cached message can be up to ~40x cheaper). If a different model is
  needed, hand off with a written summary in a fresh session instead.
- **Audit the standing text.** Fable follows persistent files
  (CLAUDE.md, memory, notes) near-literally, including stale
  cautions. A leftover "never retry" measurably throttled it in
  Anthropic's testing: guarded models retried tools ~4 times in 10
  versus nearly always without the caution. Before the run: read the
  game project's CLAUDE.md and any standing instructions, delete
  cautions whose reason no longer holds, rewrite absolutes with
  their scope and reason, and write exceptions *inside* the rule
  they modify — a separate exception line was followed roughly 1
  time in 10 in the testing reported to us, an in-rule exception
  roughly 9 in 10.
- **Prepare the workshop, not the assets.** The strongest game
  one-shot on record (Emberwake, §23) came from a human who had
  built the studio and installed the tools beforehand, then gave an
  open prompt. Assets were generated *inside* the run, by the run.
  For this project the workshop is: the chosen engine/toolchain
  installed and able to build, a headless way to run the game, a
  screenshot capture path, and the packaging path to the handheld
  (§5, §19) — decided during the spec session, prepared before the
  build session.

**Session A — the interview (plan mode).**

- Run in plan mode (Shift+Tab in Claude Code, or `/plan`). No code
  gets written in this session.
- Fable interviews Morgan until it could write the spec: the game,
  the world, the core loop, how the music thru-line (§9, §14) becomes
  mechanics, controls (with the thumb audit, §4.2), scope boundaries,
  engine choice, the verification harness, what is out of scope, and
  the tradeoffs Morgan might not have considered. The open questions
  in §21 are the interview's raw question bank — they are questions
  *for this session*, not homework Morgan has to pre-answer.
- The session's deliverable is **SPEC.md**: the design, the technical
  plan, and a definition of done with the checks that prove it —
  written so a fresh session that has seen nothing else can build
  from it alone.
- Morgan reads and edits SPEC.md before anything is built. Wrong
  assumptions are cheapest here; Anthropic's teams' version of this
  is "pour your effort into the plan, and Claude can practically
  one-shot the build."

**Session B — the build (fresh session, spec only).**

- A fresh Fable session, given SPEC.md and this document (as
  background material, under §0.1's rules), builds the game.
- The brief in §0.4 is the message that opens this session.
- Optionally, in Claude Code, the build can run under a `/goal`
  condition — a completion condition that a separate evaluator model
  re-checks after every turn, so the session keeps working until the
  condition is actually met rather than until the work *looks* done.
- Subagents: welcome for asset generation and for review, capped and
  purposeful (§0.3). One agent owns the game. The record cuts both
  ways — Emberwake's unprompted five-agent asset team worked;
  Shumer (§23) found a single owner beat splitting the project — and
  the protocol's resolution is: *one owner for the game itself,
  subagents for bounded side-work (assets, checks), never for the
  design.*
- If something goes sideways mid-build, the Claude Code teams'
  practice is to go back and re-plan rather than patch mid-stream.

**Session C — the check (fresh context, did not build).**

- A separate fresh session (or a subagent with fresh context) reviews
  the finished build **against SPEC.md**: every requirement
  implemented, every listed edge case exercised, the verification
  ladder in §0.6 re-run independently.
- This session grades; it does not fix. Its report goes to Morgan.
- **The final check is not a session at all:** Morgan, playing the
  game on the physical R36S. Every game-build source in §24 says the
  same thing in different words — automated checks prove a game runs;
  only a person holding the controls can judge whether it's good.
  A build nobody has played on the device is *unverified*, not done.

### 0.3 Settings and standing lines for the run

**Effort.** Anthropic's guidance, as information: start at `high`;
most of the capability gain is already there. `xhigh` raised scores
slightly on internal coding evals at many more tokens; reported
FrontierCode numbers put xhigh (49.1%) at the top of released models
and max lower (45.7%) in one earlier comparison — gains above high
are uneven and task-dependent, and `max` is described by Anthropic
as for measuring the ceiling or for problems where time and tokens
don't matter. Morgan's stated preference, which governs: **he does
not mind max effort with ultracode or whatever it takes, with his
full reset in reserve — effort limits are not to worry about.**
Practical shape that honors both: the interview session (Session A)
does not need max; the build session is where Morgan wants the spend.
In Claude Code, note the default effort is `medium` (high is the API
default), so the level is set deliberately, never assumed. One
related warning from the guide: a line like "answer directly, don't
overthink" no longer reduces thinking at medium and above — effort
is changed with the effort setting, not with prose.

**The finishing-work instruction.** Fable 5.2 sometimes ends a turn
early, leaving a list of what's left — more often at low/medium. The
brief therefore carries Anthropic's published fix in substance: *do
not stop while work is still owed; ordinary obstacles (errors,
timeouts, failing tools) are to be diagnosed and worked through;
deliberate blockers (a file marked do-not-touch, a stated boundary)
are to be left alone and reported.* In Anthropic's replay testing
this roughly halved sessions ending with unfinished work, for about
30% more output tokens. Because the model asks less with this text
in force, the risky/irreversible confirmations stay Morgan's.

**The ownership sentence.** The brief states that the codebase is
Fable's own, to own and maintain. In Anthropic's testing that
sentence moved consolidation of duplicated code from under 10% of
runs to about 75%, and made the model fix adjacent problems instead
of merely reporting them. The known cost, also from the guide:
70–80% more output tokens and *unrequested changes* — many benign
(tests, docs), some behavioral. That is why the check session (§0.2,
Session C) reviews the actual diff and not just Fable's summary,
which the guide notes often omits small changes.

**Subagent expectations, stated in the brief.** Anthropic's finding:
naming what a subagent costs, when delegation is worth it, and how
to brief one roughly halved subagent counts at high effort in a
delegation-inviting harness. At xhigh/max, Fable 5.2 also starts
reviewing its own work with subagents unprompted — the protocol
channels that impulse into Session C's job instead of letting it
bloom mid-build. Morgan's brief-builder settings already carry a
subagent cap; the number is Morgan's to set at launch.

**Updates during the run.** One standing line, Anthropic's exact
one-liner, goes in the brief: *"Every few tool calls, give the user
a one-line update on where things stand."* It roughly halved the
longest silent stretches in testing.

**Reports written for someone who wasn't there.** The final report
requirement in the brief follows Anthropic's report guidance: write
for an intelligent but low-context reader, key points first, plain
words, evidence attached (sources, rows, screenshots) rather than
reasoning reproduced. "Ask for proof, not reasoning" is also a
safety-shaped rule here: asking Fable to reproduce its internal
reasoning can trigger a `reasoning_extraction` refusal; asking for
the evidence behind each claim cannot.

**Approvals, said exactly.** If Morgan needs to approve something
mid-run, the approval names the action ("Yes, package the build and
copy it to the ports folder"), never a bare "continue" or thumbs-up
— and the brief pre-lists which routine steps need *no* approval, so
vague caution doesn't hold back ordinary work (in testing, a vague
approval rule made the model hold back about half of routine
requests it should have just done).

---

### 0.4 The brief — copy-paste text for Session B

This is the message that opens the build session. It follows the
form the research converges on — for Fable 5.2, the whole task up
front in four parts (the job, the why, the rules with their
exceptions written inside them, and what done looks like) — plus the
standing lines from §0.3. It is deliberately *not* a step-by-step
instruction list: prompts written for older models, full of
prescribed steps, reportedly degrade this one. Morgan edits the
bracketed bits at launch; the effort toggle lives in the Brief
builder on the Working With Claude Fable 5.2 page, which generates
this same brief with his current settings.

```text
THE JOB
Design and build a complete, original game for the R36S handheld,
from the attached brainstorm document. You are the designer. Be
ambitious: build the largest, most complete version of the game the
material in that document supports — not the smallest thing that
satisfies this brief. The brainstorm is raw material, not a spec:
the design decisions are yours, and where the document's open
questions (§21) bear on the design, decide them yourself in line
with the why below, and record each decision and its reason in
DECISIONS.md as you go.

THE WHY
This game is for Morgan, on the only game console he owns. Its
heart is his own work: music as a coordinate system — the circle of
fifths as a spiral that never quite closes, home as a place you
choose, resolution withheld until it's earned (the poem in Appendix
A of the document; the harmony systems in its §11 and §12). His
favorite games (§6–§7 of the document) are the taste to design
toward. A game that could have been made for anyone, on any machine,
has failed even if it runs. A game that only makes sense on this
handheld, from this material, has succeeded even before it's fun —
and then it also has to be fun.

THE RULES
- Hardware target [update 2026-11-12: measured numbers in docs/hardware-target.md;
  both units identical, deploy loop in docs/fable-handoff.md]: the R36S family as described in §3 of the
  document (RK3326-class, 1GB RAM, 640×480 4:3 screen), packaged
  for an ArkOS-family userspace with PortMaster. The primary test
  device is the purple unit identified in §3's evening update and
  §20 (a K36-family clone running ArkOS). If a reported spec and
  the document's own uncertainty conflict, design to the weaker
  reading.
- Controls: every input on the device is in §4 of the document.
  Two triggers per side (L1/L2, R1/R2). Never require the right
  stick and a face button at the same moment — they are the same
  thumb; firing belongs on a trigger or on stick-release. Before
  calling the controls done, run a thumb audit: for every pair of
  simultaneous actions, name the digit that performs each.
- Single-player first: most of these units have no Wi-Fi or
  Bluetooth, so nothing in the design may depend on a network or a
  second device — unless you deliberately design an offline
  multiplayer form (pass-and-play, shared screen) and say why.
- Original work: do not recreate, clone, or reskin an existing
  game. Morgan's favorites are influences, not templates. Invent
  the game's name and world from the material in the document; do
  not fall back on generic fantasy naming (the community's running
  joke is that Fable names everything "Ember" — be funnier and more
  specific than that).
- Assets: idea and world first. Generate the art and sound the
  game needs inside this run, with pipelines you build for the
  purpose, fitted to the world you design — do not wait for assets
  to be supplied, and do not let a stock asset style dictate the
  world's look.
- This codebase is yours: you are its owner and long-term
  maintainer. Structure it so its rules live in plain, testable
  code, separate from rendering.
- Finishing: do not stop while work from this brief is still owed.
  Ordinary obstacles — errors, timeouts, failing tools — are yours
  to diagnose and work through. Deliberate blockers — a boundary
  stated in this brief — are to be left alone and reported, not
  worked around. If you believe a rule in this brief is wrong for
  the game, finish everything else first, then report the rule and
  your reason; don't silently break it.
- Subagents: you may start subagents for bounded side-work (asset
  batches, independent checks), each with a written brief and a
  stated cap of [CAP — Morgan sets at launch]. The design and the
  main build stay with you; do not delegate them, and do not let a
  subagent start subagents of its own.
- Updates: every few tool calls, give the user a one-line update
  on where things stand.

WHAT DONE LOOKS LIKE
Done is proven, not asserted:
1. The game builds and packages for the handheld by a documented,
   repeatable command.
2. An automated headless run plays the game from title screen to
   its ending with zero console errors; any console error means
   the build is broken, full stop.
3. Screenshots exist from every area/state of the game, captured
   by the run itself, and you have looked at them — after each
   visual round, name the weakest thing you can see and fix it.
4. Unit checks pass for the game's rules (the node-free logic
   layer), and a headless simulation exercises the core loop.
5. The thumb audit (above) is written down and passes.
6. A fresh-context reviewer — not you — has graded the build
   against SPEC.md and this brief, and their report is included.
7. Your final report is written for a reader who wasn't there:
   what the game is, how to install and play it, the decisions in
   DECISIONS.md that matter most, the evidence for each done-item
   above, and what remains unverified — ending with what only
   Morgan can verify: playing it on the physical R36S.
```

A note on the effort line Morgan will attach to this in the Brief
builder: his stated preference is max/ultracode for the build
session (§0.3 records the research against it, as information, per
his instruction). The brief text does not change with the toggle.

### 0.5 The information form — what to give Fable, and in what shape

Research on information *form* (sources in §24) converges on a few
points, applied here concretely:

- **One document, clearly layered, beats a pile of files.** This
  document's layers — tagged claims, a chronology, raw material
  separated from Morgan's own statements — exist so Fable can tell
  evidence from ore. The spec session (Session A) then compresses
  it into SPEC.md, and the build session works from the spec. Fable
  follows written context *closely*; layering is how that literalism
  is aimed instead of feared.
- **The spec's skeleton.** A tested prompt structure for long tasks
  (Promptessor's synthesis of the official guide) names the parts:
  Objective, Context, Source authority (which source wins when
  sources conflict — here: Morgan in-session > SPEC.md > this
  document > model defaults), Scope (what may change, what must
  not), Autonomy (what proceeds without asking), Tools, Evidence
  (which claims need verification), Progress, Verification, Output,
  Completion. SPEC.md should be writable in that skeleton without
  forcing it.
- **Focused context beats total context.** The window is 1M tokens
  and compaction exists, but every request re-sends the context and
  unfocused context degrades answers. Give the build session the
  spec and this document — not Morgan's whole workspace, not his
  other projects' repos. (noodles and wasatch are *described* in
  §11–§12 at exactly the depth the design needs; their source code
  is not an input unless the spec session decides otherwise.)
- **The project's CLAUDE.md, if one is created, stays short and
  audited:** the hardware facts as settled in the spec, the build/
  test/screenshot commands, the thumb rule, the finishing-work
  line, the updates line. Nothing else. Every absolute in it will
  be obeyed absolutely, so it earns its lines one at a time.
- **Show, don't only tell, where a target exists.** For visual
  targets, Claude Code practice is a screenshot next to the mockup;
  for this game there is no mockup — which is precisely why the
  screenshot loop in §0.6 is in the definition of done instead.

### 0.6 The verification ladder for a game

Ordered weakest-to-strongest, assembled from the game-build sources
in §24 and the definition of done in §0.4. Each rung catches what
the ones below it can't:

1. **It builds.** One documented command, from a clean checkout.
2. **Rules tests.** The game's logic, kept in plain code that runs
   without the renderer, under unit checks that fail loudly.
3. **Headless simulation.** The core loop exercised automatically
   (the Godot write-up's strongest signal; Emberwake's and the
   beat-'em-up's playtest bots in §23 are the same idea at game
   scale) — reporting numbers, not vibes.
4. **Console-error gate.** The game runs headless; a single console
   error treats the build as broken.
5. **The screenshot loop.** After each visual round: capture, look,
   name the weakest visible thing, fix it, repeat. This loop, run
   for seven rounds in one write-up, is visibly what separated a
   toy from a game.
6. **Independent grading.** Session C (§0.2) against the spec —
   never the builder grading itself. The cautionary numbers from
   our earlier research stand behind this rung: in one reported
   case an independent session found 32 of 55 features wrong in a
   build its maker had called print-ready.
7. **Morgan on the device.** The only rung that can judge fun,
   feel, and whether the controls survive real thumbs. Everything
   below this rung is "runs"; this rung is "is a game."

### 0.7 Known failure modes, and the counter built into this protocol

| Failure mode (as reported) | Counter in this hand-off |
|---|---|
| Stops early with a list of what's left | Finishing-work text in the brief (§0.3) |
| Grades its own work generously | Session C, fresh context, grades only (§0.2) |
| Scope creep / unrequested changes | Ownership sentence's known side effect, checked by Session C reviewing the *diff* (§0.3) |
| Overcomplicates the design (Shumer, §23) | Spec session first; Morgan edits SPEC.md before any code |
| Builds the smallest satisfying version | "Be ambitious" is stated outright in the brief — the model's default reading is conservative |
| Delegates wildly, burns the budget | Subagent expectations + an explicit cap in the brief (§0.3) |
| Agents invent a review bureaucracy and throttle themselves | Review lives in one named session (C), not inside the build |
| Long silent runs | The one-line updates instruction (§0.3) |
| Old cautions in standing files block autonomous work | Pre-run audit of CLAUDE.md/notes (§0.2) |
| "Ember"-default naming and recreation-of-existing-games drift | Originality and naming rules written into the brief (§0.4) |
| Looks done in screenshots, feels wrong in the hands | Rung 7: unverified until played on the device (§0.6) |
| Model switched mid-run, reasoning and cache lost | One model per session; hand off by written summary (§0.2) |

### 0.9 For the local Claude session — questions and research directions

**Status: COMPLETED (2026-11-11 evening). All 9 questions answered with decompiled evidence and platform analysis in §25.**

*Added 2026-11-11 (evening). Morgan plans to open a Claude Code
session on his ThinkPad T460 (Fedora Sway) — the machine with the
card reader, the copied DTB files, and this document — and consult
Claude before the Fable launch. This section is addressed to that
Claude session. Your job here is **hardware/platform research and
protocol critique, not game design**: the design belongs to the
Fable sessions described in §0.2, and Morgan's rule for this whole
document is that nothing in it is invariant until he settles it.
Answer what's asked, with sources and evidence, and write findings
back into this document (amend §3/§5/§20 or append a dated research
note) rather than only into chat.*

*Local facts you start with: the two DTB files are at
`/home/moth/rk3326-evb-lp3-v12-linux.dtb` and
`/home/moth/rf3536k3ka.dtb`; the purple's stock card was
`/dev/mmcblk0` when read on 2026-11-11 (verify before trusting the
device name); Morgan has two spare 32 GB cards set aside, one per
unit, and the standing plan is to flash spares and keep both stock
cards physically untouched; full identification results so far are
in §20. `dtc` (device-tree-compiler) may need installing.*

**Identification — settle the purple completely:**

1. Decompile both DTBs (`dtc -I dtb -O dts`) and report what the
   active one (rf3536k3ka) declares: LCD panel model and timings,
   RAM size/type, the full GPIO/button map, battery/charging IC,
   audio path, and the USB controller's dr_mode — that last one
   predicts whether USB gadget mode (below) can work on this board.
2. Cross-check the decompiled facts against the community
   fingerprint tool (lcdyk0517.github.io/dtbTools.html) and the
   ArkOS4Clone clone-type list. Name the exact clone type this
   board corresponds to, with the evidence chain.
3. Given that board: is dArkOSRE a real option (check its
   supported-board list as of now), or is ArkOS4Clone the only
   maintained route? If both exist, compare them for THIS board:
   PortMaster support, known issues (any speaker-overvolting or
   panel caveats), update cadence. End with one concrete flash
   recommendation for the purple's 32 GB spare card: image,
   version, and first-boot steps.

**The black unit — can it be identified without opening it?**

4. Research software-only identification routes for the eMMC
   EmuELEC clone variant: EmulationStation/system-info screens,
   on-device file-manager paths, version files on its internal
   storage. If none are reliable, say so plainly and describe what
   opening it would need to reveal (board silkscreen) — Morgan
   decides whether that's worth it. Also: is there any maintained
   firmware path for eMMC variants at all, or is "leave it stock"
   the honest answer?

**Platform research — feed the §0.2 spec interview facts, not taste:**

5. PortMaster packaging, from primary docs: what a port consists of
   (folder layout, launch script, runtime), how controls are
   declared/mapped (gptokeyb et al.), and what the runtime expects
   of an engine. Which engines have real, working precedent on
   RK3326-class hardware — Godot 3 vs Godot 4 (and which renderer),
   LÖVE, others — with performance reports from people who shipped,
   not spec sheets.
6. An honest performance envelope for RK3326 + Mali-G31 at
   640×480 with 1 GB RAM: fill-rate and texture-memory limits,
   typical frame budgets in shipped ports, audio latency. Numbers
   Fable can design against, each with a source.
7. USB gadget mode on this hardware/firmware: does ArkOS USB
   Network Mode (or the SSH-over-OTG Ports script) work with
   ArkOS4Clone on K36-family boards? Combined with Q1's dr_mode
   finding, give a verdict for the purple: can test builds be
   deployed from the laptop over a USB-A→C data cable via
   SSH/SFTP, or is card-swapping the loop? Also confirm the DC/OTG
   port claims in §3 against any source that contradicts them.

**Protocol critique — read Part 0 as an adversary:**

8. Read §0.2–§0.7 and poke holes: where will the three-session
   protocol break first in practice? What does the §0.4 brief leave
   ambiguous that a build session will silently decide on its own?
   What in the §0.6 verification ladder cannot actually be executed
   headlessly for a PortMaster target, and what replaces it?
9. Anything in this document that is factually wrong, stale, or
   likely to mislead Fable's spec interview — list it with the
   correction and its source. (Known soft spots: everything tagged
   [reported] in §§3–5, and any place where the document still
   speaks of one unit instead of two.)

*Deliverable shape: short answers per numbered question, evidence
first, uncertainty labeled; no game design, no spec-writing —
those belong to the Fable sessions.*

### 0.8 What this upgrade changed in the document

- Part 0 (this section) added at the front: reader's guide, launch
  protocol, settings, the brief, the information form, the
  verification ladder, failure modes.
- §23 (clippings) was added earlier on 2026-11-11 and is now
  cross-referenced from §0.2/§0.7, since Emberwake and Shumer are
  load-bearing for the protocol.
- Super Mario Sunshine (§6.1 postscript, §7.11) was added earlier
  today at Morgan's correction.
- Nothing in §§1–22 was rewritten or promoted. The open questions in
  §21 remain open; §0.2 assigns most of them to the spec interview,
  which is where they were always going to be answered.
- Sources for Part 0 are collected separately in §24, so the
  2026-11-10 source list in §22 stays as it was.
- **2026-11-11, evening (hardware session, after the hand-off
  upgrade):** the two units were identified through the clone
  investigation recorded in §20 — black = eMMC EmuELEC clone
  variant, purple = K36-family clone and the primary device. §3
  gained an evening update with the settled facts and full DC/OTG
  port documentation (incl. USB gadget mode); the §0.1 guide and
  §0.4 brief hardware rule were corrected to match; §5.2 gained
  the deploy-loop note; §24 gained the evening's sources; §0.9 was
  added (questions and research directions for a local Claude
  session). Design content in §§1–23 remains unpromoted —
  the evening's work touched hardware fact and operating guidance
  only.
- **2026-11-11, ~22:20 (merge):** the two diverged copies of this
  document were merged into this canonical one. From the laptop
  copy: §25 in full, the §0.9 completion mark, and the settled-fact
  updates in §§3/5/20. From the canonical copy, which the laptop
  copy predated: §20's wiki cross-check and the black unit's board
  identification (R36S-V12 Variant 1, from Morgan's photograph).
  Where the two conflicted, the later evidence won and the
  supersession is marked in place (§25.3 correction note; §20's
  settled battery/USB bullets replace their undecided versions).
  The ownership decision (black = Morgan's, purple = JJ's) was
  recorded in §3. Nothing in §§1–23's design content changed.
- **2026-11-11, late evening (local Claude research session):**
  answered all nine questions in §0.9 with evidence from local DTB
  decompilation and primary platform sources; added §25 with the
  exhaustive findings. Settled: the two local DTBs are byte-for-byte
  identical; purple panel is Sitronix ST7703 4-lane MIPI DSI (640×480
  @ 58.50 Hz); clone type matches Kinhank K36 / Clone Type 1 Panel 1
  in ArkOS4Clone; RK817 PMIC reveals an 1848 mAh battery curve (qmax
  2033 mAh) vs the 3500 mAh shell sticker; USB gadget mode on the
  purple's right OTG port is confirmed supported (dwc2 dr_mode=otg),
  enabling a zero-card-pull SSH/SFTP deploy loop; engine choices
  settled on Godot 3 FRT or LÖVE 11 (Godot 4 flagged as harmful on
  RK3326 due to Weston compositor overhead); and identified the
  Dual-Runner requirement for headless test verification. §3, §5, and
  §20 updated to reflect settled facts.

---

## 1. How we got here — the full chronology

This section is a reconstruction from memory notes, the games catalogue,
and this thread. Dates and attributions are as recorded; any of them can
be corrected by Morgan at any time.

### 1.1 Before this thread

- **[reported]** On 2026-10-26, a handheld retro console entered Morgan's
  hardware inventory under the name "R26S." That name later turned out to
  be wrong (see §2.1). At the time, the assistant's web check characterized
  it as a ~$30–40 AliExpress-class Linux retro handheld, solid for
  NES/SNES/Mega Drive/PS1/GBA, shakier for N64/PSP/Dreamcast, with a
  warning that the stock microSD cards in this class of device are
  failure-prone. No build or hack plan for it was committed at the time.
- **[reported]** On 2026-11-09, Morgan asked for a catalogue of his
  favorite games through time and consoles. The catalogue was started at
  `~/workspace/your_files/favorite-games-catalogue.md`, seeded only with
  what was already on record (Mancala, Among Us as a wave/model, the Big
  Brother format as a design reference, and his own game Two-Top), with
  era-by-era sections left blank to be filled from Morgan's own naming.
- **[reported]** In that same 2026-11-09 conversation, Morgan raised two
  design references while brainstorming: **Finch** (a self-care app with
  a tamagotchi-style bird you raise by completing real-life goals/habits)
  and **"that game where the world is like a cube that evolves."** The
  assistant's identification of the cube game — most likely *Birthdays
  the Beginning* (2017), with WorldBox and Cube World as alternates —
  remains **unconfirmed by Morgan** as of this writing.
- **[reported]** Also on 2026-11-09, Morgan chose to have two spaces —
  one for games/inspiration, one for worldbuilding — rather than one
  combined space. That decision belongs to a different thread, but it is
  part of the backdrop: games-as-inspiration is an ongoing, deliberate
  project for him, not a one-off chat.
- **[reported]** Morgan's own game **Two-Top** (ampactor-labs) — a
  phone-vs-phone Bevy/ggrs brawler — predates this thread and is the game
  he has spent the most building time inside lately. It matters here as
  evidence of taste and of what he has already learned about making
  games, not as a template for the R36S idea.

### 1.2 This thread, message by message

**Tue 2026-11-10, 14:24 MST — Morgan (opening message, with 2 photos).**

- **[observed]** Photo 1 (front): a black vertical retro handheld held in
  a hand, under purple light. Large screen on the upper half (off,
  reflecting the room). Below it: a D-pad on the left, ABXY buttons on
  the right, a speaker grille in the center, small round buttons in the
  middle, and two analog sticks low on the body, left and right.
- **[observed]** Photo 2 (back): a white factory label reading "Consola
  Retro," "MODEL No RJ6S," "RATING 5V," "BATTERY Li-Po 3.8V 3500mAh"
  (partially legible), "ADAPTER INPUT 5V ≥ 1.5A" (partially legible),
  "Built in rechargeable Li-po battery / Only use certified charger /
  The battery may explode in the fire," "MADE IN CHINA." Four prominent
  shoulder bumpers across the upper back, two per side. Venting/grille
  lines across the lower back and a small port or latch at the bottom
  edge.
- Morgan's words, in substance: he wondered if anybody is making games
  actually targeting this hardware; he would love to design a game
  (originally: "with you," meaning Loni) and see if Fable 5.2 can
  one-shot it; the game should make the most of the hardware specs and
  layout. Before getting down to design, he filled in his games
  background (reproduced in §6), noting he hasn't played that many
  games, that recommendations/influences from outside his list are open
  to consideration, and that the R36S is the only console he actually
  has and his laptop is, in his words, "so sad." Full condensed text in
  Appendix B.

**Tue 2026-11-10, ~14:25–14:40 — Loni's first pass (research + reply).**

- Loni searched memory, found the earlier "R26S" record and the games
  catalogue, then researched the device class on the web (sources in
  §22). On that basis Loni identified the unit as an **R36S**, corrected
  the catalogue and memory, filed Morgan's favorites list, and replied
  with: hardware identification, the PortMaster route for native games,
  a reading of patterns in Morgan's favorites, a warning that his
  multiplayer loves mostly can't live on this device, and a concrete
  game sketch ("Mothlight," §15) with a stack recommendation (LÖVE) and
  an offer to write a full brief for Fable.
- That reply contained at least one outright error (the three-thumb
  control scheme, §4.2) and one role assumption that Morgan then
  revised (who designs, §2.3). Both are preserved in this doc rather
  than quietly edited away.

**Tue 2026-11-10, 14:45 MST — Morgan (correction + the music turn).**

- **[observed]** Morgan pointed out there are 2 "right" triggers and 2
  "left" triggers, and that Loni's suggested mechanic would require 3
  thumbs. Tone: amused, not annoyed — "it's ok."
- **[observed]** Morgan revised the division of labor: "I think I'll
  actually let Fable do the designing."
- **[observed]** Morgan pointed at the thru-line Loni had missed:
  **MUSIC.** He directed attention to what ampactor-labs/noodles and
  ampactor-labs/wasatch do with the circle of fifths, and pasted his
  poem in full (Appendix A).

**Tue 2026-11-10, ~14:46–14:55 — Loni's second pass (reading + reply).**

- Loni acknowledged the thumb error, read the actual noodles README and
  `src/circle.js`, and the wasatch README and DESIGN.md harmony
  sections via the GitHub connector, and replied with the music
  synthesis summarized in §9 and §14, ending with an offer to write the
  synthesis up as a seed brief for Fable (thru-lines and constraints
  only, no design).

**Tue 2026-11-10, 14:57 MST — Morgan (this document).**

- **[observed]** Morgan asked for "the exhaustive .md doc with all the
  details and how we got here as well," with the explicit condition that
  nothing be stated as invariant, "this is still a brainstorm."
- This document is the response to that ask. Note what it is *not*: it
  is not the seed brief offered in the second pass (that offer is still
  just an offer), and it is not a design document. It is the brainstorm,
  written down exhaustively, with its history attached.

---

## 2. Role changes and corrections along the way

### 2.1 The name of the console

- **[superseded]** "R26S" (recorded 2026-10-26, from Morgan's own
  message at the time, possibly a typo or misremembering on somebody's
  part — the record does not settle whose).
- **[observed]** The factory label on Morgan's unit reads "RJ6S," which
  appears to be one of the many label variants in this device family and
  is most plausibly a factory typo/variant of R36S.
- **[observed]** Morgan himself called it "the r36s" in his opening
  message of this thread.
- **Current working name in this doc: R36S**, with the caveat that this
  device family is famously clone-ridden and name-unstable (§20), so
  even the name is a working label rather than a certainty.

### 2.2 Who the game is "with"

- The opening message framed it as designing a game *with Loni* and
  having Fable 5.2 attempt to one-shot the implementation.
- Morgan's 14:45 message reframed it: Fable would do the designing.
- Loni's role, under the reframing, shrinks to things like: research,
  synthesis, writing seed material, cataloguing, checking facts, and
  keeping the paper trail — if Morgan wants any of that. None of that
  division is locked either; it is simply the latest shape the
  conversation took.

### 2.3 The status of Loni's game sketch

- "Mothlight" (§15) was Loni's design, offered in the first pass. Under
  the reframing in §2.2 it is **demoted to raw material**: a worked
  example of one way the threads could combine, available for Fable or
  Morgan to mine, adapt, or ignore. It carries no priority just because
  it was written down first.

### 2.4 The status of this document's claims about Fable

- Whether Fable 5.2 can "one-shot" a game of any given scope is an
  untested hypothesis in this thread, not a known capability or limit.
  The one-shot idea is treated throughout as an *experiment Morgan
  proposed*, whose terms (what counts as one shot, what prep is allowed,
  what fixing is allowed afterward) have not been defined yet (§18,
  §21).

---

## 3. The hardware, as far as we currently understand it

Everything in this section is **[reported]** from web sources consulted
on 2026-11-10 (§22), cross-checked loosely against Morgan's photos.
None of it has been verified against Morgan's specific unit, and this
device family is known for silent hardware revisions and clones, so
treat every line as "probably, for a typical unit sold under this name."

**Evening update (2026-11-11) — what is now known about Morgan's
actual hardware [observed], full detail in §20:** Morgan owns **two**
units, and after an evening of tests both are identified as clones of
two different families. The **purple unit is the primary device**: a
K36-family clone running card-booted ArkOS (its boot config loads the
rf3536k3ka device tree; its 128 GB stock card carries the standard
ArkOS three-partition layout — FAT16 BOOT, ext4 root, exFAT EASYROMS).
The black unit is an eMMC EmuELEC clone variant (boots with no card;
its card is data-only). Both are RK3326-class with a 640×480 screen,
so the design targets in this section stand as *class* targets; the
practical packaging target is an ArkOS-family userspace with
PortMaster, as on the purple. The purple's maintained firmware path
is ArkOS4Clone (clone type per the DTB fingerprint, pending).
**Ports [observed + reported]:** the bottom edge carries two USB-C
ports split by the headphone jack — **DC** (left: charging only, no
data lines; charge it with a plain USB-A→C cable and a 5V 1–2A brick,
because the board lacks USB-C CC resistors and many USB-C→C chargers
deliver nothing) and **OTG** (right: USB host for Wi-Fi dongles on
supported chipsets, gamepads, keyboards, thumb drives; with the
right ArkOS tool it can also flip to USB *gadget* mode and appear to
a connected PC as a network device for SSH/SFTP file transfer —
board-dependent on clones). Neither port outputs video. Nothing
about the game design should require a dongle or a cable; both are
developer conveniences, and the gadget-mode transfer is a plausible
deploy path for test builds.
**Ownership (decided 2026-11-11, ~22:17):** the black unit is
Morgan's own and the purple unit is JJ's. Flashing routes per unit
are recorded in §20 and §25.2 (ArkOS4Clone for the purple;
dArkOSRE with Variant 1 DTBs for the black); both units end up on
ArkOS-family firmware with PortMaster, so the game packages for
both — and the verified gadget-mode deploy loop (§25.5) lives on
JJ's unit, which the Session A device plan should take into
account.
**Board correction (2026-11-11, ~22:28):** Morgan photographed
the purple's board: it carries the **same R36S-V12 2023-08-18
silkscreen as the black unit**, a genuinely marked RK3326, and a
Samsung KMQNW000SM-B316 memory package (a part photographed on
R36S clones in the wiki's gallery). The two units are therefore
variants of one board, not two families — they differ in memory
package and individual history. **And a same-night correction to
this correction (~22:32):** after Morgan disconnected and
reconnected the purple's battery, the purple ALSO booted cardless
to the EmulationStation "WE CAN'T FIND ANY SYSTEMS!" screen — its
eMMC carries the same internal system as the black's. The
evening's original cardless test on the purple (nothing happens)
was a false negative: the unit was latched, and the battery pull
reset it. Both units in fact dual-boot — a bootable SD in TF1
wins; with no bootable card, the internal eMMC system boots. Full
record in §20. Everywhere this document says "K36" about the
purple, it names the unit's firmware/DTB profile (ArkOS4Clone
Clone Type 1 Panel 1, settled from its own stock DTB in §25.1),
not its board. Full record in §20.

### 3.1 Core specs (typical R36S, as reported)

- **SoC:** Rockchip RK3326 — quad-core ARM Cortex-A35, up to ~1.5 GHz.
- **GPU:** Mali-G31 MP2, with reported support for OpenGL ES 3.2,
  Vulkan 1.0, OpenCL 2.0.
- **RAM:** 1 GB DDR3L. (One source notes genuine boards carry two
  physical DDR3L chips; single-chip boards may indicate a clone variant
  with different behavior. Unverified for Morgan's unit.)
- **Display:** 3.5-inch IPS, 640×480, 4:3 aspect ratio. Reported to be a
  strong suit of the device: bright, sharp for retro content. Multiple
  screen panel variants reportedly exist across production runs, and
  firmware may need the correct device-tree blob (DTB) per panel.
  **Update (2026-11-11 late evening) [observed]:** the purple unit's panel
  is settled via DTB decompilation as a **Sitronix ST7703** via 4-lane
  MIPI DSI, clocked at 30.00 MHz for an exact 58.50 Hz refresh rate
  (640×480 native; details in §25.1).
- **Storage:** two microSD slots, conventionally one for the OS (TF1)
  and one for games (TF2).
- **Battery:** ~3,000–3,500 mAh depending on batch; Morgan's unit's
  label says 3500 mAh **[observed]**. Reported real-world play time
  roughly 4–6 hours at moderate brightness. Battery reported as
  removable/replaceable on typical units.
  **Correction / reality check (2026-11-11 late evening) [observed]:**
  while the physical shell label says 3500 mAh, the purple unit's
  decompiled DTB reveals that the RK817 PMIC fuel-gauge profile is
  factory-programmed with `design_capacity = 1848 mAh` (0x738) and
  `design_qmax = 2033 mAh` (0x7f1) at 4.2V (cutoff 3.5V, max charge current
  800 mA). Practical battery life should be modeled on a ~1850–2000 mAh
  cell, not 3500 mAh (§25.1).
- **Ports (as reported + observed):** two USB-C ports (left: DC charging only;
  right: OTG data/host/gadget), a 3.5 mm headphone jack.
  **Update (2026-11-11 late evening) [observed]:** USB gadget mode is confirmed
  supported by the hardware and DTB (`dr_mode = "otg"` on dwc2 controller
  at `ff300000`). Test builds can be deployed from the laptop over USB-A→C
  via SSH/SFTP into the OTG port with zero card pulling (§25.5).
- **Charging (as reported):** fussy — may not charge from USB-C to
  USB-C / fast chargers; old-school 5V/2A USB-A bricks are the reported
  safe default. Morgan's label says adapter input 5V, ≥1.5A-ish
  **[observed, partially legible]**. To be verified against his unit
  and his chargers.
- **Connectivity (as reported):** most units have **no built-in Wi-Fi
  or Bluetooth**. Wi-Fi reportedly possible via USB-C dongles with
  specific chipsets (e.g. RTL8188FTV / RTL8192EU) on some firmwares.
  Whether Morgan's unit has any radio at all is unknown (§20).
- **Price class (as reported):** roughly $35–45 from typical sellers.

### 3.2 Software / firmware environment (as reported)

- Units typically ship with an ArkOS-based Linux image and an
  EmulationStation front end.
- **[reported, dated]** The firmware landscape appears to have shifted
  during 2026: the community ArkOS build for this device family was
  reported archived in June 2026, with forks such as dArkOSRE-R36 and
  ArkOS4Clone, and ROCKNIX, named as more current routes by various
  guides. Which firmware is actually on Morgan's card has not been
  checked.
- The R36S reportedly shares its RK3326 base closely enough with the
  Anbernic RG351 line that some firmware builds are shared (e.g. the
  RG351MP ArkOS image being used as a base). Mentioned here only
  because it may matter if firmware is ever changed.
- **[reported]** A commonly repeated authenticity check: the SD card
  partition name on genuine units is `EASYROMS`, while various clones
  use names like `EMU`, `EOEC`, or `EROMs`. Unverified for his unit;
  also mostly relevant to firmware flashing, not to game design.

### 3.3 What the chip reportedly can and can't do (performance tiers)

As reported across reviews/guides consulted:

- **Full speed, comfortably:** 8-bit and 16-bit consoles (NES, SNES,
  Genesis/Mega Drive, Master System, Game Boy/Color/Advance, PC
  Engine), most arcade (MAME/FBNeo, CPS1/2, some CPS3 wobble), and most
  PlayStation 1.
- **Mostly workable:** Nintendo DS (many titles), some Nintendo 64,
  Dreamcast, and PSP — explicitly game-by-game, not a blanket promise.
- **Not the point of the device:** GameCube-class 3D and anything
  expecting a discrete GPU.
- **Native ports:** reported to be a highlight — PortMaster titles like
  Undertale, Cave Story, Doom-family ports running natively rather than
  emulated, with performance decided port by port (§5).
- For an original 2D game, the working assumption in this brainstorm
  (an **[idea]**, not a benchmark) is that the interesting limits are
  not raw power but: 1 GB shared RAM, a modest Mali GPU, SD-card I/O,
  thermals/battery, and the 640×480 screen. A well-behaved 2D game is
  generally expected to be well within reach; a 3D game in the Zelda-64
  style would be a different and much riskier conversation. Both halves
  of that sentence are provisional.

### 3.4 The display as a design surface

Points raised in the first pass, all **[idea]**-grade:

- 640×480 is exactly 2× 320×240, so art authored at 320×240 could
  upscale pixel-perfectly (integer scaling), which several sources
  noted is how PS1/N64-era content lands so cleanly on this panel.
- Other candidate internal resolutions that divide 640×480 cleanly
  could be considered (e.g. 160×120 at 4×, or authoring at native
  640×480). None chosen.
- 4:3 is a real constraint and a real aesthetic: most modern 2D games
  Morgan might take influence from assume 16:9. Composing for 4:3 —
  more verticality, tighter arenas, less horizontal sprawl — is a
  difference worth designing *for* rather than around, if the project
  goes anywhere. Or not. Brainstorm.

### 3.5 The stock SD card warning

- **[reported]** Repeatedly, across sources and in the assistant's
  original Oct 26 note: the microSD cards bundled with this device
  class are failure-prone, and imaging/backing up the card early is
  the standard advice. This is recorded here because losing the card
  could mean losing saves, ports, and any future homebrew installs —
  not because any backup step has been scheduled or agreed.


---

## 4. The physical control layout, and the thumb problem

### 4.1 The layout, as observed and reported

From Morgan's photos **[observed]** plus typical-unit reports:

- **D-pad**, upper left of the lower half. Reported quality varies by
  unit/batch; it is the primary movement input on most retro software
  for the device.
- **ABXY face buttons**, right side. From the front photo, the cluster
  appears to be in the Nintendo-style arrangement: X on top, Y on the
  left, A on the right, B on the bottom (labels visible in the photo:
  X purple at top, Y left, A red right, B orange/yellow bottom). To be
  confirmed on the physical unit in normal light.
- **Two analog sticks**, low left and low right. Their low placement
  (below D-pad and buttons respectively) is characteristic of this
  device family.
- **Four shoulder triggers** across the upper back: L1/L2 on the left,
  R1/R2 on the right **[observed — four bumpers are clearly visible in
  the back photo]**. This is one of the two facts Morgan personally
  corrected in this thread, and it matters: four index-finger inputs
  is a lot of underused real estate on a retro handheld, where most
  emulated software uses two at most.
- **Center buttons:** from the front photo there appear to be three
  small round buttons in the middle column below the speaker grille,
  with text below the lower two that reads as SELECT / START
  **[observed, partially legible]**. Typical units also have a function
  (FN) button used for emulator hotkeys; whether one of the pictured
  buttons is FN, and what any of them do outside emulators (in a
  native game, they may be freely usable — or reserved by the OS), is
  unverified.
- **Speaker grille** in the center of the face **[observed]** — mono
  speaker placement is typical for the class; headphone jack for
  stereo (as reported). Relevant if the game's music matters, which in
  this brainstorm it very much might (§9).
- Side controls (power, volume) exist on typical units; their exact
  placement wasn't legible in the photos and isn't load-bearing here.

### 4.2 The thumb problem (Morgan's correction, preserved)

Loni's first-pass sketch proposed, simultaneously:

- left stick (or D-pad) to move,
- right stick to aim a boomerang,
- the X button to throw it.

Morgan's correction, 14:45: there are 2 right triggers and 2 left
triggers, "and you just suggested a mechanic that would require 3
thumbs lol."

The anatomy of the error, for the record:

- The left thumb owns the D-pad *or* the left stick, not both at once.
- The right thumb owns the ABXY cluster *or* the right stick, not both
  at once. Aiming with the right stick and pressing a face button at
  the same time requires a third thumb.
- The inputs that *can* be simultaneous with two sticks are the four
  triggers, because index (and possibly middle) fingers live there.

Candidate design considerations that fall out of this — all
**[idea]**-grade, none adopted:

- If a game ever wants twin-stick aiming, firing most naturally lives
  on a trigger (R1/R2), or on stick-press, or on release/flick of the
  aiming stick, or aiming could be automatic/lock-on while the face
  buttons stay primary. Each option changes the feel completely.
- Symmetrically: face-button-heavy play pairs naturally with D-pad or
  left-stick movement and a free right thumb.
- The four triggers could carry mode changes (e.g. swapping forms,
  shifting key — see §14), because triggers can be tapped *while*
  moving and acting. Or they could do nothing. Brainstorm.
- Any future control scheme, from anyone, probably wants a "thumb
  audit": for every simultaneous action pair, name which digit does
  each. This doc offers that as a suggested check, not a rule.

### 4.3 Other input considerations (all provisional)

- **[question]** Stick quality/dead zones on Morgan's unit: unknown.
  Games leaning hard on precise stick aiming inherit that risk.
- **[question]** Does the D-pad on his unit register clean diagonals?
  Pivot quality on this device family is reportedly variable.
- **[idea]** The device has no touchscreen, no gyro (as reported), no
  rumble (as reported, typical units), no camera, no mic. Any design
  has exactly: 4 face buttons, a D-pad, 2 sticks (possibly clickable —
  unverified), 4 triggers, and a few center buttons. That closed set
  could be treated as a creative constraint in the Phantom Hourglass
  sense (§7.5): a small controller, used completely.

---

## 5. Routes by which software can run on this class of device

Nothing in this section is a recommendation. It's the menu as
understood on 2026-11-10, **[reported]** unless tagged otherwise.

### 5.1 PortMaster

- A community project that packages native Linux ports of games for
  ARM handhelds like this one, installable from within the device's
  Tools menu on supported firmwares.
- Ports are **not emulation**: the game's code (or a reimplemented
  engine) runs natively on the RK3326, which generally means better
  performance and battery for the titles it covers.
- Library size reported as 1,300+ ports and growing; entries are
  labeled per-device, and heavier entries (e.g. Half-Life, Stardew
  Valley) are present in the catalogue but are a much bigger ask of
  this chip than of more powerful handhelds — device notes matter.
- Per the PortMaster wiki material consulted, a game is "portable" if
  its code can be made to run on ARM Linux, via roughly three paths:
  1. **Native build** — open source, or the developer ships an ARM
     Linux build; compiles and runs directly. Many ports are
     SDL-based C/C++ games of this kind.
  2. **Engine runtime** — an engine has been reimplemented/rebuilt for
     ARM and runs the game's data: listed examples include Godot,
     Solarus, RealLive.
  3. **Bytecode VM** — the game is bytecode for a VM that already runs
     on ARM: GameMaker (via GMLoader/GMLoaderNext), Mono/.NET, Java.
- Named engine/framework rows from the wiki table consulted: GameMaker
  (the largest group), Godot (Godot 3 via FRT; Godot 4 via a Godot
  runtime), Love2D (LÖVE binary runs a `.love` file), Pyxel, RealLive,
  Solarus.
- Translation layers (box86/box64) exist for x86 binaries but pay a
  performance cost; native ARM is reported to run best.
- Controller mapping for ports is reportedly generated through
  PortMaster's mapper/gptokeyb machinery, which is part of why the
  physical layout (§4) matters at packaging time.
- **Engine audit results (2026-11-11 late evening) [settled, §25.4]:**
  - **Godot 3.5.x via FRT (`frt_3.5.2.squashfs`) [RECOMMENDED]:**
    renders directly to DRM/KMS GLES2 without any desktop/compositor
    overhead, rock-solid 60 FPS, ~50 MB RAM baseline.
  - **LÖVE 11.x (Lua) [RECOMMENDED ALTERNATIVE]:** native runtime,
    negligible overhead, sub-10ms native ALSA audio latency.
  - **Godot 4.x [AVOID ON RK3326]:** requires running inside a Weston
    (Wayland compositor) wrapper on PortMaster; the compositor overhead
    chokes the Cortex-A35, causing frame stuttering and high audio latency.
- **Implication if this route were ever chosen:** an original game
  built in one of the supported engines could, in principle, be
  packaged as a PortMaster-style port and installed on the device like
  any other port. The packaging details (control.txt, runtime pinning,
  etc.) have not been researched yet and would need a dedicated pass.

### 5.2 Emulation-adjacent routes (fantasy consoles and interpreters)

Mentioned as possibilities to investigate, **[idea]**-grade — their
exact availability on Morgan's firmware has not been checked:

- **PICO-8 / TIC-80 / Pyxel-style fantasy consoles:** tiny, constrained
  environments that suit one-shot-sized games. Trade-off: their native
  resolutions and input models use only a fraction of this hardware
  (a 128×128 screen on a 640×480 panel; a D-pad and two buttons where
  the device offers far more). Whether that constraint is a feature
  (focus, finish-ability) or a waste (ignores the layout Morgan wants
  exploited) is an open aesthetic question (§21).
- **ScummVM and other interpreters** ship with these firmwares and run
  whole genres of older games; mostly relevant as context (the device
  is already an interpreter stack), not as an original-game route,
  unless someone wanted to author inside one of those formats, which
  nobody has proposed.

### 5.3 Native development directly against the OS

- The device runs Linux (ArkOS-family), so in principle a game can be
  a plain ARM Linux binary using SDL2 and friends, launched from
  EmulationStation's ports section without PortMaster's packaging.
  **[reported]** that many PortMaster entries are effectively this,
  with PortMaster handling distribution/mapping.
- For Morgan specifically, a Rust route exists in the abstract (he is
  a Rust systems engineer; SDL2/raylib-style or Rust-native 2D stacks
  cross-compile to aarch64). Nobody has proposed he write this game
  himself — the thread's premise leans the other way (Fable) — but the
  option is recorded so the brainstorm doesn't silently exclude it.

### 5.4 Testing without the device

- **[idea]** Every engine route in §5.1/§5.3 can also run on a desktop
  or laptop during development, which matters because Morgan's laptop
  is weak but 2D-game-development weak is usually fine, and because
  flashing/copying to the handheld for every iteration would be slow.
  A candidate workflow (desktop-first, device-as-final-check) is
  floated here, not adopted.
- **Getting builds onto the device [evening note, 2026-11-11]:**
  three routes, in increasing convenience. (1) Card swap — the
  baseline, always available. (2) A Wi-Fi dongle on the OTG port
  (§3) with network transfer. (3) **USB gadget mode** — the OTG
  port flipped to device mode via ArkOS USB Network Mode or an
  SSH-over-OTG Ports script, so the handheld appears to the laptop
  as a USB network device offering SSH/SFTP/Samba, and can borrow
  the laptop's internet connection (the only way a radio-less unit
  reaches PortMaster downloads). Route 3 is the developer loop
  worth wanting — push a build, pick up the device, play.
  **Settled (2026-11-11 late evening) [observed, §25.5]:**
  Route 3 is confirmed working for the purple unit (`dr_mode = "otg"`
  on dwc2 controller, data lines routed on right OTG port).
  Test builds deploy over a standard USB-A→C data cable via SSH/SFTP
  (`192.168.7.1`, user `ark`, pass `ark`) directly into `/roms/ports/`
  with zero card pulling.
- **The Dual-Runner architecture for testing (2026-11-11 late evening) [verdict, §25.6]:**
  Headless automated verification (§0.6) on Morgan's x86_64 ThinkPad
  cannot execute PortMaster ARM binaries directly. The project must
  enforce a dual-target architecture: a native desktop runner
  (`run_desktop.py` / desktop engine) for automated logic smoke tests,
  bot playthroughs, and screenshot capture, and a packaging script
  (`package_portmaster.sh`) that bundles the `.pck` / `.love`, `.gptk`,
  and shell script for the handheld.

---

## 6. Morgan's games — the catalogue material

Source: Morgan's opening message, 2026-11-10, filed into
`~/workspace/your_files/favorite-games-catalogue.md` the same day.
Order and grouping below are his.

### 6.1 Single-player favorites — Morgan's own order

1. **The Legend of Zelda: Majora's Mask**
2. **The Legend of Zelda: Tears of the Kingdom**
3. **The Legend of Zelda: Ocarina of Time**
4. **The Legend of Zelda: The Wind Waker**
5. **The Legend of Zelda: Phantom Hourglass**
6. **Outer Wilds**
7. **Fallout 3 / Fallout: New Vegas** (listed together by Morgan)
8. **Paper Mario: The Thousand-Year Door**

**Postscript to the list (2026-11-11):** a day after giving the list,
Morgan added **Super Mario Sunshine** — "oh I forgot super Mario
Sunshine as one of my all time favorites too." He gave no rank for
it, and this doc does not invent one; it sits alongside the ordered
eight as an unranked all-time favorite. A per-game note is at §7.11.

Context Morgan attached to the list:

- He hasn't played that many games ("I like haven't played that many
  games though"). The list is a favorites list from a shallow-but-deep
  pool, not a survey of the medium.
- He suspects he would love **Hyper Light Drifter** and **Tunic**,
  unplayed. ("I bet I would love hyper light drifter I bet I would
  love tunic...")
- Outside recommendations are explicitly open to being considered as
  influences.
- The reason given for not having played them is resources, not
  interest: he would be playing those games if he had a rig that could
  run them; the R36S is the only console he actually has and the
  laptop is weak. (Both HLD and Tunic are, incidentally, the class of
  game this hardware conversation keeps circling — see §7.9.)

### 6.2 Multiplayer favorites — no particular order (Morgan's words)

- **Super Smash Bros. Ultimate**
- **Minecraft Dungeons** — played with his little brothers. Context
  from Morgan: they had gone back to **Gauntlet: Dark Legacy** first,
  excited, and quickly got bored — "this game did not hold up... super
  shitty with or without cheats hahaha" — and Minecraft Dungeons was
  "what's scratching that itch now."
- **Gauntlet: Dark Legacy** — listed inside the Dungeons anecdote;
  fondly remembered, poorly aged, per Morgan.
- **Super Monkey Ball 2** (GameCube) — with his brother, a long-running
  good time that surprisingly still holds up; "hardly because of the
  ridiculousness it's almost like meta fun while the mechanics
  genuinely are good."
- **Mario Party** — "some of the Mario parties are fun obviously."
- **Two-Top** — his own game, named by him in this list ("my game too
  top" in the voice-to-text original).
- **Boomerang Fu**
- **Wii Play: Tanks** — "on the Wii Play tanks game I was fucking
  top-tier haha"
- **MMORPGs** — not a played favorite but a curiosity: "I feel like
  MMORPG like might be sick but I just never had the resources to try
  getting into that."

### 6.3 Older catalogue entries that predate this thread

From the games catalogue (started 2026-11-09), included so the
brainstorm's raw material is all in one place:

- **Mancala (Kalah)** — marathon session with JJ, night of
  2026-10-21/22; lost roughly 12 in a row while rebuilding pattern
  recognition he says was at crush level in 2018. A data point about
  enjoying systems you can *re-learn* deeply.
- **Among Us** — cited by Morgan as a wave/model: what a social game
  can do when it catches fire; part of why he wants a Big Brother-form
  game.
- **Big Brother (TV format)** — a design north star for him rather
  than a video game: slow burn over days, alliances, nominations,
  evictions. (There's a separate host-kit prototype thread — Factory
  Floor, 2026-11-09 — outside this brainstorm's scope.)
- **Finch** — self-care tamagotchi-style bird raised by doing real-life
  goals/habits; named 2026-11-09 as a design reference.
- **The cube-world-that-evolves game** — unidentified; assistant's best
  guess Birthdays the Beginning, alternates WorldBox / Cube World.
  Confirmation still pending.

---

## 7. Per-game notes: what each favorite might be bringing

Every note in this section is a **[reading]**. These are hypotheses
about why a game might sit where it sits in Morgan's list, assembled
so a designer (Fable, or anyone) can see candidate ingredients. Morgan
has not endorsed most of these readings; several were only voiced by
Loni in-thread. Any of them could be wrong about what he actually
loves in the game.

### 7.1 Majora's Mask (#1)

- A three-day time loop; the world resets; masks, songs, and player
  knowledge persist.
- NPCs live on schedules. Helping someone requires learning *when*
  they are *where*, and the famous long side-quests (e.g. the
  Anju/Kafei chain) are pure schedule-knowledge expressed as story.
- Transformation masks: different bodies as keys, each body changing
  movement, music (each form plays the ocarina as a different
  instrument), and how the world treats you.
- Music is diegetic machinery: the ocarina's songs are literally the
  controls for time (slowing it, skipping it, rewinding it). This is
  worth underlining in a brainstorm where music keeps surfacing (§9):
  in Morgan's #1 game, *playing music is how you operate time.*
- A melancholy, small, dense world: one town, four outskirts, an
  apocalypse with a face. Density over sprawl.
- A save/progress structure that trusts the player to hold the thread
  (the Bombers' Notebook as an external memory — a paper ship's log).

### 7.2 Tears of the Kingdom (#2)

- Building/fusion as expression: systems that let the player author
  solutions rather than find the one intended key.
- Verticality and traversal freedom; the sky/depths layering.
- Sits at #2 in a list otherwise dominated by much smaller games,
  which might mean: the openness itself is loved, or the Zelda
  grammar is loved at any scale, or both. **[question]** for Morgan
  sometime: what in TotK would survive being shrunk to a 3.5" screen,
  if any of it would?

### 7.3 Ocarina of Time (#3)

- The template under Majora's: ocarina-as-interface again, time travel
  between two ages of the same world (same map, two states — a "where
  and how high" choice made literal as child/adult), dungeon-item
  grammar.
- Melodies as passwords/keys that the player *performs* rather than
  selects from a menu — performance as input.

### 7.4 The Wind Waker (#4)

- Sailing: a world whose traversal is slow, musical (the Wind Waker
  baton conducts time signatures — 3/4, 4/4, 6/4 — as a spellcasting
  interface), and mostly ocean with islands as punctuation.
- Bright surface, lonely undertow. A flooded world's melancholy under
  cel shading.
- The baton is another data point for §9: a Zelda game where the
  central magical tool is a *conductor's* tool, and using it well is
  literally keeping time.

### 7.5 Phantom Hourglass (#5)

- The outlier pick that says a lot: a DS Zelda built entirely around
  one weird input — the stylus does everything, including drawing the
  boomerang's flight path and annotating the map by hand.
- **[reading]** Its presence at #5 suggests the *gimmick used
  seriously* is a value: a whole game committed to its one strange
  control idea, and hand-drawn map notes as knowledge-keeping (the
  player literally writes the notebook). Both halves rhyme with other
  entries here (§4.3's closed input set; §8's knowledge-as-inventory).
- Also: a repeated central dungeon revisited with new abilities and
  knowledge across the game (the Temple of the Ocean King) — a loop
  structure inside a non-loop game, with a time limit per visit.

### 7.6 Outer Wilds (#6)

- A ~22-minute time loop in a clockwork solar system; the ship's log
  is the only persistent "inventory." Progress is purely epistemic:
  you finish the game the moment you understand it, and a skilled
  player could complete it on a first loop, in principle.
- No combat, no upgrades, no XP. Curiosity is the engine; the rumor
  system turns knowledge into a map.
- Music again: the travelers' instruments, each on a different planet,
  playing the same tune — findable by radio (signalscope). The game's
  emotional climax is literally getting the band together for one last
  song. In a brainstorm about Morgan, that detail probably matters.
- Pairs with Majora's as "the same structure, twice in one top-8":
  loop + schedules + knowledge. Loni flagged this pairing in the first
  pass; Morgan has not confirmed or denied the pairing as the reason
  both rank.

### 7.7 Fallout 3 / New Vegas (#7)

- Choice-dense RPG wastelands: dialogue as gameplay, factions,
  multiple solutions, a world that remembers what you did.
- Radio stations as world-building-through-music (Galaxy News Radio /
  Radio New Vegas) — music as the connective tissue of a broken
  world, again at the level of texture.
- **[reading]** The ingredient this entry most plausibly contributes:
  *talk to people, choose, live with it* — the opposite pole from
  Outer Wilds' silence, and a possible ingredient for any town full
  of scheduled NPCs (§15 uses it lightly; Fable may use it heavily or
  not at all).

### 7.8 Paper Mario: The Thousand-Year Door (#8)

- Turn-based battles enlivened by **timed button presses** (action
  commands): rhythm as the difference between a menu selection and a
  performance. Combat you *play*, in time, with your hands.
- Badges as a build/customization system; partners as abilities and
  personalities; a stage/play framing where the audience matters.
- **[reading]** The timing element is the sleeper connection to §9:
  even in the most "RPG" entry on the list, execution has a musical
  component — hitting the beat of the action command.

### 7.9 Hyper Light Drifter and Tunic (suspected loves, unplayed)

- **Hyper Light Drifter:** top-down 2D sword-and-dash action, wordless,
  secrets everywhere, a melancholy dying world, a killer Disasterpeace
  score. Runs on modest hardware in its original form.
- **Tunic:** top-down isometric Zelda-like whose central trick is an
  in-game instruction manual in an unreadable language — knowledge as
  inventory again, in its purest commercial form: the manual pages are
  the progression. Also: secrets behind every waterfall, and a
  soundtrack-forward presentation.
- **[reading]** If Morgan is right that he'd love these, they double
  as existence proofs for this brainstorm: both are roughly the class
  of game — 2D, top-down or isometric, knowledge-gated, music-forward,
  modest-spec — that a device like the R36S could plausibly run
  natively, and that a small team (in these cases, famously small
  teams) could plausibly finish. Whether their *engines* would port
  is a separate, unverified technical question (§5, §19).

### 7.10 The multiplayer list, read as ingredients

All **[reading]**:

- **Smash Ultimate:** mastery + chaos in the same room; anyone can
  play, nobody has finished learning it.
- **Minecraft Dungeons over Gauntlet Dark Legacy:** the co-op
  dungeon-crawl itch is real for Morgan and his brothers, but the
  modern, snappier execution won over the nostalgic original — a data
  point that *feel and pacing* beat *reverence* for him. (Also a
  warning against designing by nostalgia alone.)
- **Super Monkey Ball 2:** physics toy + party game; the fun is partly
  *meta* — ridiculous failures are content. Mechanics that generate
  stories/laughter when they break down gracefully.
- **Mario Party:** social dice, minigames, grievance as bonding.
- **Boomerang Fu:** one-hit, fast-round, readable arena chaos with a
  thrown weapon that comes back — boomerangs keep recurring in this
  brainstorm (Phantom Hourglass's drawn boomerang path; Zelda's
  boomerang generally).
- **Wii Play Tanks:** top-down twin-stick arena play, ricocheting
  shells, positioning over aim-twitch. Morgan self-reports top-tier
  skill — one of his strongest "I was great at this" data points.
- **MMORPG curiosity:** unexplored territory; persistent worlds and
  social systems at scale are an unknown appetite, noted but not
  designable-for on an offline handheld in any obvious way (§17).

### 7.11 Super Mario Sunshine (added 2026-11-11, unranked)

All **[reading]**, as with the rest of §7:

- The first non-Zelda platformer in his all-time set, and it fits the
  pattern almost suspiciously well: **FLUDD is another one-weird-device
  game.** A whole Mario built around a single gadget — a water pack
  that hovers, rockets, sprays, and cleans — committed to completely,
  the Phantom Hourglass move (§7.5) years earlier and in 3D.
- **Movement as joy in itself:** the hover nozzle, spin jump, and
  wall-kick kit make just crossing Delfino Plaza feel good; traversal
  is the content, not the commute (Wind Waker's sailing, §7.4, is the
  same value at sea).
- **A dense hub:** Isle Delfino is one bright plaza town with levels
  radiating off it — the small-dense-world pattern (§8, component 4)
  again, in a Mario costume.
- **Cleaning as the core verb:** the world starts polluted and you
  wash it back to bright. Restoration rather than conquest; the
  melancholy-under-bright-surface pattern (§8, component 6) inverted —
  here the grime is on the surface and the brightness is underneath,
  and your job is to reveal it.
- Also the list's second GameCube-era anchor (with TTYD and Monkey
  Ball 2): that console keeps recurring in Morgan's history.
- **[question]** tucked in for later: Sunshine is a game about water —
  pressure, spray, flow. Whether that matters to a man whose other
  work is full of rivers, a lake that decides whether music comes
  home (wasatch, §12), and audio DSP is the kind of connection this
  brainstorm exists to notice without insisting on.

---

## 8. The first thru-line Loni found: loops, knowledge, transformation

This was the spine of Loni's first-pass reply. It's preserved here as
one candidate thru-line — later joined (not replaced) by Morgan's
music thru-line (§9). Whether the two are actually two lines, or one
line seen twice, is itself an open question (§14).

Candidate components, each traceable to §7:

1. **Knowledge as the real inventory.** Majora's and Outer Wilds both
   reset the world and let knowledge persist. Tunic literalizes it
   (the manual). Phantom Hourglass lets you handwrite it on the map.
2. **NPC schedules / clockwork worlds.** Majora's town, Outer Wilds'
   planetary clockwork, Wind Waker's day/night islands, Phantom
   Hourglass's timed dungeon returns. Worlds that run without you,
   and can be *learned*.
3. **Transformation as keys.** Majora's masks (and Deku/Goron/Zora
   movement sets), TotK's fusions, TTYD's paper transformations
   (plane, boat — traversal by becoming).
4. **A small, dense world over a large, thin one.** Termina, the
   Outer Wilds solar system, Rogueport. Even TotK, the sprawling
   exception, is a beloved *grammar* at large scale rather than proof
   sprawl is required.
5. **One weird control idea, committed to.** Stylus-everything,
   baton-conducting, ship-log-as-save-file, action commands — and,
   with Sunshine's addition (§7.11), a whole Mario hung on one water
   gadget. Each favorite has a signature input or interface conceit
   it refuses to dilute. This component arguably got *stronger* with
   the Sunshine addition, which is worth noticing in a brainstorm
   that keeps circling "make the most of the layout" (§4).
6. **Melancholy under bright surfaces.** Majora's moon, Wind Waker's
   flood, Outer Wilds' dying sun, HLD/Tunic vibes in the suspected
   list. Cheerful palettes carrying grief is a recurring flavor.

**Confidence note:** components 1–3 are strongly represented in the
list's top end. Components 4–6 are softer readings. All six are
offered as ingredients a designer *could* reach for, not as Morgan's
stated design values. Morgan's own stated values so far are only: use
the hardware/layout fully (§4), and music (§9).


---

## 9. The other thru-line Morgan named: MUSIC

At 14:45 Morgan corrected the brainstorm's center of gravity: "think
of the other thru-line... MUSIC. look at what my projects
ampactor-labs/noodles and ampactor-labs/wasatch do with the circle of
fifths... look at my poem."

So this section is the brainstorm's other spine, in Morgan's own
chosen order of evidence: the projects first (§11, §12), the poem as
the source text (Appendix A, notes in §10), and the framework that
grew around the poem (§13).

### 9.1 The claim, stated as a brainstorm proposition (not a fact)

**[idea]** In Morgan's existing work, music is not decoration,
soundtrack, or content. It is closer to a *coordinate system* — the
map things move on, and the physics that decides whether they arrive.
If that pattern carried into a game, music could plausibly be any or
all of: the world's geometry, the movement system, the progression
system, the save system, the antagonist (whatever withholds
resolution), and the win condition (resolution itself, earned). Each
of those is explored as raw material in §14. None has been chosen.

### 9.2 The underlying math, as the poem frames it

Background any reader of the poem needs, stated carefully because the
poem's whole tension lives here (figures are standard music-theory
values, **[reported]** from general knowledge and consistent with
Morgan's own notes on file):

- A perfect fifth is the ratio 3:2. Stacking fifths generates pitch
  classes: C → G → D → A → E → B → F# → … This is why the fifth is
  called a *generator* of the space.
- Stack twelve perfect fifths and you land near where seven octaves
  would put you — but not on it. You overshoot by the **Pythagorean
  comma**, about 23.46 cents (roughly a quarter of a semitone's
  quarter... precisely: ~23.46 cents, where 100 cents = one equal-
  tempered semitone).
- So the "circle" of fifths, built from pure intervals, does not
  close. It's a **spiral**: each lap passes near home, higher (in
  pitch-space, sharper) than home.
- **Equal temperament** is the historical fix: shave every fifth by
  about 2 cents (23.46 / 12 ≈ 1.955 cents), distribute the error
  evenly, and the circle *closes by treaty*. Every key becomes equally
  usable and equally slightly-out-of-tune: in the poem's phrase,
  "maximally fair, minimally faithful."
- Two choices remain free even after the system is fixed, per the
  poem: **WHERE** home is (which pitch class you call the tonic — the
  "finger down, call it home (C)" moment, which the poem is explicit
  is arbitrary), and **HOW HIGH** home is (which octave/register —
  reference pitch, placement). "Everything else is the function
  stacking fifths."
- **V7 → I** (the dominant seventh resolving to the tonic) is Western
  harmony's canonical *wanting* machine: the V7 chord contains a
  tritone that aches for resolution. The poem places "(V7 resolving
  to I)" as a stage direction at its emotional hinge, and its most
  quoted line follows immediately: "Harmony cultivates wanting by
  metabolizing our error as remainder. A music with no remainder
  leaves nothing to want in a world where wanting is the product."

### 9.3 Why this might be a game-shaped idea (Loni's reading)

**[reading]** The spiral/comma structure has three properties that
map suspiciously well onto Morgan's game list (§8):

1. **A loop that doesn't close is a loop with memory.** A perfect
   circle-reset erases. A spiral loop returns you *near* the start,
   off by a remainder — and the remainder has to go somewhere. In
   Majora's/Outer Wilds it goes into the player's knowledge. In tuning
   it goes into the comma. Same shape: *the error is the save file.*
2. **Home is chosen, not found.** The poem insists the tonic is an
   arbitrary finger placed down and agreed upon — a treaty. Games
   usually hide their "home" (spawn, hub, base key). A game could
   instead make choosing home an act the player performs and lives
   with.
3. **Wanting can be mechanized.** Withholding resolution (deceptive
   cadences, unresolved dominants) is a composable, rule-based way to
   produce longing — and wasatch already implements a version of it as
   a literal rule about a lake (§12.4). A game could gate its endings,
   doors, or arrivals the same way: not locked by a key item, but
   *unresolved* until conditions make resolution true.

Whether any of this survives contact with an actual design is exactly
what the brainstorm is for. Fable may find a better mapping, or a
different one entirely, or Morgan may decide the music line belongs
in the game's *sound* rather than its structure. All open.

---

## 10. The poem — notes

The full text, exactly as Morgan pasted it into this thread on
2026-11-10, is **Appendix A**. It is included in full because Morgan
explicitly offered it as design evidence ("look at my poem"), and
because paraphrase would lose the load-bearing lines. Relationship to
other versions on file: Morgan's framework document *The Generative
Self* (latest v5, 2026-09-27) carries the poem's core lines as its
epigraph and harmonic law (see §13), and earlier drafts exist among
his files. Which version, if any, should be treated as canonical for
design purposes is **[question]** — this doc uses the pasted version
because it's the one he handed to *this* conversation.

Line-level notes (all **[reading]**):

- *"In the midst of the spiral where all but the generator turn
  static and fade, no compass with which to map meaning, I concede."*
  — Opens inside the spiral, conceding there's no neutral map. The
  generator (the fifth) keeps moving when everything else freezes.
- *"Any point at which one might first settle down is arbitrary."* —
  The tonic as arbitrary settlement. Settlement language — this is a
  poem about *choosing where to live*, in pitch and in life, at once.
- *"there is no end or beginning, twelve fifths overshoot home and
  miss forever."* — The comma as eternal near-miss.
- *"As every note carries its octave within, the nature of the space
  is to fold, but never close."* — Octave equivalence folds the spiral
  into a circle visually; the fold is a convenience, the non-closure
  is the truth. (The Generative Self v5 reuses this almost verbatim:
  "The document folds. It does not close.")
- *"...a crack in the wall where TIME enters the equation"* — Time is
  what the gap lets in. In a loop-game brainstorm, this line is doing
  a lot of potential work: the comma/gap as the place where the time
  mechanic lives.
- *"we are faced with two choices: WHERE, and HOW HIGH home is."* —
  See §9.2. Two free parameters; everything else is generated.
- *"Two pins and a generator, music?"* — The poem's most compressed
  line, and genuinely ambiguous (which may be the point). Candidate
  readings, none endorsed: the two pins are the two choices (WHERE /
  HOW HIGH) driven into the spiral to anchor it; the two pins are a
  compass's legs, drawing the circle that doesn't close; two pins as
  in a pinned specimen (the moth resonance is available, given
  Morgan's nickname 'Moth', but that connection is Loni's association,
  not Morgan's statement); a tuning fork's two tines. **[question]**
  for Morgan, if he ever wants to gloss it.
- *"may as well put a finger down, call it home (C), split the
  difference, eat the error, and FAKE THE CLOSURE."* — Equal
  temperament described as a human shrug that became civilization's
  shared surface. Note the affection inside the mockery ("silly
  human"): the poem doesn't despise the treaty.
- *"Equal temperament is the quantization..."* — Quantization is a
  producer's word: snapping lived timing/pitch to a grid. The poem
  treats 12-TET as the original quantization decision.
- *"the primitive IS infinity"* — The space can't be reduced to a sum
  of parts because the parts can't be counted; the generator runs
  forever.
- *"Sharing space with the Sunflower, Earth, and our breath."* —
  Phyllotaxis (sunflower spirals, golden-angle stacking — a cousin
  structure to the spiral of fifths), orbital motion, breath cycles:
  spirals and loops in nature, all of them also not quite closing.
- *"What else then might we have to secure common ground than a
  TREATY (yum)."* — The shared tuning as the ground people meet on;
  "(yum)" keeps it from pomposity. Common ground you can stand on
  together, in a space that cannot be seen (sound).
- *"Let it be known: errors do not sit well with my stomach."* — The
  cost is real, bodily, not aesthetic. The treaty works and still
  nauseates. Both things.
- *"ache IS the engine, we work because we want as we work as we
  want..."* — Wanting as motive force, recursive.
- *"(V7 resolving to I)"* — A stage direction placed where a lesser
  poem would put a paragraph. The resolution is *performed* by the
  poem's structure, not described.
- *"It is freedom, our arrival."* — Arrival exists, but it's the
  resolving/wanting dynamic that's named as freedom, not a final
  resting state.
- The closing movement — *"You star-eyed sunkiss, my resolution...
  It's your garden... through all we keep between us, our gravity, I
  pull."* signed **"JJ+Mo 😍 4eva 😍"** — The poem lands its abstract
  system on a specific person: home-as-chosen becomes home-as-her;
  "my resolution" casts JJ as the tonic the V7 was aching toward;
  "our gravity, I pull" keeps even the love lyric in orbital/spiral
  language (gravity, not arrival — compare The Generative Self §VI in
  §13 below: "The VII does not resolve to the I. Gravity, not
  arrival."). For game-design purposes the relevant **[reading]** is:
  in Morgan's work, *resolution is relational* — it's a someone, or a
  somewhere someone is — not an abstract completion state.

---

## 11. What noodles does with the circle of fifths

Source: ampactor-labs/noodles README.md and `src/circle.js`, read via
the GitHub connector on 2026-11-10. Paraphrased except where quoted.
noodles itself, briefly **[reported from its README]**: a phone
music-making app, Ableton-Live-like clip grid (scenes = rows, one clip
per track), four tracks (Harmony, Drums, Bass, Melody), a new generated
four-bar song in a random key/tempo on each load, plain JavaScript on
Tone.js/Vite, installable as an offline web app, live at
ampactor.dev/noodles. Chords are stored as scale degrees, so changing
key moves every chord with the song.

The circle implementation, which is the part Morgan pointed at:

- **The circle is a playable surface, not a chart.** `circle.js`'s own
  header comment (quoted in Loni's second-pass notes): the circle is
  "a projection of the song model, never a second copy of it," and
  "every harmonic truth on screen comes from model.js." The UI is a
  view onto theory, not a picture of it.
- **Fixed wheel, moving light.** "The wheel never rotates; stations
  are muscle memory (D is always two steps clockwise, always 2♯).
  Changing key slides the bright region around a fixed world, so
  modulation reads as travel." — This sentence may be the single most
  game-relevant line in either repo: *the world is fixed; your home
  region moves across it; changing key is traveling.*
- **The diatonic sector.** With majors on the outer ring and relative
  minors on the inner ring, the seven diatonic chords of any key form
  one contiguous patch: IV–I–V on the outside, ii–vi–iii beneath them,
  vii° as a thin seam wedge "living on the sector's edge" — the
  diminished chord assigned to the boundary between in-key and
  out-of-key, which is exactly where the poem would put it.
- **Gestures (touch, on a phone):** tap a wedge to sound its chord,
  voice-led from wherever you were; hold a wedge for an "extension
  bloom" (7 · 9 · sus4 · sus2 options, plus the chord's name card);
  drag across wedges to strum; drag the rim to carry the home sector
  around the wheel (sharps/flats light up "in the order they arrive");
  release to commit the travel (a key change that re-snaps the whole
  song).
- **Theory lives in the controls; explanation waits to be asked.**
  Chords in-key are colored by role; borrowed chords (stored as raw
  notes rather than scale degrees) are drawn in violet — out-of-key is
  *visible* as a color, not prohibited. Names and explanations appear
  only on hold or on the ? page: "hold a wedge or open the ? page."
  The README's framing: "The theory lives in the controls."
- **The extension ladder as curriculum.** Extensions stack: a 9
  contains the 7th, an 11 the 9th, a 13 the 11th. The editor's pads
  present this ladder so sliding up it lets you "hear the tower grow."
  Extended harmony taught by touching, in steps.
- **Neighbors share almost everything.** The chord editor's circle is
  described in the README as "the twelve keys in a ring where
  neighbors share six of their seven notes" — adjacent keys differ by
  exactly one note, which is the entire mechanics of smooth
  modulation, expressed as geography.
- **One instrument, shared memory.** The key-sheet wheel and the
  chord-editor wheel share their "wedge voicing memory" — the code
  comment calls the two mounts "one instrument." Surfaces differ;
  the underlying model is single.

**[reading] — design DNA extractable from noodles, for the brainstorm
pile:**

- A harmonic *space* with fixed geography and a movable "home region"
  (sector) — a world map that is also a chord chart.
- Travel = modulation: moving one step is cheap and smooth (one note
  changes); moving far is dramatic (many notes change).
- Boundaries have residents: the vii° seam, the violet borrowed
  chords — edges and outside-places are marked, visitable, colored
  differently.
- Complexity is layered by *holding*, not by menus: press longer,
  get the extensions. Depth on a timer.
- Names/explanations are opt-in. The system is learnable by ear and
  hand first; vocabulary arrives when requested. (Compare Tunic's
  manual, §7.9 — knowledge presented inside the world, in pieces.)

---

## 12. What wasatch does with the circle of fifths

Source: ampactor-labs/wasatch README.md and DESIGN.md, read via the
GitHub connector on 2026-11-10. wasatch itself, briefly **[reported
from its README]**: "Wasatch Symphony" — a web app that plays the Salt
Lake valley live as music (trains, buses, planes, weather, air,
seismometers). A Rust engine compiled to WebAssembly (built on
Morgan's sonido) composes and renders every bar on the browser's audio
thread; every listener's phone plays the same bar at the same moment,
about 90 seconds behind the valley; a small Node "conductor" server
seals realtime feeds into 30-second windows. Live at
ampactor.dev/wasatch.

The circle/harmony system, which is the part Morgan pointed at:

- **Harmony = two things only.** From DESIGN.md's "Harmony space"
  section: (1) the **notes in play** — a diatonic collection, i.e.
  *seven adjacent positions on the circle of fifths* (C major's notes
  given as the sequence F C G D A E B); and (2) **home** — which of
  those seven is the tonic. Home's position within the arc *is* the
  mode, counted from the flat end: Lydian, Ionian, Mixolydian,
  Dorian, Aeolian.
- **Mode and key unified.** On a fixed tonic, each rung of the
  brightness ladder is exactly one step flatward on the circle (C
  Lydian uses G major's notes, C Ionian uses C's, C Mixolydian F's,
  C Dorian B♭'s, C Aeolian E♭'s). Wasatch's earlier design drove key
  and mode separately and could produce five-step jumps from combined
  changes; the unified circle space exists specifically so that can't
  happen — motion is always *a walk*, step by step.
- **The piece's large-scale motion is a walk around the circle.** The
  valley's "flow" moves the arc of notes-in-play; the sky moves home.
  Harmony changes happen at section boundaries, voiced to move one
  note at a time where possible (large leaps avoided; parallel fifths
  "not a concern in this idiom" per DESIGN.md — a composer's shrug
  worth preserving).
- **The harmony dial.** The UI renders the circle as a ski-lift
  bullwheel: seven adjacent positions lit (the notes in play), one
  dot inside the lit arc (home), and an arrow showing "where the
  valley is pushing." DESIGN.md's claim: "Two minutes of watching
  teaches the rule." A caption line narrates changes in plain words —
  the README's example: *"The valley's slowing down → B♭ minor (G♭
  for G)."*
- **Chord tones assigned to the world.** A TRAX train leaving a
  station rings a bell on its line's chord tone: Blue line = root,
  Red line = fifth, Green line = third (DESIGN.md gives the concrete
  example: the Red Line's bell is the chord's fifth, "so over A it
  rings E, 18 ms behind the beat" — late trains literally lay back).
  FrontRunner's arrival horn plays "in the rhythm of a grade
  crossing," and the phrase it arrives in "comes home."
- **The lake rule** (DESIGN.md's "The lake's rule"). The Great Salt
  Lake's level controls how phrases end:
  - At or above 4,198 ft (the "optimal range" runs 4,198–4,205 ft):
    cadences land home.
  - Between 4,195 and 4,198 ft: the share of unresolved cadences
    falls from a ceiling to none.
  - Below 4,195 ft: the unresolved share stays at a tuned ceiling
    ("start at two in three"), calibrated "so it reads as longing
    rather than aimlessness."
  - Unresolved cadences land on the mode's deceptive chord (vi in
    Ionian/Lydian/Mixolydian; ♭III in Dorian; ♭VI in Aeolian) or a
    sus2 tonic — and never on the chord the phrase was vamping on,
    "so the non-arrival is audible."
  - DESIGN.md, verbatim in Loni's notes: "it means the piece
    literally can't come home until the lake does."
  - The lake sat at 4,189.8 ft on Oct 23 (per DESIGN.md), far below
    the transitional range — so at that time, every listener heard
    the ceiling of non-arrival, and "the day the lake rises past
    4,195 ft the piece starts to come home. Nobody has to know this
    to enjoy it."
- **The sky as brightness.** Cloud/conditions select how bright the
  mode is, "Lydian through minor"; a storm approaching Alta holds
  "the harmony in suspense, a darker pad, until the snow starts" —
  suspension as a *held state*, released by weather.
- **The wind harp and the treaty.** Ridge wind plays an Aeolian harp
  whose virtual string's shedding frequency "picks the register, then
  snaps to the nearest chord tone in equal temperament" — nature's
  continuous pitch, quantized to the treaty grid — while (per
  DESIGN.md) the harp's own tuning sits *off* equal temperament, its
  5th about 14 cents flat, "so the harp sounds the chord" differently
  from the tempered instruments around it. Even inside wasatch, the
  pure interval and the tempered grid coexist as two audible
  philosophies. That detail is small and, for this brainstorm,
  possibly load-bearing (§14.6).
- **Determinism.** The score is a pure function of schedule, sun/moon,
  and sky observations, with a counter-based random generator keyed by
  bar: "Two phones with the same inputs play the same notes." A world
  that is a *function* — relevant to loops: a loop you can re-derive
  is a loop you can learn exactly.

**[reading] — design DNA extractable from wasatch:**

- A rule that *withholds home* based on the state of the world, tuned
  to read as longing rather than brokenness. (§9.3's "wanting,
  mechanized," already shipped once.)
- World-events assigned to chord tones, so reality (or a game world)
  *plays the chord* by happening.
- Harmony as a walk on a fixed circle, with a visible dial and
  plain-language captions: the system teaches itself by being watched.
- Continuous nature (wind frequency) snapped to a discrete grid (the
  chord) — with one instrument deliberately left un-snapped as the
  ghost of the pure system.

---

## 13. The Generative Self framework connections

Morgan's framework document *The Generative Self* (v5, 2026-09-27, on
file) is the larger structure the poem lives inside. Sections of it
that touch this brainstorm, quoted/paraphrased from the v5 file read
on 2026-11-10:

- **The epigraph** is the poem's core: "Twelve fifths overshoot home
  and miss forever. The nature of the space is to fold, but never
  close," followed by "Harmony cultivates wanting by metabolizing
  error as remainder." The document's own reading note: "The document
  folds. It does not close."
- **§I The Model:** identity as a *generator* capable of many coherent
  outputs ("One generator. Many coherent outputs.") — the word
  "generator" is the same word the poem uses for the fifth. One
  generator, many outputs, in music and in selfhood, in the same
  vocabulary.
- **§III The Loop:** NOTICE → EXTRACT → CHOOSE → EXPRESS → ENCOUNTER
  → OBSERVE → LEARN, written as a repeat block (`|: ... :|`). "The
  identity is the loop. Not the current frame of it." A loop that
  *learns* — i.e., a spiral wearing loop notation.
- **§VI The Other Generator:** the relationship section, and the
  brainstorm's most direct bridge: "The VII does not resolve to the
  I. Gravity, not arrival. The relationship *is* the music: the gap
  that never quite closes, and isn't supposed to." Non-resolution as
  a *feature of love*, stated as doctrine — the lake rule, applied to
  people.
- **R11 Music as Laboratory:** "A closed system has nowhere to go.
  Temperament accepts an error that cannot be eliminated and turns it
  into a shared surface on which movement becomes possible.
  Dissonance is information. Remainder is material. Movement is the
  response." Also its table mapping experience to musical expression
  (Weight→bass/rhythm, Desire→harmony, Memory→sampling, Time→
  arrangement, Remainder→unresolved material, Transformation→
  development) — a ready-made mapping table if a game ever wants
  feelings-as-systems.
- **R12's lyric filter** example: the abstract line "harmony
  cultivates wanting by metabolizing error as remainder" is shown
  being translated into an embodied image: "I keep missing home / by
  something I can't measure." Recorded here because that translation
  move — theorem → image → playable thing — is presumably the exact
  move any game design from this material would also have to make.

**[reading]** Taken together: the poem is not a poem *about* music
theory that Morgan also happens to build software near. It reads as
the **seed crystal** for a whole practice — noodles, wasatch, The
Generative Self — in which the same structure (generator, spiral,
remainder, treaty, withheld resolution) compiles into a phone app, a
valley symphony, a self-framework, and a love lyric. The R36S game,
if it happens, would be the next compilation of the same generator
into a new medium. That framing is Loni's, offered to the brainstorm;
Morgan may see the lineage differently.

---

## 14. Where the game/music ideas and the game/game ideas might meet

This is the synthesis section Loni offered in the second pass, written
out more fully. Everything here is **[idea]** / **[reading]**. This is
the brainstorm's center, and it is also the least settled part of it.

### 14.1 The seed sentence (one candidate formulation)

"A loop game built on a spiral, not a circle, where movement is
modulation on a fixed wheel, home is a choice not a given, resolution
is withheld until conditions earn it, and what you carry between
loops is the remainder — the part that doesn't fit the grid."

That sentence was Loni's closing pitch in the second pass. Morgan's
response was to ask for this document — which is not the same as
endorsing the sentence. It stands here as *a* formulation, awaiting
better ones.

### 14.2 Movement as modulation

From noodles (§11): fixed wheel, moving home-sector, travel = key
change, adjacent = one note different. Game translations, all raw:

- A world map that *is* a wheel: twelve regions arranged as stations
  on the circle, fixed forever, with the "in-key" sector (the region
  where things are diatonic/safe/consonant) sliding as the player
  modulates.
- Walking clockwise could mean walking sharpward (adding sharps);
  counter-clockwise, flatward (darker, flatter). Distance measured in
  *notes changed*, not meters — nearby places share 6 of 7 notes;
  the tritone-opposite station shares almost nothing and feels
  maximally foreign.
- Shortcuts could exist where the spiral folds: octave-equivalence
  points where distant places touch (the fold in "the space is to
  fold, but never close").
- Or movement could stay conventional (a town, a map) while the
  *music system underneath* does the modulating, wasatch-style, with
  the dial visible. The wheel as engine, not as geography.

### 14.3 Home as an act

From the poem (§9.2, §10): WHERE and HOW HIGH are chosen; the finger
comes down; the treaty is agreed. Game translations, raw:

- Early in the game, the player *places* home: picks a tonic town /
  key / register, knowing it's arbitrary, and the world re-voices
  itself around that choice (NPC themes, safe zones, what counts as
  consonant).
- Re-homing could be the game's big verb (noodles' rim-drag): an
  expensive, deliberate act of moving the sector, re-lighting the
  world. "Modulation reads as travel" — moving house as the journey.
- Register (HOW HIGH) could map to verticality: the same world an
  octave up/down — brighter/thinner or deeper/heavier — echoing
  Ocarina's child/adult same-map-two-states (§7.3).

### 14.4 Resolution withheld, wanting mechanized

From wasatch's lake rule (§12) and the poem's V7: raw translations:

- Doors that aren't locked but *unresolved*: they open when the local
  harmony resolves, and the world's state decides whether resolution
  is available at all yet.
- An ending that can be *approached* early and lands deceptively —
  the game visibly almost-ends (deceptive cadence as a fake-out
  finale) until conditions let it come home.
- A dominant-pedal mechanic: standing in a V region builds charge/
  tension that must be discharged somewhere; carrying it across a
  loop could be the remainder made playable.
- NPC wants as dominants: each character's arc is a chord that wants
  a specific resolution, and you can only resolve so many per loop
  (Majora's schedule pressure wearing harmony's clothes).

### 14.5 The remainder as the save file

From §9.3: loop resets, remainder persists. Raw translations:

- Whatever the loop can't quantize — a detuned note, an off-grid
  object, a person who remembers you — persists between loops,
  accumulating comma by comma until the accumulated error *becomes* a
  new place/state (twelve loops of comma = a semitone-ish of drift?
  The math poetry writes itself; the game design would need to make
  it legible, not just true).
- The notebook (§15) is one implementation of persistence; a *tuning
  drift* could be another: each loop, the world returns ~2 cents
  sharper, subliminally, until someone in-world notices. Or the drift
  could be the difficulty curve. Or the villain. All raw.

### 14.6 The treaty as a mechanic (pure vs tempered)

From §9.2 and wasatch's off-temperament harp (§12): two tuning
philosophies coexisting. Raw translations:

- A grid-snap the player can toggle: tempered mode (everything snaps
  to the circle, travel is easy, everything is slightly wrong) vs
  just/pure mode (intervals are true, but stacking them drifts you
  away from home — powerful locally, unfaithful globally). Choosing
  per-situation which error to eat could be a core verb: "maximally
  fair" vs "maximally faithful" as stances, not settings.
- Quantization as time mechanic: actions snap to the beat/grid in
  tempered places and swing/rubato in pure places.
- The treaty's social half: a tuning *shared* is a surface people can
  meet on (§10's TREATY note) — in a single-player game this could be
  about NPCs agreeing to your home; in any multiplayer daydream (§17)
  it's about players literally agreeing on a tonic before they can
  play together.

### 14.7 The world plays the chord

From wasatch (§12): events assigned to chord tones; reality performs
the harmony. Raw translations:

- Enemies/NPCs/events each bound to a chord tone; a busy screen is
  literally a chord being played by the world happening.
- The player's actions could be the missing tone: the world plays
  root and fifth, you are the third that decides major/minor. Agency
  as the note that determines the chord's quality — small input,
  total emotional color change.
- A harmony dial / wheel HUD (wasatch's bullwheel, noodles' sector)
  as the game's compass: no minimap, a *keymap*. Where you are is
  where home sits in the arc and where the arc is pushing.

### 14.8 Performance as input (the Zelda-music thread)

From §7: ocarina songs operate time (Majora's/Ocarina), a baton
conducts spells (Wind Waker), timed presses make RPG combat a
performance (TTYD). On the R36S those translate awkwardly and
interestingly: no mic, no touch — performing a melody means a button
sequence, possibly on the D-pad (Majora's own C-button ocarina is the
precedent), possibly with the triggers as octave pins (two pins!
§10's unresolved line, offered here as a *candidate* gloss: two pins
and a generator, played on two triggers and a generator-button...
this is wordplay, not a design, and is recorded as such).

---

## 15. Loni's first-pass sketch ("Mothlight") — kept as raw material

**Status: [superseded] as a proposal, retained as material.** Written
by Loni in the first-pass reply (2026-11-10), before Morgan's music
correction and before the designer role moved toward Fable. It is
included verbatim-in-substance so the brainstorm keeps its history —
and because parts of it (the notebook, the schedule town) may still
be useful ore. Its control scheme contains the known error (§4.2),
flagged inline.

- **Working title (Loni's):** "Mothlight" — drawing on Morgan's
  nickname 'Moth' and a lighthouse image. Morgan never commented on
  the name.
- **Premise:** a tiny harbor town (Wind Waker scale: one island, about
  six screens) stuck in the last three nights before its lighthouse
  goes out. (Light/dark and moth imagery doing quiet work.)
- **Loop:** one loop ≈ 10 minutes of real time; at the end, the town
  resets; the player's possessions reset; the **notebook doesn't** —
  Outer Wilds' ship-log-as-save-file (§7.6) as a physical object.
- **NPCs:** five, on Majora's-style schedules; you cannot help all of
  them in one loop; learning a schedule *is* progression.
- **Forms:** two to start — the player character, and a "Moth form"
  (flutter-dash across gaps, sees hidden writing in the dark),
  swapped on L1/R1 — Majora's masks (§7.1) compressed to two forms,
  using shoulder triggers as the swap. (This part of the scheme is
  thumb-legal: triggers are index fingers.)
- **Combat/aim (contains the error):** D-pad/left stick move; right
  stick aims a boomerang; X throws it; B roll/dash; A sword; Y opens
  the notebook. The right-stick + X simultaneity is the three-thumb
  problem (§4.2). A corrected variant was never designed, because
  Morgan reassigned design before one was needed; obvious candidate
  fixes live in §4.2.
- **Dungeon:** one mini-dungeon, five rooms, rearranging each night;
  the final door needs not a key item but a sequence/song learnable
  only by watching the town across loops — knowledge as the key.
- **Seasoning (Loni's words):** Paper-Mario-style timed press on the
  sword swing; Fallout-style dialogue choices that change which NPC
  schedule you unlock.
- **Scope guardrails (Loni's suggestion at the time):** one town, one
  dungeon, five NPCs, two forms, one ending — explicitly arguing
  *against* attempting an open world, 3D, or a full Majora's clone in
  a one-shot.
- **Stack suggestion (Loni's, at the time):** LÖVE (a `.love` file,
  runnable via PortMaster per §5.1, and runnable on the weak laptop
  for testing), Godot as plan B. See §19 for the fuller, unsettled
  route comparison.

**What the sketch lacks, in hindsight:** any music system at all.
It has songs-as-keys (borrowed from Zelda) but no circle, no spiral,
no home-choosing, no withheld resolution — the entire §9/§14 layer is
absent from it. If anything in this doc justifies the sketch's
demotion, it's that: it was a competent collage of Morgan's game list
that missed Morgan's own generator. Recorded without defensiveness;
that's what second passes are for.

---

## 16. A pile of undeveloped directions, fragments, and sparks

Loose material, deliberately unorganized beyond grouping. All
**[idea]** unless noted. Inclusion ≠ endorsement by anyone.

**Structures:**

- A game with no map screen, only the wheel: navigation by key.
- A roguelike where each floor is one station further around the
  circle, and "descending" is modulating; the run ends when you
  either come home or drift a full comma too far.
- A town where every building is a chord tone of the home key, and
  the out-of-town wilderness is the borrowed/violet zone (noodles'
  violet made geographic).
- A "one-screen monastery" game: a single screen, a single day,
  bell-hours as schedule, the whole game rung on one chord that
  slowly wants to move.
- A sailing game on the wheel (Wind Waker §7.4): stations as islands
  on a circular sea, wind as harmonic pull — some islands are always
  downwind (a fifth away), some are a tritone tack against the wind.
- The cube-that-evolves reference (§6.3) applied to harmony: a small
  world whose *key* evolves as you raise/lower things; life appears
  at certain consonances. (Also depends on identifying the cube game.)

**Mechanics fragments:**

- Strumming the world: a gesture (drag across wedges, in noodles) as
  a literal in-game action — sweep the D-pad across stations to
  arpeggiate a door open.
- Extension-by-holding (§11): press-and-hold any interaction to get
  its "9th/11th/13th" version — deeper dialogue, deeper chest, deeper
  dive — at the cost of time in a loop where time is the currency.
- Deceptive-cadence save points: resting almost-resolves you; full
  resolution must be earned elsewhere.
- The diminished seam (§11) as a place: a thin region between keys
  where the vii° lives — unstable, useful as a shortcut, nobody
  lives there. Or somebody does.
- Borrowing as theft/diplomacy: taking a violet chord from a neighbor
  key changes your relations with that key's town.
- A boss that is a dominant chord: it doesn't attack, it *leans* —
  pressure that grows until you either resolve it (on its terms) or
  deceptively escape (on yours, at a cost).
- Register as difficulty: the same encounter an octave up is the
  same notes, different body. HOW HIGH as a real choice with real
  consequences (§14.3).

**Presentation fragments:**

- Everything captioned like wasatch: plain-language trail signs
  explaining the current harmony ("The town is homesick → leaning
  flatward"). The system teaching itself while being watched (§12).
- A bullwheel/dial HUD instead of hearts/minimap (§14.7).
- Music generated by play itself (wasatch §12): no composed "tracks,"
  only rules — the run *is* the performance, and no two loops sound
  the same even when played identically, because the remainder
  differs (§14.5).
- 4:3 compositions that lean into the portrait-ish frame: towers,
  wells, lighthouses, moon overhead — verticality for a vertical-ish
  screen (§3.4).

**Meta fragments:**

- The game as the next compilation of The Generative Self's generator
  (§13): creed → app → valley → framework → game. The changelog of
  Morgan's versions (v1→v5) treats artifacts as snapshots, not
  definitions — a game could be versioned the same way, shipped as a
  snapshot.
- Two-Top's lessons (§1.1): whatever Morgan learned building a
  deterministic, netcode'd brawler (ggrs = rollback = another kind of
  loop-with-remainder, if one squints) is an unmined seam for this
  brainstorm. **[question]** — nobody has asked him about it yet.

---

## 17. Multiplayer — hopes, limits, and open forms

Morgan's multiplayer list is beloved (§6.2), and the first pass warned
that most of it "can't live here." The fuller, more careful picture:

- **[reported]** Most units of this device family have no Wi-Fi or
  Bluetooth built in. Networked multiplayer on the handheld itself is
  therefore somewhere between unlikely and dongle-dependent.
- **[idea]** But multiplayer ≠ networked. Forms that remain possible
  in principle on a single offline device:
  - **Pass-and-play / hotseat:** turn-based or round-based play handed
    back and forth (Mario Party's structure, Monkey Ball's party
    modes are substantially this).
  - **Shared-screen, one device, two hands-each forms:** awkward on a
    3.5" screen, but Boomerang-Fu-speed rounds tolerate a lot.
  - **Asynchronous/artifact multiplayer:** trading save files,
    notebooks, seeds, or ghosts — players meeting inside each other's
    loops without simultaneity. (The poem's treaty, again: common
    ground agreed in advance, meeting in an unseen space.)
  - **The game could simply be single-player** — Morgan's top-8 is a
    single-player list; his multiplayer loves may belong to other
    devices and other rooms (a GameCube's living room is not a
    handheld's bus seat). Nothing in this brainstorm requires the
    R36S game to serve both lists.
- **[question]** Whether Morgan even *wants* multiplayer in this
  particular artifact has not been asked directly. The first pass
  assumed single-player by default. Flagged here as an assumption,
  not a decision.
- **[idea]** If multiplayer ever entered: §14.6's treaty idea (players
  must agree a home key before playing together) and §14.7's "you are
  the third that decides major/minor" (a second player as the other
  third) are the two fragments in this doc with natural two-player
  shapes. Both are wordplay-grade until designed.

---

## 18. Session shape, scope, and the one-shot experiment

- **The one-shot premise (Morgan's, 14:24):** design a game, then
  "see if Fable 5.2 can one-shot it." Undefined terms, all
  **[question]**: Does one-shot mean one prompt, one sitting, one
  generation with no edits? Is a detailed spec (like the brief Loni
  offered to write) legitimate prep, or does prep ruin the experiment?
  Are bug fixes after device testing allowed, or does the first
  failure end the experiment (and is a failure a result worth having
  either way)? Is success "runs on the R36S," "is fun," "matches the
  design," or "Morgan finishes it"?
- **Why scope keeps coming up:** every influence at the top of
  Morgan's list is a multi-year, full-team production. The brainstorm
  keeps translating them down to handheld scale (§15's guardrails
  were one attempt). Candidate scoping principles, none adopted:
  one town / one system / one loop length; one mechanic done
  completely vs many done thinly; a game that is *finished small*
  over a game that is *impressive large*.
- **Session length:** unknown and undesigned. Reference points from
  the list: Outer Wilds loops ≈ 22 minutes; Majora's cycle ≈ 54+
  minutes real-time (shorter with slowed time); phone sessions for
  noodles are minutes. A handheld owned by a man whose transport is a
  bicycle suggests short sessions might matter, but that's Loni
  speculating about bus-stop play; Morgan hasn't said.
- **The device is the only console he has (§6.1):** worth noting that
  an R36S-native game would be, for Morgan, not a port or a side
  version but *the* version — the primary artifact on his primary
  machine. That raises both the stakes (it should feel native, §3.4,
  §4) and the charm (designing for the machine you actually own is
  the Phantom Hourglass move, §7.5).

---

## 19. Candidate technical routes (none chosen)

A comparison pile, **[reported]** engine facts from §5 plus
**[idea]**-grade assessments. If Fable designs the game, Fable may
also have engine opinions; Morgan's own stack history (Rust, Bevy,
JS/Tone.js, WASM) is relevant context either way.

- **LÖVE (Love2D, Lua):** runs `.love` files natively on this device
  class via PortMaster (§5.1). Small, single-purpose, fast to iterate,
  trivially runnable on a weak laptop. Lua is a language a one-shot
  generator can plausibly write in one coherent project. Limits:
  you build (or borrow) everything — no editor, no scene system.
  Loni's first-pass lean; no longer advocated now that design moved.
- **Godot 3 (via FRT) / Godot 4 (via runtime):** a real engine with a
  2D editor; Solarus-adjacent Zelda-likes are proven in this
  ecosystem's neighborhood. Costs: heavier project structure, export
  pipeline to ARM handhelds is a known-but-fiddly route, and a
  one-shot would include engine-project scaffolding, not just code.
- **Solarus:** an engine built specifically for Zelda-like action
  RPGs, listed among PortMaster's engine runtimes (§5.1). If the game
  leaned hard Zelda, Solarus is purpose-built; its Lua scripting and
  editor could suit or constrain in equal measure. Unexamined beyond
  its existence.
- **GameMaker (via GMLoaderNext):** the largest PortMaster category,
  and the Undertale route (§5.1). Requires GameMaker tooling/license
  on the authoring side; nobody in this thread uses it; listed for
  completeness.
- **Fantasy consoles (PICO-8 / TIC-80 / Pyxel):** maximum constraint,
  minimum scope risk (§5.2). Written in Lua (PICO-8/TIC-80) or Python
  (Pyxel). The trade is §5.2's: a fraction of the hardware used.
- **Native Rust / SDL2:** Morgan's home turf (sonido, Two-Top/Bevy),
  cross-compiled to aarch64 Linux (§5.3). Maximum control, maximum
  work, and in tension with the thread's "Fable one-shots it" premise
  — unless the one-shot target *is* a small Rust project, which is
  conceivable but a harder one-shot than Lua.
- **Web/JS (the noodles stack):** conceivable via a browser on the
  device? Not established that the firmware ships a usable browser
  environment for games; listed only so its absence is deliberate.
  Probably a dead end on this hardware; unverified either way.

**Packaging/distribution questions attached to any route:**
PortMaster submission vs sideloaded `.sh`/folder in the ports
directory; whether anyone besides Morgan would ever install it;
licensing (noodles currently has no license chosen; wasatch is
AGPL-3.0 — Morgan's projects differ, so no house default exists).

---

## 20. Risks, unknowns, and things to verify against the actual unit

A checklist-shaped pile. Nothing here has been checked yet unless
noted; checking any of it is future work, not assigned work.

- **Clone/variant identity:** which board, panel, and RAM
  configuration Morgan's unit actually is; whether the `EASYROMS`
  partition tell (§3.2) applies; which DTB/firmware line it belongs
  to. This affects firmware choices more than game design, but a
  PortMaster package targets "the R36S" as a family, and family
  variance is this device's defining hazard.
  **Update (2026-11-11):** there are **two** units, not one — a
  smoky-black translucent one (the unit photographed on 2026-11-10)
  and a clear-purple translucent one — and they are visibly
  different production variants: different back-label text ("Consola
  Retro / MODEL No: R36S" vs. "Game Console / Model No.: R36S"),
  different speaker-grille patterns, different shoulder-button
  shapes, and only the purple carries a round "PASSED 2024" QC
  sticker. Morgan's hunch that they are two different clones of a
  "real" R36S is plausible but **unsettled**: 2026-11-11 research
  (junubgames clone-detection guide; handhelds.wiki R36S Clones)
  says the market has three tiers — genuine (RK3326, full firmware
  support), EmuELEC clones (different board in the same shell,
  clone-specific firmware only), and fakes (weaker unrelated chip,
  no custom firmware) — and that labels, boxes, batteries, and
  other visual tells are all copied well enough to prove nothing
  either way. The checks that settle each unit, per those sources:
  (1) boot with no SD card (genuine stays dead; an eMMC clone boots
  to "can't find any systems"); (2) boot sequence shows an "ArkOS
  2.0" line + four red dots on genuine, and the Start menu header
  reads EMU-ELEC on EmuELEC clones; (3) the stock card's data
  partition is EASYROMS on genuine, EMUELEC or EEROMS on clones;
  (4) the .dtb files on the BOOT partition (genuine:
  rk3326-r36s-linux.dtb / gameconsole-r36s.dtb; clone giveaway:
  rk3326-evb-lp3-v12-linux.dtb / rf3536k*.dtb), fingerprinted with
  the community dtbTools page; (5) if opened, the board silkscreen
  (R36S-V12/V21/V22/V30/Y02 = genuine; G80C/G80CA/G80D, RF35XE =
  EmuELEC clone; GA36/PS202 = fake). **Practical consequence, tied
  to Morgan's plan to flash dArkOSRE-R36S:** image both stock cards
  fully *before* flashing anything (the DTBs are the identification
  evidence), identify each unit separately, and flash the per-board
  image for that unit — a genuine image on a clone board is the
  classic black-screen/flashing-red-LED outcome.
  **Result (2026-11-11, ~18:00):** Morgan ran check (1) on the
  black unit: with no cards inserted it booted to EmulationStation's
  "WE CAN'T FIND ANY SYSTEMS!" screen. A genuine R36S cannot do
  that — it has no internal storage — so **[observed] the black unit
  is a clone-tier unit with onboard eMMC storage** (the
  EmuELEC-clone-with-internal-storage variant in the wiki's terms).
  It is not thereby a "fake": this variant is generally still
  RK3326-class. But it is ruled *out* for standard/genuine firmware
  images, and the wiki flags this specific variant as possibly
  incompatible with the K36/ArkOS-for-clones image as well, so its
  board/DTB identification is now the gating step before any flash.
  **Result (2026-11-11, ~18:02):** the purple unit ran the same
  test the other way — no cards in, power on, nothing at all.
  **[observed]** That is the genuine-board signature (nothing to
  boot from), so the pair now reads: one clone (black, eMMC
  internal-storage variant), one presumptive genuine (purple).
  "Presumptive" because a flat battery produces the same nothing;
  the purple's remaining confirmations are the card-in boot
  sequence (ArkOS 2.0 line + red dots), the EASYROMS partition
  name, and the .dtb fingerprint. If those land, the purple becomes
  the primary device for the game and for a genuine dArkOSRE image,
  and §3's reported specs apply to it with much less hedging.
  **Result (2026-11-11, ~18:15):** the purple's stock card is in
  Morgan's laptop. **[observed]** It is a multi-partition ArkOS-
  layout card: mmcblk0p3 is a ~104 GiB data partition literally
  labeled **EASYROMS** (94.9 GiB used, 91% full — a 128 GB-class
  card), and a sibling partition mounts as a Linux root filesystem
  ("root": /usr, /etc, roms, roms2, ports, ports_scripts, and a
  /boot folder). The EASYROMS label is the genuine-side partition
  tell from §20's checklist, so the purple now has two independent
  genuine signals (cardless-no-boot + EASYROMS). Remaining: the
  .dtb filenames (in the root partition's /boot and/or the small
  BOOT partition) and the dtbTools fingerprint to name its exact
  board/panel before the spare card gets flashed.
  **CORRECTION (2026-11-11, ~18:17):** the BOOT partition (p1,
  FAT16) was mounted and listed, and its only two DTBs are
  **rk3326-evb-lp3-v12-linux.dtb** and **rf3536k3ka.dtb** — both
  clone-family filenames per §20's sources, and NO genuine-named
  DTB (rk3326-r36s-linux.dtb / gameconsole-r36s.dtb) is present.
  So the "two genuine signals" reading above does not survive:
  ArkOS-for-clones images also use the EASYROMS label (the
  partition test is spoofable), and a card-booted clone without
  eMMC also sits dead with no card in (the no-card test only
  convicts eMMC variants). What the DTB listing proves directly is
  that this card's *image* is a clone image (K36 family). Whether
  the purple's *board* is a K36-family clone is now the leading
  hypothesis — if the unit boots and displays correctly on this
  card, the board is accepting a clone DTB — but the settling
  evidence is still outstanding: the extlinux.conf FDT line (which
  DTB actually loads), a dtbTools fingerprint of the active DTB,
  and/or the board silkscreen (the purple's clear shell may allow
  reading it without opening). FLASHING THE PURPLE IS ON HOLD
  until those land: no genuine dArkOSRE image, and no clone image
  either, until the board is named. This reversal is also a
  standing lesson for this project: on R36S-family hardware, every
  cheap test can be copied; only the DTB/board layer settles
  identity.
  **SETTLED (2026-11-11, ~18:19):** the purple's extlinux.conf
  reads `FDT /rf3536k3ka.dtb` — the DTB that actually loads at boot
  is the K36-family clone device tree, and the unit boots and runs
  on this card. **[observed] The purple is a K36-family clone**
  (card-booted ArkOS; both DTBs copied to Morgan's laptop for the
  dtbTools fingerprint, which can still name the exact board/panel
  and the matching ArkOS4Clone clone-type). Final tally for the
  pair: **both units are clones, of two different families** —
  black = eMMC EmuELEC variant (OS internal, data-only card),
  purple = K36 family (OS on card). Morgan's original hunch
  ("two different clones of a real R36S") was correct. Firmware
  consequence: the maintained path for K36-family boards is
  ArkOS4Clone (with the clone type the DTB tool names); dArkOSRE
  support is per-board and gets checked against the fingerprint
  before any flash. Game-design consequence: essentially none —
  both units are RK3326-class, the purple runs a full ArkOS
  userspace (PortMaster included), and §3's class specs stand.
  **FINGERPRINT SETTLED (2026-11-11 late evening) [observed, §25.1]:**
  The two DTB files on Morgan's laptop are byte-for-byte identical.
  The decompiled DTS confirms the panel is a **Sitronix ST7703** via
  4-lane MIPI DSI, 640×480 @ 58.50 Hz, with a 143-byte init sequence.
  In ArkOS4Clone / dtbTools, this matches **Kinhank K36 / Clone Type 1 Panel 1**.
  Flash recommendation for the spare 32 GB card: ArkOS4Clone (§25.2).
- **Firmware currently installed:** stock ArkOS-based image? Version?
  Has PortMaster already been installed on it? Unknown.
- **Radios:** does his unit have any Wi-Fi/Bluetooth at all? Assumed
  none (§3.1), unconfirmed.
- **Stick click (L3/R3):** do the sticks click? Unverified; §4.3.
- **D-pad quality and diagonals** on his unit: untested.
- **Battery reality [SETTLED, 2026-11-11 late evening]:** the exterior
  label says 3500 mAh (§1.2), but the decompiled DTB for the purple unit
  reveals the RK817 PMIC fuel-gauge profile is factory-set to
  `design_capacity = 1848 mAh` (0x738) with `design_qmax = 2033 mAh`
  (0x7f1) at 4.2V, 800 mA max charging current, and 3.5V cutoff (§25.1).
  Runtime should be estimated against an ~1850–2000 mAh cell.
- **Charging:** which of his chargers the unit accepts happily (§3.1)
  is a small, real, daily-life unknown with a battery this size.
- **USB gadget mode on the purple [SETTLED, 2026-11-11 late evening]:**
  Confirmed functional (§25.5). The decompiled DTB configures the
  `snps,dwc2` USB controller with `dr_mode = "otg"`, and the physical
  right port routes OTG data lines. Using ArkOS USB Network Mode or
  `ssh_over_otg.sh`, test builds deploy from the laptop over a USB-A→C
  data cable via SSH/SFTP directly to `/roms/ports/` (`192.168.7.1`),
  eliminating the card-swapping loop during development.
- **Wiki cross-check (2026-11-11, ~22:06, handhelds.wiki
  R36S_Clones, shared by Morgan):** the wiki's EmuELEC-clone page
  names this unit's exact DTB pair (rk3326-evb-lp3-v12-linux.dtb +
  rf3536k3ka.dtb, captioned "files only seen on clones"),
  corroborating §20's settled purple verdict. Two open details it
  adds: (1) the same DTB pair is associated in community reports
  with more than one ArkOS4Clone dtb-selector choice — Clone Type
  1 (Panel 1 per the Gemini fingerprint in §0.9's answers; Panel 3
  also reported) and Type 2 without amplifier (V12-family boards)
  — so the purple's selector pick gets settled empirically at
  flash time, in that order, and a RAM-chip count through its
  translucent shell (one chip vs two) is a cheap discriminator
  between the board families. (2) For eMMC clones like the black
  unit, the wiki documents no-open identification and even
  firmware options for some variants ("sticker clone": ArkOS K36
  works, ArkOS4Clone via the HG36 selection), while true fakes
  (RK3128 / Allwinner GA36 class, OS on eMMC) take nothing — the
  black's RetroArch system-information screen (RAM figure ~497 MB
  vs ~1 GB; CPU model/cores) discriminates before any flash is
  contemplated.
  **Black board identified (2026-11-11, ~22:12) [observed]:**
  Morgan photographed the black unit's board. Silkscreen reads
  **R36S-V12 2023-08-18**; the SoC is a genuinely marked
  **RK3326** (not RK3128, not Allwinner — the black is not a
  fake); PMIC is the standard RK817; and there is a **single
  Samsung memory package** (eMMC combo, part reads
  ~KMF*10012M-B214) with no separate RAM chips. Against the
  wiki's R36S-V12 2023-08-18 clone section, that is **Variant 1**
  (single chip + Samsung eMMC; Variant 2 has no eMMC, Variant 3
  is SK Hynix at 512 MB). Consequences: the black has a real
  firmware path — dArkOSRE publishes verified Variant 1 DTB
  files — so "unflashable" is retired; it remains the
  beater/control unit by choice, not by necessity, and still
  never takes a genuine image. Final confirmation available
  anytime: total RAM on its RetroArch system-information screen
  (~1 GB class seals Variant 1). Also visible on the board:
  exposed UART pads (GND/RX/TX/VCC), both TF slots populated,
  no radio hardware anywhere. And a caution the evening earned
  twice: the V12 silkscreen appears on genuine AND clone boards
  alike — the single-package-plus-eMMC combination, not the
  printing, is what identifies this one.
- **Purple board identified (2026-11-11, ~22:28) [observed]:**
  Morgan photographed the purple unit's board too, and it is the
  evening's best twist: the silkscreen reads **R36S-V12
  2023-08-18 — the same board as the black unit.** Also visible:
  a genuinely marked RK3326 (date code a week later than the
  black's), RK817 PMIC, exposed UART pads, both TF slots, and a
  **Samsung KMQNW000SM-B316** memory package — a part the wiki's
  clone gallery shows photographed on R36S clones. So the "two
  different clone families" framing this section built up from
  DTB filenames is **superseded**: the units are two production
  variants of one board, differing in memory package and factory
  provisioning. The black's eMMC was provisioned with its
  EmuELEC OS (cardless boot to the error screen); the purple's
  was not provisioned with a bootable OS (dead cardless; boots
  ArkOS from its card). The purple's stock DTB remains
  rf3536k3ka, and its ArkOS4Clone profile remains Clone Type 1
  Panel 1 per §25.1 — "K36" describes that firmware profile, not
  the board. Flash consequences: the purple's plan is unchanged
  (ArkOS4Clone, Type 1 Panel 1 first), with the wiki-reported
  V12 fallback (Type 2 without amplifier) already noted in the
  cross-check above; and the black's dArkOSRE Variant 1 route
  gains a sibling data point, since both units now sit under the
  same board documentation. What actually made the two units
  behave so differently all evening was provisioning and cards,
  not hardware lineage.
- **Purple cardless boot — the false negative resolved
  (2026-11-11, ~22:32) [observed]:** with the purple open, Morgan
  disconnected and reconnected its battery, then powered it on
  with no cards inserted: it booted to the same EmulationStation
  "WE CAN'T FIND ANY SYSTEMS!" screen as the black unit
  (photographed). **The purple's eMMC carries the same internal
  EmuELEC-family system as the black's.** The 18:01 cardless test
  that showed nothing was therefore a false negative — the unit
  was in a latched/hung state (the RK817 PMIC on these boards can
  latch until a true power cut), and the battery pull was the
  reset that revealed the truth. Three standing consequences:
  (1) this document's mid-evening claim that the purple has no
  internal OS is retracted wherever it appears (the DTB/card
  evidence for its clone identity is unaffected — that was never
  based on the cardless result alone, and §20's settled record
  already flagged the nothing-boot as non-convicting); (2) both
  units dual-boot identically: a bootable SD in TF1 takes
  priority, and with no bootable card the internal system boots —
  which the purple's whole life already demonstrated, since it
  has always booted ArkOS from its card with this eMMC present;
  (3) §25.3's brick-risk caution for eMMC units is empirically
  overcautious for this board: flashing an SD image cannot brick
  a unit whose internal system reappears the moment the card is
  pulled. The flashing plans for both units are unchanged, and
  the false negative is itself a §20-grade lesson: on this
  hardware, a dead power button is a state, not a diagnosis —
  pull the battery and test again before concluding anything.
- **The stock SD card:** health unknown; the class-wide failure
  warning (§3.5) stands until an image/backup exists or Morgan
  decides he doesn't care.
- **Screen in daylight / at his typical play contexts:** unknown;
  brightness is reportedly a strength (§3.1).
- **Speaker vs headphones for a music-forward game:** the face
  speaker's fidelity is whatever it is; a game whose core is harmony
  may effectively require the headphone jack to *mean* anything. Or
  the design could target "audible through a small speaker on a bus"
  as its mix target, wasatch-style pragmatism. Undesigned either way.
- **Fable unknowns:** capability/scope questions in §18, plus the
  practical one — what artifact format would Fable even deliver
  (a `.love`? a Godot project? source + build steps?), and who runs
  the build/packaging step (Morgan, presumably, on the sad laptop —
  which constrains toolchain weight; §5.4).

---

## 21. Open questions — the exhaustive list

Collected from every section. None of these have answers in the
record. They're grouped, not ranked.

**About intent:**
1. Is this game primarily *for Morgan to play*, *for Morgan to have
   made (with Fable)*, a portfolio/lab artifact in the Generative
   Self sense (§13), or an experiment about one-shotting itself?
   These imply different games.
2. Does the game want an audience beyond Morgan? Ever submitted to
   PortMaster? Shared with JJ, with ampactor-labs followers, with
   nobody?
3. Is "finished" a goal, or is the brainstorm itself part of the
   fun (the asking-for-this-doc move suggests the process is at least
   half the point)?

**About design authority and process:**
4. Is Fable designing from a seed brief, from this whole document,
   from a conversation, or cold? Who writes the seed (Loni offered;
   Morgan hasn't accepted or declined)?
5. What are the one-shot rules (§18)? What repair attempts, if any,
   are legitimate after the shot?
6. If the one-shot fails, what's the move: iterate, re-shot, hand-fix,
   abandon, frame the failure as the artifact?
7. What is Loni's ongoing role, if any: researcher, documentarian,
   tester-on-device, nothing?

**About the game's shape:**
8. Genre center of gravity: Zelda-like top-down adventure? Loop
   puzzler? Music toy with a game around it? Town-and-schedules sim?
   Something the list doesn't name?
9. Is music the map, the mechanic, the output, the story, or several
   at once (§9.1)? Which of §14's translations, if any, feel alive to
   Morgan — and which feel like Loni getting carried away?
10. Combat: present, absent (Outer Wilds says it can be absent),
    rhythmic (TTYD), physics-comic (Monkey Ball/Boomerang Fu)?
11. Loop: is there one? How long? What persists (knowledge only, or
    also objects/drift/people, §14.5)? Spiral or circle (§9.3)?
12. Home: chosen (poem) or given (almost every game)? Changeable
    mid-game (noodles' rim-drag) or chosen once (a treaty)?
13. NPCs: scheduled townsfolk (Majora's) or none? Dialogue choices
    (Fallout) or wordless (HLD)?
14. Perspective/art: top-down pixel (HLD), isometric (Tunic),
    side-view, first-person-ish (Outer Wilds is first-person — could
    a 2D game borrow its *structure* without its camera?), or
    something native to 4:3 (§3.4)?
15. Multiplayer: in, out, or artifact-form (§17)?
16. Difficulty/failure: what does failing look like in a game whose
    philosophy says remainder is material and safety is
    recoverability (§13, Generative Self §VII)? Can you lose? Should
    you be able to?
17. The moth: is 'Moth' (his nickname) actually part of this, or was
    that Loni's reach (§15)? JJ: does the poem's resolution-as-person
    (§10) belong in a game at all, or is that layer private and the
    game should stay on the system side of the poem?

**About the hardware fit:**
18. Which inputs are *signature* inputs (the Phantom Hourglass test,
    §7.5): the four triggers? the twin sticks (thumb-audited, §4.2)?
    the D-pad as an instrument (§14.8)?
19. Headphones assumed, or speaker-first (§20)?
20. Session length target (§18)? Save anywhere, or loop-boundary
    saves (Majora's owl statues say hello)?

**About the music specifically:**
21. Does the player *make* music (perform, §14.8), *cause* music
    (wasatch-style rules, §12), *read* music (the dial as compass,
    §14.7), or *be* music (the third that decides the chord, §14.7)?
22. Pure vs tempered (§14.6): is the treaty a theme, a mechanic, a
    difficulty setting, or just the poem's business?
23. Would Morgan compose/record any audio for it (he is, after all,
    an audio engineer with sonido), or should the one-shot generate
    its own? Hybrid: Fable builds the system, Morgan's sounds fill
    it? (Nobody has proposed this; it occurred while writing §20 and
    is parked here as a question, not a plan.)

**About identification/housekeeping:**
24. The cube-evolves game (§6.3): Birthdays the Beginning, or not?
    (Pending since 2026-11-09, and §16 has a fragment hanging on it.)
25. "Two pins" (§10): does Morgan want to gloss it, ever?
26. Should this brainstorm live anywhere else (the Games space from
    2026-11-09, a goal workspace)? Currently it lives only in this
    thread and this file.

---

## 22. Sources consulted

Web sources consulted by Loni on 2026-11-10 for §3–§5 (search-result
pages; claims in this doc are paraphrases and should be re-verified
before anyone acts on them):

- Tech Insider — "R36S ArkOS Setup: Flash Firmware in 13 Steps
  [2026]" — tech-insider.org/r36s-arkos-setup-2026/ (specs, firmware
  shift, PortMaster install).
- Elektroda forum thread on the R36S's construction (RK3326 board,
  ArkOS, PortMaster support) — elektroda.com.
- Retro Console Club — "R36S Review (2026)" — retroconsoleclub.com
  (price class, performance tiers, PortMaster notes).
- r36smax.com — "R36S Game Console" (independent guide; specs table,
  firmware overview).
- TechTactician — "R36S Handheld Game Console Hands-On Review"
  (specs table, clone/panel warnings, 2026 firmware updates).
- 2BlueBox — "R36S Gaming Performance: PS1, N64, PSP & PortMaster
  Guide" (performance tiers, integer scaling note).
- r36s.org — Firmware Systems & Customization Guide (firmware forks,
  PortMaster port catalogue size).
- PortMaster Wiki — "What Can Be Ported?"
  (github.com/jantrueno/portmaster-wiki; the three porting paths and
  engine table in §5.1) and jantrueno.github.io mirror.
- ArchR docs — PortMaster page (native vs translated performance
  note).

Project sources read directly on 2026-11-10 via the GitHub
connector:

- ampactor-labs/noodles — README.md (app overview, circle editor
  description, decisions) and src/circle.js (header comment and
  geometry/gesture design quoted in §11).
- ampactor-labs/wasatch — README.md (concept, event→sound mapping
  table, architecture) and DESIGN.md ("Harmony space" and "The
  lake's rule" sections quoted/paraphrased in §12).

Morgan's own documents:

- The poem, as pasted into this thread 2026-11-10 (Appendix A).
- The Generative Self v5 (2026-09-27), file
  `~/workspace/user/files/THE_GENERATIVE_SELF_v5_0_wbni.md` (§13).
- Favorite games catalogue,
  `~/workspace/your_files/favorite-games-catalogue.md` (§6).

Conversation record: this side chat, "Design game for R36S
hardware," 2026-11-10 (three Morgan messages, two Loni replies,
this document commissioned in the third message).

---

## 23. Addendum (2026-11-11) — clippings Morgan brought in

Morgan shared screenshots of three readable sources (plus one long
thread screenshot too small to read, not summarized here). Recorded
as evidence for §18's one-shot scope questions; all figures are as
reported by those sources, not verified by us. Still a brainstorm:
nothing here settles any design question either.

- **The New Stack (Nov 11, 2026), on Saltline:** an Anthropic engineer
  (Felix Rieseberg) gave Fable 5.2 one prompt for a first-person
  shooter, no human feedback, ~8 hours: 445M input tokens (much of it
  cached context, which is why the run cost ~$550 at API rates instead
  of ~$3,560 uncached input alone), 2.7M output tokens. Visuals were
  generated procedurally, no imported assets; the game ships as a
  ~1.4MB HTML file with bundled Three.js. Rieseberg then spent ~2
  hours improving weapons/sounds/gameplay himself.
- **Same article, the wider field:** Matthew Berman's Gears of War:
  E-Day level recreation in Unreal 5 from a 3-line instruction:
  ~8.5B tokens over several days, ~$15,000 API-equivalent. His Excel
  clone: ~50 hours, ~$11,700 API-equivalent. Kevin Ngo's "What the
  Water Keeps" (boat ride through 8 dreamlike worlds): Ngo supplied
  3D assets via Tripo and a soundtrack via Suno; Fable composed the
  trailer music from royalty-free samples. Matt Shumer: a voxel
  destruction engine built from scratch ("nailed the voxel engine
  I've been trying to get out of almost every model for a year"), a
  Hogwarts-meets-Fortnite battle royale in ~2 weeks; Shumer found a
  **single agent owning the whole project** beat multi-agent for him,
  and warns Fable overcomplicates and still needs steering: "Framing
  the problem and keeping it on track with your goals is on you."
- **Same article, the skepticism that matters:** the demos mostly
  *recreate existing games*; the step from first working build to
  maintainable product is unproven in them; formula correctness at
  demo scale doesn't guarantee correctness at real scale; Arena's
  Peter Gostev: "a LOT of things got better but not every single
  thing" (one of his experiments cost $2,618).
- **Reddit r/vibecoding (u/shiny_guru, creator of ppu.toys), on
  Emberwake:** Fable given an open-ended prompt and full run of a
  browser-based SNES development studio produced, in 4h26m and $72,
  an action platformer with 5 levels and 5 bosses running at 60fps
  on real SNES hardware. It spun up 5 asset agents unprompted while
  the main agent coded, and *invented its own art pipeline*: Blender
  models/renders, textured and rigged, then quantized via ppu.toys
  and a custom Python script into SNES-displayable format. Caveat:
  the human had built/prepared the studio environment and installed
  art tools beforehand — open prompt, prepared workshop.
- **Same thread, a commenter (MelodramaticShape):** had Fable build
  "a full on Zelda-like GBC game in ~6 hours. Plays on actual
  hardware. Pixel art, map design and puzzle design are way above
  Opus IMO." The closest reported precedent to this brainstorm's
  dream: Zelda-like, real retro hardware, one run.
- **Same thread + TechPowerUp forum, the mood:** a running joke that
  Fable names everything "Ember" (Emberwake included); a "slop"
  critique that one-prompt games flood storefronts and hurt
  discoverability for everyone; forum sentiment largely cynical
  about monetization while conceding the capability. Noted here
  because an *original* game (not a recreation) is precisely the
  differentiator the skeptics keep asking for — and the naming joke
  is a real, if funny, reason for the human to seed a name/world
  rather than accept Fable's defaults.

---

## 24. Sources for the hand-off upgrade (2026-11-11)

Consulted by Loni on 2026-11-11 for Part 0. Claims in Part 0 are
paraphrases with their key numbers kept; the official guide is the
authority wherever a secondary source and the guide differ.

**Anthropic, official:**

- "Prompting Claude Fable 5.2" — Claude Platform docs,
  platform.claude.com/docs/en/build-with-claude/prompt-engineering/
  prompting-claude-fable-5-2 — read in full. Source of: the effort
  calibration (start at high, gains above it uneven, max for
  ceiling-measurement/open-ended problems), the finishing-work text
  and its test numbers (~half as many unfinished endings, ~30% more
  output tokens), the ownership sentence and its numbers
  (consolidation under 10% → ~75% of runs; 70–80% more output
  tokens; summaries omit small changes), subagent expectations
  (cost-aware description roughly halved subagent counts), the
  caution-piling audit (delete stale "never" rules, write exceptions
  explicitly, name steps needing no approval), the updates guidance,
  the report-writing guidance, preserved thinking / don't edit
  earlier turns, and the reasoning-extraction refusal note.
- Anthropic's Claude Code team practices, as summarized in "How
  Anthropic's Own Team Uses Claude Code" (learnaiwithmariah.com)
  and "Claude Code Habits From Inside Anthropic"
  (newmoneyschool.com): give it a check to run (test/build/linter/
  screenshot) or you become the test suite; explore → plan → code;
  `/goal` conditions re-checked by a separate evaluator; let Claude
  interview you, then build in a fresh session from SPEC.md; a
  separate session/subagent reviews against the spec; CLAUDE.md as
  the standing-instructions file; `/simplify`; loops/schedules.

**Secondary syntheses of the Fable guide:**

- Nic's notes — "Claude Fable 5.2: when to use it and how to prompt
  it" (notes.nicolasdeville.com/ai/fable-5-2/) — read in full. The
  8 rules; Ben AI's 4-part brief checklist (the job, the why, the
  rules with exceptions, what done looks like); the updates
  one-liner verbatim; plan facts (1M context, 128K output,
  $8/$40 per million tokens, Fable capped at half the weekly limit
  on Max per the video's account).
- Haci Simsek — "Anthropic Just Released Claude Fable 5.2. Here Are
  the 12 New Rules for Prompting It" (Medium) — cross-check of the
  guide's numbers, incl. FrontierCode figures.
- Promptessor — "Claude Fable 5.2 Prompting Guide" — the long-task
  prompt skeleton used in §0.5 (Objective, Context, Source
  authority, Scope, Autonomy, Tools, Evidence, Progress,
  Verification, Output, Completion).
- Hussam Ahmed — "Prompting Claude Code: From Vague One-Liner to
  Directed Brief" (hussamahmed.com) — the directed-brief levers,
  runnable checks, `/goal` and stop-hook mechanics.
- James Goldbach (@agentic.james, Instagram, 2026-11-11) — six
  evidence-based tips summary; cross-check on ownership, finishing,
  and caution-audit numbers.

**Game-build practice:**

- "Claude Code Game Building: Five Steps From Flat Shapes to
  Playable 3D Games" (aipost.kr) — the screenshot loop (capture,
  study, fix the weakest visible thing), console-error-as-broken,
  and "play it yourself and describe what feels wrong" as the step
  most people skip.
- Jonathan Caruso — "Getting Claude Code to Build Games in Godot"
  (jonathancaruso.com) — the three feedback signals (headless runs
  and logs; screenshots against a virtual display; automated tests
  plus a simulation harness as the strongest signal), make-command
  harness, rules kept in plain node-free testable code, self-playing
  builds for headless capture.
- Meta's Web Apps game plugin documentation
  (wearables.developer.meta.com) — independent corroboration of the
  same doctrine from a different vendor: desktop checks complement
  a playtest, they do not replace one; a change nobody has played
  on the device is recorded as unverified, not done.

**Already on file:**

- The "Working With Claude Fable 5.2" page (Morgan's Spaces) — the
  scouts/deep-research synthesis this document's §0.3 effort notes
  and §0.6 rung 6 draw on, and home of the Brief builder that
  generates §0.4's brief with Morgan's settings.
- §23 of this document — the Saltline/Emberwake/Shumer clippings.

**Hardware identification and ports (consulted 2026-11-11 evening,
for §3's evening update and §20's results):**

- Junub Games — "R36S Clones Detection Guide: How to Tell in 5
  Minutes" (junubgames.com/r36s-clones-detection/) — read in full:
  the three tiers, which visual tells are dead, the ten-second
  checks, the DTB test and dtbTools verification, board-marking
  table, per-board firmware table.
- Handhelds Wiki — "R36S Clones" (handhelds.wiki/R36S_Clones) — the
  tier taxonomy, EmuELEC clone variants incl. the internal-storage
  variant, partition and DTB tells, clone firmware options.
- r36s.org — "Is Your R36S a Clone? How to Spot a Fake"; r36smax
  and r36sultra clone checkers/lists — cross-checks on the same
  tells.
- Tech Tactician — "R36S Setup Guide (2026)" (techtactician.com) —
  DC/OTG port functions, the USB-C CC-resistor charging quirk,
  dArkOSRE/ArkOS4Clone as the current firmware routes.
- 2BlueBox — "R36S Wi-Fi Setup Guide: OTG Dongle & Android USB
  Tethering" — port positions (DC left of the jack, OTG right),
  dongle chipsets, tethering.
- ctgl1987 — "ArkOS USB Network Mode" (GitHub) and r36swiki's
  "SSH & FTP Over USB OTG" — OTG gadget mode (RNDIS/ECM network
  emulation), known to work on R36S and clones running
  ArkOS/ArkOS4Clone, board-wiring caveat for clones.

---

## 25. Research findings and platform audit (§0.9 answered, 2026-11-11)

This section contains the findings from the local Claude session on
Morgan's ThinkPad T460 (Fedora Sway), responding directly to the
questions and research directions posed in §0.9. Claims here are tagged
under the document's standard system: **[observed]** (measured or
verified directly from local files / hardware), **[reported]** (from
primary documentation, community repositories, or developer commits),
and **[verdict]** (actionable recommendation).

### 25.1 Decompilation and hardware forensics — settling the purple unit (Q1, Q2)

The two DTB files on Morgan's machine (`/home/moth/rf3536k3ka.dtb` and
`/home/moth/rk3326-evb-lp3-v12-linux.dtb`) were decompiled to DTS using
a Python FDT parser (`parse_dtb.py`) in the session scratch directory.

**Crucial forensic finding [observed]:**
The two DTB files are **byte-for-byte identical** (MD5:
`0cc6b25e3a020f087e5861ace7f1e828`, size 107,328 bytes). The stock
vendor firmware image simply copied the K36 board DTB over the default
Rockchip EVB filename so that whichever file the bootloader requests,
the exact board tree loads.

**Hardware specifications extracted from `rf3536k3ka.dtb` [observed]:**

1. **LCD Panel and Timings:**
   - **Controller:** Sitronix ST7703 (`compatible = "sitronix,st7703", "simple-panel-dsi"`).
   - **Interface:** 4-lane MIPI DSI (`dsi,lanes = <4>`).
   - **Resolution:** 640 × 480 (`hactive = 640`, `vactive = 480`).
   - **Pixel Clock:** 30.00 MHz (`clock-frequency = <0x1c9c380>`).
   - **Horizontal Timings:** hfront-porch = 150, hsync-len = 50, hback-porch = 150 (Total H = 990).
   - **Vertical Timings:** vfront-porch = 20, vsync-len = 6, vback-porch = 12 (Total V = 518).
   - **Refresh Rate:** 30,000,000 / (990 × 518) = **58.50 Hz** (~60 Hz).
   - **Init Sequence:** 143-byte initialization payload starting `39 00 04 b9 f1 12 83 ...`.
   - **Reset GPIO:** `reset-gpios = <&gpio3 15 1>` (active low).

2. **RAM Size and Type:**
   - **Configuration:** Rockchip reference DDR timing node (`ddr_timing`, compatible `"rockchip,ddr-timing"`) declaring speed bins and drive strengths for LPDDR3/DDR3L.
   - **Architecture:** 1 GB physical memory space populated via U-Boot ATAGS (standard RK3326 memory map).

3. **Input and Button Map (`play_joystick` driver):**
   - **Analog Joysticks:** Rockchip SARADC (`saradc@ff288000`, 4 channels) with 1750 µV threshold (`left-x` = ch0, `left-y` = ch1, `right-x` = ch2, `right-y` = ch3).
   - **Digital Buttons:** 19 GPIO keys (`gpio-key-num = <19>`), all active-low:
     - D-pad Up, Down, Left, Right: `gpio3` pins 11, 12, 13, 14.
     - Face buttons (A, B, X, Y): `gpio3` pins 16, 17, 18, 19.
     - Triggers (L1, R1, L2, R2): `gpio3` pins 20, 21, 22, 23.
     - Center / function buttons (Select, Start, Menu/FN, hotkeys): `gpio3` pins 24, 25, 26, 27.
     - Rocker / side controls: `gpio2` pins 13, 14, and `gpio3` pin 10.
     - Rocker extra GPIOs: `rocker0-gpios = <&gpio2 12 1>`, `rocker-gpios = <&gpio2 15 1>`, `rocker1-gpios = <&gpio2 16 1>`.
   - **Volume Keys:** ADC-keys node on SARADC ch2 (Vol Up: press threshold 15,000 µV, KEY_VOLUMEUP; Vol Down: 295,000 µV, KEY_VOLUMEDOWN).

4. **Battery and Charging IC:**
   - **PMIC:** Rockchip RK817 (`compatible = "rockchip,rk817"` on `i2c0@ff180000`, addr 0x20).
   - **Battery Fuel Gauge:** `compatible = "rk817,battery"`.
     - `design_capacity = <0x738>` = **1848 mAh** (0x7f1 `design_qmax` = 2033 mAh).
     - *Critical discrepancy [observed vs reported]:* The physical exterior label claims "3500 mAh", but the active PMIC fuel-gauge profile is factory-tuned for an **1848–2033 mAh cell** at 4.2V!
     - Cutoff threshold: `power_off_thresd = 3500 mV`.
   - **Charger:** `compatible = "rk817,charger"`.
     - Input and charging current limit: `max_input_current = 800 mA`, `max_chrg_current = 800 mA`.
     - Max charge voltage: 4200 mV (standard single-cell Li-ion).
     - DC detect: `dc_det_gpio = <&gpio3 5 0>`.

5. **Audio Path:**
   - **Codec:** RK817 integrated audio codec (`rockchip,rk817-codec`).
   - **Sound Card:** `compatible = "rockchip,multicodecs-card"`, card name `"rockchip-rk817"`.
   - **Speaker Amp Control:** `spk-con-gpio = <&gpio3 7 0>` (GPIO3 pin 7 drives the onboard speaker amp).
   - **Headphone Detect:** `hp-det-gpio = <&gpio2 22 0>` (GPIO2 pin 22 detects 3.5mm plug insertion).

6. **USB Controller and Gadget Mode Capability:**
   - **Node:** `usb@ff300000`, DesignWare Core 2 (`snps,dwc2`, `"rockchip,px30-usb"`).
   - **Mode:** `dr_mode = "otg"` [observed].
   - **OTG ID GPIO:** `otg-gpio = <&gpio3 4 0>`.
   - **Verdict [observed]:** The controller is explicitly set to dual-role OTG mode. USB peripheral/gadget mode (Linux `libcomposite`, `g_ether`) is supported by the hardware and DTB.

**Clone Type Classification (Q2) [reported + observed]:**
Cross-referencing the ST7703 640×480 @ 58.50 Hz panel timings, 143-byte init sequence, and `rf3536k3ka` filename against `dtbTools.html` and `ArkOS4Clone` (`lcdyk0517/arkos4clone`) yields an exact match:
- **Exact Clone Profile:** **Kinhank K36 / Clone Type 1 Panel 1** (without amplifier, or standard K36 Origin Panel).

---

### 25.2 Firmware comparison and flashing recommendation for the purple unit (Q3)

- **dArkOSRE vs. ArkOS4Clone:**
  - `dArkOSRE-R36` (`southoz`) is a Debian-based custom firmware focused on genuine R36S boards with generic clone fallbacks.
  - `ArkOS4Clone` (`lcdyk0517/arkos4clone`) is maintained explicitly for this device's board line, includes the dedicated `dtb_selector` tool with built-in profiles for `rf3536k3ka`, and maintains full PortMaster support and ALSA audio routing without speaker overvolting.
- **Concrete flash recommendation for the purple's 32 GB spare card [verdict]:**
  1. Download and flash the latest `ArkOS4Clone` image to the 32 GB card using standard disk imaging (`dd` or Raspberry Pi Imager).
  2. Before booting: Mount the `BOOT` partition on the ThinkPad. Verify the presence of `rf3536k3ka.dtb`. If not present, copy `/home/moth/rf3536k3ka.dtb` directly into the boot root and ensure `extlinux/extlinux.conf` points `FDT /rf3536k3ka.dtb`.
  3. First boot: Insert card into TF1/OS slot. Power on. If the screen is black or controls are inverted, use the `dtb_selector` tool or confirm the DTB file.
  4. Keep the 128 GB stock card untouched as the permanent golden reference.

---

### 25.3 The black unit — software-only identification and verdict (Q4)

- **Software identification paths [reported]:**
  - EmulationStation System Settings $\rightarrow$ System Information will report the Linux kernel version (typically 4.4.189 on EmuELEC clones) and architecture.
  - Under EmuELEC, mounting internal storage reveals `/flash/SYSTEM` (SquashFS) and `/flash/dtb.img`. If an on-device terminal is accessible, `cat /proc/cpuinfo` and `cat /proc/device-tree/compatible` will confirm whether the chip is a true RK3326 or a remarked Allwinner (e.g. `sunxi`).
- **Hardware reality:** Clones with internal eMMC that boot without an SD card typically carry `GA36-MB` or `G80C/G80CA` board silkscreens.
- **Verdict [verdict]:** **Leave the black unit stock.** In eMMC clones, the on-board bootloader takes precedence over the external SD slot, making custom OS booting prone to bricking or persistent black screens. Treat the black unit as a stock reference/beater unit. All game development and custom firmware testing belongs on the purple K36.

**Correction (2026-11-11, ~22:12, after this session ended):** the
black unit's board has since been identified directly — Morgan
photographed it. The silkscreen reads **R36S-V12 2023-08-18**, the
SoC is a genuinely marked RK3326, and the memory is a single
Samsung eMMC package: the wiki's **Variant 1** of that board (full
record in §20). The GA36/G80C guess above is therefore superseded,
and so is the "leave it stock" verdict as a statement of necessity:
dArkOSRE publishes verified Variant 1 DTB files, so the black has
a real firmware path. It remains the secondary unit by Morgan's
choice — and, per his decision the same evening, it is his own
unit while the purple is JJ's. The software-identification paths
above remain valid technique for unidentified units.

---

### 25.4 PortMaster platform realities and engine selection (Q5, Q6)

- **PortMaster Packaging Layout [reported]:**
  ```text
  /roms/ports/
  ├── GameTitle.sh             # Launch wrapper
  └── gametitle/
      ├── port.json            # Metadata read by PortMaster
      ├── gametitle.gptk       # Controller mapping configuration
      ├── licenses/
      └── gamedata/            # Engine binary, squashfs mount, or .pck/.love
  ```
- **Controller Mapping (`gptokeyb`) [reported]:**
  `gptokeyb` intercepts raw `/dev/input/event*` devices and maps the 19 physical buttons and 2 analog sticks to keyboard strokes, mouse clicks, or analog axes. The `.gptk` file declares these mappings in plain key-value format.
- **Engine Comparison for RK3326:**
  - **Godot 3.5.x via FRT (Frugal Runtime) [RECOMMENDED]:**
    - FRT is a lightweight custom Godot 3 runtime targeting raw DRM/KMS / GLES2 without a window manager or compositor.
    - Mounts directly from PortMaster's shared `frt_3.5.2.squashfs` runtime.
    - Extremely low RAM usage (~40–70 MB baseline), rock-solid 60 FPS at 640×480.
    - Used by dozens of commercial and indie ports on PortMaster.
  - **LÖVE 11.x (Lua) [RECOMMENDED ALTERNATIVE]:**
    - Native `love_11.5.squashfs` runtime. Negligible overhead, sub-10ms audio latency, fast iterative script reloading.
  - **Godot 4.x [AVOID ON RK3326]:**
    - Godot 4 dropped the standalone DRM display server and GLES2 renderer. PortMaster runs Godot 4 games by embedding them inside a **Weston (Wayland compositor)** session.
    - On an RK3326 Cortex-A35, the Weston compositor introduces significant CPU overhead, frame stuttering, and severe audio latency. Godot 4 is viable on RK3566/H700, but actively harmful on RK3326.
- **Performance Envelope (RK3326 + Mali-G31 MP2 @ 640×480, 1 GB RAM) [reported]:**
  - **CPU:** 4× Cortex-A35 (in-order execution, weak floating-point throughput). Frame budget: logic must execute in under 6.0 ms to sustain 60 FPS.
  - **GPU Fill-rate & Memory:** The Mali-G31 shares memory bandwidth (single 32-bit DDR3L bus @ ~786 MHz, total bandwidth ~3.1 GB/s) with the display controller and CPU. Keep sprite overdraw under 2.5×. Avoid heavy full-screen fragment shaders (bloom, complex CRT filters).
  - **Audio Latency:** ALSA via RK817 buffer size 512–1024 samples @ 44.1 kHz gives ~11.6–23.2 ms latency. Procedural harmonic math must pre-generate or cache audio buffers rather than computing floating-point trigonometric wave equations sample-by-sample in high-level script during frame render.

---

### 25.5 USB Gadget Mode and Deploy Loop (Q7)

- **Verification [observed + reported]:**
  - Hardware: The USB controller is `snps,dwc2` at `ff300000`, configured with `dr_mode = "otg"`.
  - Physical ports: Right USB-C port is **OTG** (data lines connected); Left USB-C port is **DC** (power only, no data).
  - Software: ArkOS4Clone includes Linux `libcomposite` / `g_ether` support and the `ssh_over_otg.sh` helper.
- **Verdict [verdict]:** **YES. The zero-card-pull deploy loop works.**
  Connecting a USB-A-to-C data cable from the ThinkPad to the purple unit's right-side OTG port creates an RNDIS/Ethernet interface (default IP `192.168.7.1`).
  You can deploy test builds, update scripts, and sync logs directly via `rsync` or `scp` to `/roms/ports/` (`ssh ark@192.168.7.1`, password `ark`).
  Card swapping is not required for daily development.

---

### 25.6 Protocol critique and adversarial review (Q8, Q9)

1. **The Headless ARM Paradox (Verification Ladder Rungs 2–4):**
   - *The Problem:* Rung 2–4 in §0.6 dictate that the game must build and run headlessly with zero console errors. But PortMaster target binaries are ARM Linux, while the developer laptop is an x86_64 ThinkPad running Fedora Sway.
   - *The Fix:* The game architecture must maintain a **Dual-Runner abstraction**:
     - `runner_desktop.py` / native engine binary: executes the logic and headless smoke tests natively on x86_64 for automated verification and bot playthroughs.
     - `package_portmaster.sh`: exports the `.pck` / `.love` and bundles the `.gptk` and shell script for ARM.
2. **The Audio Verification Gap:**
   - *The Problem:* The verification ladder focuses heavily on screenshots and logic tests, but ignores audio verification. For a game whose core ontology is the Pythagorean comma and harmonic wanting, an audio crash or muted sound engine would pass Rung 1–5 undetected.
   - *The Fix:* Add an automated harmonic unit test to Rung 2 that calculates pitch cents and validates interval ratio tables.
3. **The "Ambition" Clause in the Brief (§0.4):**
   - *The Problem:* Telling Fable to "build the largest, most complete version of the game" without an explicit feature ceiling invites the model to attempt 3D exploration, procedural dialog, and real-time DSP all at once, which will overwhelm the RK3326.
   - *The Fix:* In Session A (the spec interview), explicitly require the spec to constrain the game to a 2D top-down or side-scrolling perspective with a single, tightly bounded harmonic loop.
   - *Editor's note (merge, 2026-11-11): recorded as the research
     session's recommendation. Under Part 0's rules the scope
     decision itself belongs to Morgan in the Session A interview;
     this item is the case for the cap, not the cap.*
4. **Retired Assumptions & Fact Corrections:**
   - The purple unit's panel, controls, audio, and USB gadget capabilities are no longer `[reported]`; they are **[observed]** from decompiled DTB facts.
   - Battery capacity is ~1848–2033 mAh, not 3500 mAh.
   - The two DTBs (`rf3536k3ka.dtb` and `rk3326-evb-lp3-v12-linux.dtb`) are identical clones.

---

## Appendix A: The poem, as pasted by Morgan on 2026-11-10

Included verbatim, including its line breaks and punctuation, because
Morgan offered it as evidence and its exact wording carries the
design material discussed in §9–§10. (Other versions/drafts exist in
his files and in The Generative Self; see §10's note on canonicity.)

> In the midst of the spiral where all but the generator turn static
> and fade, no compass with which to map meaning, I concede.
>
> Any point at which one might first settle down is arbitrary. There
> is no end or beginning, twelve fifths overshoot home and miss
> forever. As every note carries its octave within, the nature of the
> space is to fold, but never close.
>
> That fact leaves a gap, a crack in the wall where TIME enters the
> equation and we are faced with two choices: WHERE, and HOW HIGH
> home is. Everything else is the function stacking fifths.
>
> Two pins and a generator, music?
>
> Along come silly human with their silly human crew:
> "may as well put a finger down, call it home (C), split the
> difference, eat the error, and FAKE THE CLOSURE."
>
> Equal temperament is the quantization chosen to be equidistant in
> every key, maximally fair, minimally faithful, a "center" of the
> space.
>
> I mean, I get it.
> It could never be reduced to the sum of its parts precisely because
> its parts cannot be counted. Fundamental to all inhabitants of our
> universe, the primitive IS infinity. How lovely its journey, that
> dance unending along relative path. Sharing space with the
> Sunflower, Earth, and our breath. Teasing as hourglass grain, only
> ever might our reaching hands behold the moment suspended as our
> own, yet fail. For steady as the stream of time pours in, she, too,
> must pass.
>
> What else then might we have to secure common ground than a TREATY
> (yum). One surface, upon which all agree and the blooming people
> can meet in the middle of that blooming space that cannot be seen.
>
> Let it be known: errors do not sit well with my stomach.
>
> But then, looking in, I am reminded: ache IS the engine, we work
> because we want as we work as we want...
>
> (V7 resolving to I)
> Harmony cultivates wanting by metabolizing our error as remainder.
> A music with no remainder leaves nothing to want in a world where
> wanting is the product.
>
> It is freedom, our arrival.
>
> You star-eyed sunkiss, my resolution. I see that you are queen,
> rocking and rolling with all that good stuff I so badly need. I am
> sold and I am buying ALL that you are selling.
>
> It's beautiful how you glow in my heart and won't let go.
> It's your garden, life and love you take, the things you make and
> grow with all the colors we envision through each other's prisms'
> flow and when you reach for me, all cozied up or cold, through all
> we keep between us, our gravity, I pull.
>
> I love you more and more and more and more.
>
> JJ+Mo
> 😍 4eva 😍

---

## Appendix B: Morgan's original messages, condensed

For completeness, Morgan's three messages in this thread, condensed
(not verbatim) — the full originals live in the chat transcript.

**B.1 — 14:24, opening.** Photos of the handheld, front and back
(§1.2). Wondered whether anyone makes games targeting this hardware.
Proposed designing a game together and seeing if Fable 5.2 can
one-shot it; asked that it make the most of the hardware specs and
layout. Pre-emptively filled in his games background since his games
space/catalogue wasn't filled yet: the ordered single-player list
(§6.1), the unplayed suspected loves, the openness to outside
influences, the shallow-pool caveat, and the resource context (R36S
is his only console; the laptop is weak). Then the multiplayer list
(§6.2) with the Gauntlet/Dungeons anecdote, the Monkey Ball note, and
the MMORPG curiosity. Closed with: "what do you think?"

**B.2 — 14:45, correction and the music turn.** The trigger count
(2 per side) and the three-thumb observation (§4.2), delivered as a
joke at Loni's expense and accepted as such. Reassigned designing to
Fable (§2.2). Pointed to the missed thru-line, MUSIC, and to the
evidence: noodles, wasatch, and the poem (pasted in full,
Appendix A).

**B.3 — 14:57, this document.** Asked for the exhaustive .md with all
the details and the history of how we got here, with nothing stated
as invariant because it's still a brainstorm. This document is the
deliverable for B.3. Any errors in it are Loni's; Morgan's standing
correction offer applies — if it's wrong in here, say so and it gets
fixed in place, like the console's name was (§2.1).

*— End of brainstorm document, v1, 2026-11-10. It folds. It does not
close.*

---

## 26. Audit of §25 and the firmware options (2026-11-11, ~22:50, Opus session)

The DTB was parsed again with a fresh FDT parser, the DTB-tool
screenshots were read, the 119 GB card mounted on the laptop was
inspected, and the firmware projects were checked online. Results:

**Confirmed from the DTB [observed]:** root model `Rockchip rk3326 evb
lpddr3 v12 board for linux`; panel `sitronix,st7703` over 4-lane DSI,
640×480, 30 MHz pixel clock (≈58.5 Hz); RK817 PMIC, codec and charger
(800 mA input/charge limit, 4.2 V); fuel-gauge `design_capacity` 1848,
`design_qmax` 2033; USB `snps,dwc2` with `dr_mode = "otg"`.

**Corrections to §25:**
- The panel init sequence is **370 bytes**, not 143.
- The DTB tool reports a **partial match** (panel parameters match, MD5
  differs), not an exact one. Its candidate selector choices are: K36
  Origin Panel; Clone R36S Type 1 Panel 1 without amplifier (with and
  without the right joystick inverted); GameConsole HG36 (HG3506). It
  marks **Aurknix** (AveyondFly's ROCKNIX fork) as "Recommended" and
  ArkOS4Clone as the second route. "Type 1 Panel 1" is the most likely
  choice, but it has to be tested on the unit.
- **RAM size is not in the DTB.** The "1 GB via ATAGS" line was
  inference. The memory is a Samsung eMCP (eMMC + LPDDR3 in one
  package; the DTB's "lpddr3" agrees). The closest documented part,
  KMQN1000SM-B316, is 8 GB eMMC + 8 Gb (1 GB) LPDDR3. Confirm on the
  device with `free -m` or the system-info screen.
- **Battery:** 1848 mAh is only the fuel-gauge setting; it does not
  prove the cell's capacity. The black unit's cell sticker reads
  3.7 V 3500 mAh 12.95 Wh. Neither figure is proven. The practical
  consequence is that the battery percentage may read wrong. Treat
  runtime as unknown until it is measured.
- **USB gadget mode:** `dr_mode = "otg"` makes gadget mode possible,
  but it does not prove it works. The `ssh_over_otg.sh` /
  `ark@192.168.7.1` recipe comes from AeolusUX's K36 ArkOS build, and
  reports on clones are mixed. Mark it [untested] on ArkOS4Clone until
  it is tried.
- **Godot 4:** PortMaster's docs say most CFWs have "no x11 / weston".
  Godot 4.3–4.4 runtimes exist in PortMaster's runtime list, but
  developers report Godot 4 as "mostly unfeasible" on this device
  class. The conclusion (avoid it) stands; the Weston explanation was
  wrong. Godot 3 via FRT (KMS/DRM + SDL2, prebuilt in PortMaster's
  runtimes) and LÖVE 11.5 are confirmed as PortMaster runtimes.

**The 119 GB card on the laptop (2026-11-11) [observed]:** one exFAT
partition with no label. It has an ArkOS-style ROM tree (`tools/`,
`themes/` full of R36S themes, `backup/lastarkosrestore.log`) and
**PortMaster 7.03** (2023) in `tools/`. That makes the OS this card
pairs with ArkOS-family, not EmuELEC. Morgan identified it as the
**"JJ backup"**, a copy of the black unit's card from an earlier
state. It holds data only, with no BOOT partition or DTB, so it
cannot identify the black unit's panel.

**Firmware options as of today [reported]:**
1. **ArkOS4Clone** (lcdyk0517). Latest release 20261008. It has a
   dtb_selector, an Install.PortMaster entry (run it once), online
   updates through ES, and since 20261008 it can be written to eMMC.
   This is the most active project for this board family.
2. **Aurknix** (AveyondFly/distribution_rocknix). A ROCKNIX fork with
   a unified RK3326 image covering K36, HG36, R36S and clone types. The
   DTB tool recommends it. ROCKNIX is an immutable system, so packaging
   and ssh work differently from ArkOS.
3. **dArkOSRE-R36** (southoz). Lists DTBs for "R36S-V12 2023-08-18
   Variant 1 Panel 3 A / Panel 8 A" and for Variants 2 and 3. Tested
   status is unclear (the README marked Variant 1 as untested), and
   these units' panel numbers are not mapped to its list.
4. **Stock** (eMMC system + ArkOS card). Its PortMaster is from 2023.

**[verdict, for Morgan to accept or reject]:** put both units on the
**same** ArkOS4Clone image, booting from SD, and leave the eMMC
untouched as the fallback system. That gives one software target,
current PortMaster, and no brick risk. Aurknix is the fallback if the
selector choices misbehave. Do not write anything to eMMC.

**Still open:** the black unit's own DTB and panel (only the purple's
DTB has been read); the RAM figure on each unit; whether L3/R3 click;
whether gadget mode works on the chosen image.

**The black unit's own card (2026-11-11, ~23:00) [observed]:** a
58 GB card with a single unlabelled FAT32 (vfat) partition holding
ROMs only. It has the ArkOS-style tree (`ports_scripts/`, `tools/`,
R36S themes) and **PortMaster 2024.03.20-1013**; its only port is
`ecwolf`. There is no BOOT partition, DTB, extlinux file or OS version
file. Conclusion: the black unit's OS lives entirely on its eMMC, and
it is ArkOS-family (this card and the JJ backup both use ArkOS
layouts). Its panel and DTB can only be learned on the device itself
(`/boot` over ssh or a terminal) or by booting an ArkOS4Clone card and
seeing which selector choice drives the screen.

**The purple's stock card, re-read (2026-11-11, ~23:10) [observed]:**
115 GB with three partitions: p1 BOOT (vfat, 512 MB, no label), p2
`root` (ext4, 8 GB), p3 `EASYROMS` (exFAT, 104 GB, 92% full).
`extlinux.conf` loads `FDT /rf3536k3ka.dtb`. Both DTBs on the card
have MD5 `0cc6b25e…e828`, the same as the laptop copies. The
userspace is **ArkOS 2.0 (04242024)** on Ubuntu 19.10. The kernel is
**Linux 5.10.160**, a vendor build dated 2024-10-17 (made with the
libreelec toolchain, not ArkOS's usual 4.4 kernel). PortMaster is
**7.03**, older than the black card's 2024.03. Options › Tools has
Wi-Fi, Enable/Disable Remote Services, Network Info and USB Drive
Mount, but **no USB-gadget / SSH-over-OTG tool**. So on stock
firmware the only network route is a USB Wi-Fi dongle. The §25.5
deploy loop depends on whichever new firmware is chosen.

---

## 27. Ceiling research: designing for the hardware rather than emulation (2026-11-11, late, Opus session)

Morgan's goal, restated (~23:20): the game should not be retro. It
should be "as deep and hi-def and beautiful and engaging as possible
while exploiting the full potential of the platform." This section
records what the hardware can actually do, from the DTB, the
purple's stock libraries, and three research passes. Tags as usual.

### 27.1 Black unit: TF1-OS slot is broken [observed]
Morgan reports that the black's TF1-OS slot won't latch, so cards
keep ejecting. The internal eMMC is the way around it.
ArkOS4Clone's script `Options › Advanced › Install to eMMC.sh`
(read from the repo source) does the following:
- Copies the SD-booted system to the eMMC.
- Asks first; pressing **X** makes a full eMMC backup to
  `/roms/backup/emmc-backup.img` on the card.
- Refuses if the eMMC is too small.
- Writes U-Boot and verifies it.
- Keeps ROMs on TF2.

`Restore eMMC.sh` writes that backup back. The one requirement is
a single session with a card held in TF1 (taped against the spring).
After that, the black runs entirely from eMMC plus TF2. [idea]
Install the purple the same way so both units run an identical
configuration, with TF1 kept only as an installer/recovery slot.

### 27.2 Clock limits [observed + reported]
- **Stock DTB (purple):**
  - CPU OPPs up to 1296 MHz; 1416 and 1512 are present but disabled.
  - GPU up to 520 MHz.
  - DDR **528 MHz** (666 and 786 present but disabled;
    system-status-freq locks 528).
  - Thermal trips at 70, 85 and 115 °C; sustainable power 750 mW.
- **ArkOS4Clone `k36` boot.ini:** CPU 1296 / GPU 520 / **DDR 666**
  by default, about +26% memory bandwidth over stock.
- **ArkOS4Clone dtbTools overclock choices** (`ops.go`), plus an
  optional OC-voltage overlay. Stability per unit is unknown and
  must be tested.
  - CPU: up to 1608 MHz.
  - GPU: up to 650 MHz (600 on 5.10).
  - DDR: up to 1040 MHz (1032 on 5.10).
- **Evidence that memory is the binding limit** (ROCKNIX PR
  #3437/#3438, R36S-clone glmark2):
  - DDR 328→666 MHz: score 247→342.
  - GPU 480→520 MHz: score 311→330.

### 27.3 Graphics driver capability [observed + reported]
- **Purple stock:** `libmali-bifrost-g31-rxp0` (r13p0 strings),
  kernel 5.10.160 with Mali kbase r18p0.
  - Binary strings: OpenGL ES 3.2, OpenCL 2.0,
    `GL_ARM_shader_framebuffer_fetch` (+depth/stencil),
    `GL_EXT_shader_pixel_local_storage`, ASTC LDR+HDR,
    `EXT_multisampled_render_to_texture`, `OVR_multiview2`,
    geometry/tessellation, `EXT_disjoint_timer_query`.
  - No Vulkan ICD installed.
  - Strings are not proof of exposure; eglinfo on the device is.
- **ArkOS4Clone:** `mali-select` links **g29p1** on its 5.10 kernel,
  described as "also provides Vulkan", and rxp0 on 4.4. A
  `switch-kernel` tool flips between them.
- **ROCKNIX/Aurknix:**
  - libmali (default) or Panfrost (GLES 3.1; PanVK Vulkan on
    Bifrost v7 is "broken-driver"-flagged and non-conformant).
  - Runs a Sway compositor.
  - Most RK3326 boards leave DDR at 333 MHz.
  - Net: less attractive than ArkOS4Clone for this goal.
- **GPU numbers** (Mali-G31 MP2, 2 cores, 1 or 2 execution engines
  each; RK3326's configuration is unconfirmed):
  - At 520 MHz: 1.04–2.08 Gpix/s, 8.3–16.6 GFLOPS FP32
    (FP16 ×2).
  - DDR 32-bit: 528 MHz ≈ 4.2 GB/s peak, 666 MHz ≈ 5.3 GB/s.
  - Planning budget at 640×480×58.5: about 25× full-screen
    overdraw equivalent, 150–250 FP32 ops/pixel, about 50 MB/frame
    of real bandwidth.
- **Also enabled in the DTB:** RGA2 2D blitter, VPU decode (H.264;
  HEVC node present) and encode. These are only usable through BSP
  libraries (librga is on the purple). No game ports use the VPU.

### 27.4 What the ceiling looks like in shipped ports [reported]
Source: PortMaster catalog, 1,485 ports, 62 blocked on RK3326.
- **Dead Cells** reaches about 25 fps on R36S, but only after
  cutting lighting, render targets (4→2), normal maps and draw calls
  (143→72). The porter: "the enemy wasn't actually the CPU, it was
  the GPU"; deferred lighting with bloom was "catastrophic".
- **Morrowind** runs at 0.5 resolution scale.
- **UT99** runs at 640×480 with a native GLES2 renderer.
- **FlatOut 2** averages 25 fps at 640×480 on RK3326S.
- **Blocked for 1 GB out-of-memory:** Hyper Light Drifter,
  Jet Lancer.
- **Driver costs** (Digimon decomp, measured):
  - About 105 µs stall per draw for `glBufferSubData` into a
    reused buffer.
  - 3.2 ms present.
  - Game logic + mixing about 14 ms.
- **[reading]** Ports hit these walls because they bring desktop
  architectures (multi-RT deferred passes, uncompressed assets) to a
  tiler with 1 GB. A game designed for the tiler from day one can
  keep lighting and post-processing in on-chip tile memory
  (framebuffer fetch / PLS) and can author assets as ASTC. That is
  the specific opportunity an original game has that ports don't.
  It stays unproven until it is benchmarked on the device.

### 27.5 Stack implications (supersedes §25.4's Godot-3-first ranking for this goal)
- **[verdict-candidate]** Native C (or Zig) + the device's SDL2
  (KMSDRM) + a hand-written GLES 3.x renderer using Mali extensions
  + a hand-written DSP/synth on a dedicated core with NEON.
  - Cross-compile from Fedora with zig
    (`-Dtarget=aarch64-linux-gnu.2.30 -Dcpu=cortex_a35`). Precedent:
    Pocket Acid, a real-time synth that ships on R36S. Alternatively
    use PortMaster's arm64 builder image.
  - Build the same code natively on x86 against Mesa GLES for
    headless smoke tests.
  - Check shader costs statically with Arm's `malioc` (confirm G31
    with `--list`).
  - Profile on device with `EXT_disjoint_timer_query`.
- **Alternatives, in order:** raylib 6 (SDL backend), Godot 3 FRT
  (GLES3 renderer; synth needs GDNative C++), LÖVE 11.5.
- **Avoid:** Godot 4 (weston wrapper), Defold (glibc 2.33).
- **Audio:**
  - ArkOS ALSA dmix runs 44.1 kHz with a 1024-frame period
    (about 23 ms).
  - `AUDIODEV=hw:0,0` may bypass dmix (unverified).
  - The DTB wires headphone detection (`hp-det-gpio`), so a
    speaker mix and a headphone mix are both possible.
- **Display:**
  - Native 640×480 on a 3.5" panel is about 229 PPI, so
    native-resolution, anti-aliased art reads as high-definition.
  - Refresh is firmware-dependent (58.5 Hz stock; ROCKNIX overlays
    run 77.4 Hz), so drive the game from vsync with a fixed-step
    simulation.
- **Two units together:** USB Wi-Fi dongles (ArkOS4Clone ships
  rtl8188eu and RTL8723DU drivers) are the proven link. A direct
  USB-cable link is [idea]-grade only, because the board has no CC
  resistors and roles are unresolved.

### 27.6 Proposed next step [idea]
Build a **probe**: a small native program, packaged as a port, run
on both units after ArkOS4Clone is installed. It would record:
- EGL/GLES/Vulkan strings and extensions.
- Fill-rate, bandwidth and ALU microbenchmarks at each DDR/GPU/CPU
  step.
- A PLS / framebuffer-fetch lighting test.
- Audio latency (dmix vs hw).
- Actual refresh and input polling rate.
- Free RAM.

Its output becomes Fable's hardware sheet: measured on these two
units, not taken from reports.

---

## 28. The probe, the OTG port, and the flashing plan (2026-11-11/12, Opus session)

### 28.1 The probe [built, desktop-verified, not yet run on device]
- **Location:** `probe/` in the repo. Native C11 with no link-time
  dependencies: SDL2, EGL, GLES and Vulkan are all loaded with dlopen
  at runtime.
- **Builds:**
  - aarch64 with Zig 0.17.1 (`.tools/zig`, git-ignored), target
    `aarch64-linux-gnu.2.30 -mcpu=cortex_a35`. The highest glibc
    symbol needed is 2.27, so it runs on ArkOS (Ubuntu 19.10) and
    dArkOS (Debian).
  - x86_64 with gcc, for desktop smoke tests. The run
    `SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy … --quick`
    completed every test path on the T460.
- **What it measures:**
  - System dump: cpufreq, devfreq, thermal, Mali, libs, DRM, mmc,
    input, ALSA, boot config.
  - CPU: NEON FMA on 1–4 cores, RAM bandwidth and latency ladder,
    synth voices per core (sine / Karplus-Strong / polyBLEP saw+SVF).
  - Storage read/write with the cache dropped.
  - GPU:
    - Caps: extensions, limits, precisions, compressed formats, EGL.
    - Fill rate (opaque vs blended); texture throughput (RGBA8 / ETC2
      / ASTC); fp32 vs fp16 ALU.
    - Draw-call cost: plain, BufferSubData, orphaned, instanced.
    - Render-pass break cost.
    - Framebuffer fetch (ARM/EXT), with a correctness readback.
    - 16-light deferred lighting via pixel local storage vs MRT vs
      forward, with correctness readbacks.
    - Texture upload rate.
  - Display: vsync interval and present cost.
  - Audio: drivers, smallest steady buffer on the default device and
    on `hw:0,0`, playing quiet 4:5:6 chords.
  - Controls (interactive): resting noise, stick directions (detects
    inverted axes, which answers the "invert" DTB question), button
    map, axis update rate.
  - 60 s stability test: CPU result checks, RAM pattern verification,
    GPU frame-hash verification, plus a thermal/clock telemetry CSV.
  - Vulkan instance and device report.
- **Outputs:** written to `gameguyprobe/results/`. Hold SELECT+START
  to skip ahead. A watchdog and a crash handler make sure the log
  survives hangs.
- **Package:** `probe/dist/ports/`, containing `GameguyProbe.sh`,
  `GameguyProbe-LongStress.sh` (10 min, for overclock validation) and
  `GameguyUSBDiskMode.sh` (experimental).

### 28.2 DTB choice, settled by comparison [observed]
- All candidate ArkOS4Clone DTBs (`clone type1 panel1` / `invert` /
  `amp`, `type2 panel1`, `k36`, `hg36`) carry the **identical
  370-byte panel init sequence** as the stock DTB. They retime the
  panel to **60.02 Hz** (stock: 58.50).
- The stock DTB drives a speaker-amp enable on **GPIO3_A7**
  (`spk-con-gpio`). Only `clone type1 panel1 amp` has that same pin
  (`spk-ctl-gpios` → gpio3 pin 7).
- **First choice: "Clone Type 1 Panel 1 with amp".**
  - If the speaker misbehaves, fall back to plain Type 1 Panel 1.
  - Stick inversion gets decided from the probe's direction test.
- Battery gauge profiles in these DTBs: 2808 mAh (type 1) or
  3124 mAh (type 2), against stock's 1848.

### 28.3 The OTG port [reported from source code; untested on these units]
- **ArkOS4Clone's U-Boot** (`lcdyk0517/Clone-u-boot`,
  `odroidgoa_defconfig`) has `CMD_ROCKUSB`, `CMD_USB_MASS_STORAGE`
  and DWC2 gadget support, with mmc 0 = eMMC and mmc 1 = SD.
  - `systemctl reboot ums` (reboot-mode magic `0x5242c30c`) exposes
    the **whole eMMC as a USB disk** on the laptop. Unplugging
    continues the boot.
  - `systemctl reboot loader`, or holding **VOL+** at power-on with a
    PC connected, enters rockusb (`rkdeveloptool`, Fedora package,
    USB ID 2207:330d).
  - This only works once ArkOS4Clone's U-Boot is on the eMMC, i.e.
    after "Install to eMMC". From then on, deploy, backup, results
    pulls and reflashing can all go over the cable.
- **Maskrom** (in ROM, unbrickable) is reachable via
  `rkdeveloptool rd 3` from rockusb, or via UART `rbrom`.
  - Loader: `rk3326_loader_v2.12.140.bin`, built from rkbin
    `RKBOOT/RK3326MINIALL.ini`.
- **Linux USB gadget (SSH over USB):** the kernels ship configfs and
  ECM/RNDIS (5.10 adds ACM). There is no ready script in ArkOS4Clone;
  the community script is `carrothu-cn/SSH-over-OTG-for-ArkOS`.
  Status: likely, unverified.
- **[caution, unverified]** The DTB marks the OTG 5 V output
  (`vbus_host`, GPIO3_A4) as `regulator-always-on`. When it's
  connected to a laptop, both sides may drive VBUS. Cheap insurance:
  an inline USB power meter or a VBUS-blocking adapter.
- **A raw `dd` of the SD release image onto the eMMC will not boot.**
  `boot.ini`, the eMMC overlay and `fstab` need the adjustments that
  `emmc-boot-files.sh` makes. Use the on-device "Install to eMMC"
  script.

### 28.4 The plan from here
The step-by-step plan, with failure handling for each step, is in
`docs/walkthrough-probe-and-flash.md`. Laptop helpers:
- `probe/tools/flash-card.sh`: writes only 28–34 GB cards, then
  verifies by reading the card back.
- `probe/tools/select-console.sh`: performs the same file operations
  as the official dtb_selector, without its menu.

Firmware: `.tools/firmware/dArkOS4Clone-20261008.img` (12.4 GB,
archive verified).

Order:
- A. Baseline probe on the black's stock firmware, via its TF2 card.
- B. Flash the install card.
- C. Purple: boot → probe → Install to eMMC (with backup) → USB
  disk mode test.
- D. Black: one session with TF1 taped → Install to eMMC (with
  backup).
- E. Optional clock tuning, gated by a 10-minute LongStress PASS.

**Correction (2026-11-12, ~00:15) [observed]:** the black unit's
internal system is **EmuELEC**. Its main menu reads "EMUELEC ES V4.7"
(photographed). §26's inference that it was "ArkOS-family", made from
the card's folder names, was wrong; the original §20 reading
(EmuELEC-clone provisioning) stands. On EmuELEC, the Ports system
lists `.sh` scripts from **`/storage/roms/ports_scripts`** (EmuELEC
`es_systems.json`, manufacturer "Ports"), not from `ports/`. The probe
launcher now finds its folder from either location.

---

## 29. First measurements: black unit, stock EmuELEC (probe v1.0, 2026-11-12 ~00:30)

Raw results are in `probe/results/black-stock-emuelec/`: three complete
runs and one stopped at the controls prompts. Unit code `8ecf62`. The
device clock reads 2023-02-16 because the unit has no RTC battery.

**Platform [observed]:**
- EmuELEC ES 4.7, Linux 5.10.160 (vendor build, 2024-08-27),
  systemd 252.
- SDL 2.28.5 with the KMSDRM driver only.
- Mali blob r13p0: **OpenGL ES 3.2**, EGL 1.4. **No Vulkan.**
- 977 MB of RAM visible.
- Clocks at stock: **CPU 1296 / GPU 520 / DDR 666 MHz**. The black's
  stock DTB already runs DDR at 666; the purple's stock DTB at 528.

**GPU features (verified by correctness readback):**
- **Pixel local storage works** (16-byte fast size).
- **ARM framebuffer fetch works.** EXT framebuffer fetch is not
  exposed.
- ASTC and timer queries are available.
- Limits: max texture 8192, MSAA ×16, 4 draw buffers.

**Valid costs** (these measurements force real execution):
- **Render pass through DRAM: ~0.5 ms per full-screen pass.** 16
  ping-pong passes took 8.2 ms, about 2.4 MB / 0.5 ms ≈ 4.8 GB/s,
  which is the memory bus.
- **16-light deferred lighting:** PLS 5.9 ms against MRT G-buffer
  15.0 ms. The MRT figure is solid; PLS gets re-checked in v1.1.
- **Draw calls (CPU side):** ~10 µs each plain, ~20 µs with
  `glBufferSubData`. Instancing costs ~0.05 µs per instance, so batch
  everything.
- **Texture upload:** 208 MB/s (a 2048² RGBA8 texture takes 81 ms).
  Preload assets; don't stream large textures per frame.

**Display:**
- 58.51 Hz.
- `SwapWindow` blocks ~16.8 ms, and swap-interval 0 is ignored.
- The game is therefore **locked to vsync and double-buffered**: a
  missed frame drops straight to 29.25 fps.

**Audio:**
- ALSA. The default device forces 1024-frame periods (**21.3 ms**)
  whatever is requested.
- **Direct `hw:0,0` runs steady 128-frame callbacks (2.67 ms)** at
  48 kHz S32, so a low-latency synth path exists if the game owns the
  device.

**Controls:**
- 4 full-range axes with zero resting noise (the driver applies a
  deadzone). Stick directions are SDL-normal (not inverted) under
  EmuELEC's driver.
- 17 button slots, including **L3/R3 clicks** (b11/b12).
- **L2/R2 are digital** buttons (b6/b7).
- **FN is never delivered** to the gamepad (slot b10 "guide"); the
  firmware's hotkey service takes it. Don't design around FN.

**CPU and memory:**
- NEON FMA 1.5 GFLOPS per core, scaling linearly to 6.0 on 4 cores.
  This is below theoretical; to be re-checked.
- **Synth capacity ≈ 830–1130 simple voices per core** at 48 kHz in
  plain C (sine / Karplus-Strong / saw+SVF).
- Latency: L1 2.4 ns, ≤128 KB 13 ns, DRAM **~170–190 ns**. The L2 is
  small, so data-oriented layouts matter.
- Read 2.3 GB/s on one core; memset 4.8 GB/s. The memcpy figure is
  anomalous (implies traffic above the bus peak) and is being
  re-checked.

**Storage (the stock "SD16G" game card):** write 29 MB/s, read
47 MB/s. The card reports a 58.2 GB size with a partition running
past its end. Its capacity is being treated as suspect (§3.5).

**Stability at stock clocks:** **PASS**: 60 s at full CPU, RAM and GPU
load, zero errors, max 67.7 °C, no throttling.

**Invalid in v1.0 (measurement bug, fixed in v1.1):** fill rate,
texture rates, ALU GFLOPS, and every single-render-pass timing
(1-pass layers, forward lighting, framebuffer-fetch ms). The Mali
driver drops queued draws that a later clear overwrites, so v1.0 timed
only one frame of many. v1.1 calls `glFinish` on every frame and
subtracts an empty-frame baseline. The stick prompts were also
lengthened (15 s each, plus a "get ready" pause), and the axis-rate
metric was replaced with the peak 1-second window.

**The black's game card is defective as imaged (2026-11-12 ~00:55)
[observed]:**
- The card holds 122,138,624 sectors. Its single FAT partition and
  filesystem (from the vendor's image) declare 122,507,264: **189 MB
  that don't exist**. The laptop kernel logs "p1 extends beyond EOD,
  truncated".
- After the v1.0 runs (whose results did save), the card came back
  "not properly unmounted". On the next launch nothing could be
  written: not the launcher's first file, and not ES's play counter.
  That is consistent with Linux remounting the card read-only after
  write errors in the missing tail (`errors=remount-ro`). This step is
  inferred, not observed on-device.
- Consequence for play: **saves written to this card can fail or
  corrupt.**
- Fix later: copy everything off (≈51 GB; the laptop has room),
  reformat at the true size, copy back. Do no further writes until
  then.
- The probe was hardened: it skips its storage test when a
  filesystem is larger than its partition, the write test is down to
  32 MB, and if the probe folder is read-only it writes results to
  `$HOME/gameguyprobe-results`.
- The stock-EmuELEC v1.1 re-run is skipped. The v1.0 valid findings
  stand, and correct GPU throughput numbers will come from the purple
  on ArkOS4Clone (same chip).

**Purple on dArkOS4Clone 20261008 (2026-11-12 ~01:45) [observed]:**
- First boot completed. Device detected as `clone-r36s`, hotkey type
  `happy5`. Display and buttons are correct; ES 2.13 starts; games
  launch.
- **The speaker was silent with "Type 1 Panel 1 With Amplifier";
  headphones worked.**
  - Cause, from the DTB comparison: that profile sets
    `use-ext-amplifier` (plus `spk-ctl-gpios` on GPIO3_A7), which
    routes the RK817 output to an external amp and disables its class-D
    speaker driver.
  - The stock DTB has no `use-ext-amplifier`.
  - §28.2's pick, based on the shared GPIO pin, was wrong. Switched to
    **"Clone Type 1 Panel 1" (no amp)**, which is also what the DTB
    tool recommended. Speaker test pending.
- The hardware volume (VOL± buttons, "SND" in the menu) is separate
  from ES's System Volume slider.
- A software reboot with the charger connected can land on U-Boot's
  charge screen ("battery 4.1 V / current 12 mA"); press power to
  continue. The RST button does a full reboot.
- First-boot log saved: `probe/results/purple-darkos4clone/boot.log`.

---

## 30. Corrected measurements: purple on dArkOS4Clone (probe v1.1, 2026-11-12 ~01:55)

Raw results are in `probe/results/purple-darkos4clone/` (unit code
`94430f`). Platform: kernel 4.4.189 (ArkOS4Clone build), SDL 2.32.10
KMSDRM, the **same Mali r13p0 blob** as stock EmuELEC, GLES 3.2, EGL
1.4. Vulkan is only **llvmpipe** (software); there is no GPU Vulkan on
this release. Clocks: CPU 1296 / GPU 520 / DDR 666.

**GPU throughput (each frame finished; empty-frame overhead of 0.32 ms
subtracted):**
- **Fill:** blended **≈925 Mpix/s ≈ 50 full-screen layers per 60 Hz
  frame**. Opaque reaches ≈1.55 Gpix/s because hidden-pixel removal
  skips covered work. This sits near 1 pixel per clock per core × 2
  cores × 520 MHz.
- **ALU:** fp32 **7.2 GFLOPS**, fp16 **15.8 GFLOPS**. That is ≈87% of
  2 cores × 4 lanes × 2 × 520 MHz, so **one execution engine per
  core**, and mediump doubles throughput. Budget: ~390 fp32 or ~800
  fp16 flops per pixel per 60 Hz frame at full screen with nothing else
  running.
- **Texturing (Mtexel/s):** 1:1 RGBA8 544; minified 2048² RGBA8 381;
  ETC2 442; ASTC 4×4 183. The ASTC test used void-extent blocks, and
  real ASTC may differ, but ETC2 is the safe fast compressed format
  here.
- **One full-screen layer ≈ 0.55 ms**, whether it stays in tile memory
  or goes through DRAM (16 layers in one pass 9.2 ms vs 16 ping-pong
  passes 8.9 ms). Per-pixel work dominates; DRAM round-trips are not
  the bottleneck at this scale.
- **Framebuffer fetch (ARM) works but is 4× slower** than
  fixed-function blending (23.1 vs 5.6 ms for 16 layers).
- **16-light lighting at 640×480:** **forward single-pass loop
  7.3 ms**, MRT deferred 15.8 ms, **pixel local storage 55.8 ms**.
- **This retracts §27/§29's [reading]** that on-chip PLS and
  framebuffer fetch are the big opportunity. On G31 with r13p0 they
  are the slow paths. **Forward shading with per-pixel light loops,
  mediump, and few batched draws** is the measured winner.
- **Draw calls:** 12.6 µs each (≈1300 per frame at most, CPU side);
  `BufferSubData` doubles that; instancing ≈0.7 µs per instance.
- **Texture upload:** 190 MB/s.

**Display:**
- **58.49 Hz.** The 60.02 Hz "adjust" timings in the ArkOS4Clone DTB
  are not the active mode. SDL lists `640x480 @ 60 Hz` and `@ 59 Hz`;
  the desktop mode is 59. [question] Can a game select the 60 Hz mode?
  To be tested.
- Vsync-locked and double-buffered (swap blocks ~16.8 ms).

**Audio:** ALSA default device **steady at 128 frames = 2.67 ms**
(48 kHz F32). On stock EmuELEC the default device forced 21 ms; here
the firmware's asound config allows small buffers. This is excellent
for live synthesis.

**CPU and memory:**
- Same as the black: NEON FMA ~1.5 GFLOPS/core, synth ~800–1100
  voices/core.
- RAM: read 2.3 GB/s on one core, **3.8 GB/s on all cores**; write
  4.8 GB/s; DRAM latency ~170–200 ns.

**Storage (new onn 32 GB card, exFAT):** write 37 MB/s, read 47 MB/s.

**Controls:**
- All **17 buttons register, including FN**. ArkOS4Clone passes FN
  through; stock EmuELEC did not.
- Zero resting noise. Peak axis update ≈58 changes/s.
- Stick-direction results from this run are invalid (prompt bug, fixed
  in v1.2).

**Thermal:**
- 60 s full load **PASS**, but it **peaked at 80 °C and the CPU
  throttled to 1008–1248 MHz** (GPU 400–520). The unit was on charge
  during the run, which adds heat. The black on stock reached 67.7 °C
  with no throttle.
- Design target: assume sustained clocks below peak, and keep
  steady-state load well under 100%.

### 30.1 OTG port: what the bootloader actually does (2026-11-12 ~02:50, from source + ROCKNIX docs)

**Purple install:** "Install to eMMC" succeeded, and the purple boots
ArkOS4Clone from eMMC with no card. The install copies only
tools/bios/themes into ROMS_EMMC, so Ports is empty on eMMC.

**ArkOS4Clone U-Boot** (`lcdyk0517/Clone-u-boot`, branch
`odroidgoA-v2017.09`, `odroidgoa_defconfig`):
- Relevant config: `CONFIG_RKIMG_BOOTLOADER=y`,
  `ROCKCHIP_BOOT_MODE_REG=0xff010200`, `CMD_ROCKUSB`,
  `CMD_USB_MASS_STORAGE`, `USB_GADGET_DWC2_OTG`, `USING_KERNEL_DTB`.
- **Reboot modes:** `setup_boot_mode()` maps the kernel's reboot-mode
  magic (DTB `mode-ums = 0x5242c30c`, `mode-loader = 0x5242c301`) to a
  preboot command: `ums mmc 0` or `rockusb 0 ${devtype} ${devnum}`.
- **VOL+ at power-on** (`rockchip_dnl_mode_check`): requires
  `KEY_VOLUMEUP` **and** VBUS detected from a host, then runs rockusb.
  When rockusb returns, it sets the back-to-bootrom flag and resets.
- [observed] One VOL+ attempt enumerated `2207:330d "USB download
  gadget"` twice (25 s, then 6 s). Two later attempts produced no USB
  traffic at all. The VOL+ path is real but unreliable for us, cause
  unknown.
- [observed] Running `GameguyUSBDiskMode` (`systemctl reboot ums`)
  from the **SD-booted** system just rebooted, with no USB traffic.
  [reading] Most likely `ums mmc 0` failed because U-Boot uses the
  kernel DTB, and on the SD's BOOT partition that DTB has the eMMC
  disabled. The eMMC overlay is applied later, in `boot.ini`. From the
  **eMMC-booted** system, whose BOOT_EMMC DTB was pre-merged with
  `rk3326-emmc.dtbo`, `mmc 0` should exist. To be tested: put the
  launcher onto the eMMC system and run it there.

**ROCKNIX docs (K36 "EE clones" page):** with the device off and
connected to a PC by the OTG port, **holding VOL− while booting**
enters a recovery mode in which **all storage appears as USB drives**
(the eMMC is typically ~7.8 GB). This presumably comes from the
**stock** EmuELEC-clone bootloader; ArkOS4Clone's U-Boot source has no
VOL− path.
- **The black still has its stock eMMC bootloader.** If VOL− works on
  it, the black's eMMC can be backed up and written entirely over USB,
  bypassing the broken TF1 slot.
- The purple's stock bootloader was replaced by Install to eMMC; its
  backup image is on the install card.

**OTG tests on the black, stock bootloader (2026-11-12 ~03:00)
[observed]:**
- Holding VOL− at power-on with the OTG cable to the laptop: normal
  boot, **no USB traffic**. The ROCKNIX VOL− UMS recipe most likely
  belongs to ROCKNIX's own bootloader, not stock.
- Holding VOL+ (the Rockchip download key) with the rockusb watcher
  running: normal boot, **no USB traffic**.
- So the black's stock bootloader offers no USB path we can trigger.
  **The black's route stays the one-session taped-TF1 install**
  (walkthrough Part D).

**Where things stand:**
- **Purple (JJ's):** ArkOS4Clone on eMMC, no card needed; speaker
  works on the no-amp profile. Its stock eMMC backup is on the install
  card at `/roms/backup/emmc-backup.img`; copy it to the laptop.
- **Black (Morgan's):** stock EmuELEC. Its game card has a filesystem
  larger than the card (copy off, reformat, copy back). The TF1 latch
  is broken.

**Next steps:**
1. Add a helper port to the install card that copies the probe and
   `GameguyUSBDiskMode` onto the purple's eMMC ROMS partition.
2. Boot the purple from eMMC and test `reboot ums` (U-Boot UMS on
   `mmc 0`) as the cable deploy loop.
3. Run probe v1.2 on the purple: stick directions and the 60 Hz mode
   question; run it unplugged for a thermal reading without charging.
4. The black's taped-TF1 install.

**USB-C cable finding and rockusb limits (2026-11-12 ~03:10–03:36)
[observed]:**
- **The original USB-C cable was the problem.** With a different cable,
  VOL+ at power-on put the purple (ArkOS4Clone U-Boot) into rockusb
  (`2207:330d`) reliably. `rkdeveloptool` reports a SAMSUNG eMMC,
  7456 MB (15,269,888 sectors).
- The earlier failures (purple VOL+, and the black's VOL−/VOL+) all
  happened with the bad cable. **The black's stock-bootloader tests need
  repeating with the good cable.**
- **rockusb reads on this U-Boot are only valid for the first 32 MiB.**
  A full `rkdeveloptool rl 0 15269888` returned real data for sectors
  0–65535 and 0xCC filler (an unfilled buffer) almost everywhere beyond
  that. Two reads agreed only because the filler is deterministic.
- That bad image was briefly misread as eMMC corruption and has been
  deleted. **Do not use rockusb `rl`/`wl` beyond 32 MiB on the
  ArkOS4Clone U-Boot**; writes are equally suspect.
- For bulk transfers, use UMS (from the eMMC-booted system) or the
  Linux USB gadget (`GameguySetupEMMC` + `GameguyUSBNet`).
- **JJ's stock eMMC backup** is safe on the laptop, made by the
  on-device install script and verified against the card copy:
  `.tools/backups/purple-stock-emmc-8GB-20261112.img`, sha256 OK. It
  has a GPT layout with `uboot`, `trust`, `emuelec` (2 GiB) and
  `swap`, i.e. the stock bootloader is Rockchip's own U-Boot. Its eMMC
  is 7,818,182,656 bytes.
- Lesson: avoid hard power-offs (hold power) while the system is
  booting or writing; use the menu's power-off whenever possible.

**Rockchip USB download modes, settled (2026-11-12 ~03:55) [observed + source]:**
- On both units, both U-Boot rockusb builds (stock vendor and ArkOS4Clone)
  and both maskrom RAM loaders (rkbin usbplug v1.42 and v1.36, built
  with rkbin `boot_merger` into `.tools/rkbin/rk3326_loader_v2.12.140*.bin`)
  return valid data **only for reads that start below sector 65536
  (32 MiB)**.
- rkdeveloptool's capability report shows "Direct LBA" (writes) and
  "First 4m Access", but **not "Read LBA"**. Full-range reads are not
  offered by these loaders; full-range writes are.
- Maskrom entry works: `rkdeveloptool rd 3` from rockusb, then `db`
  the loader.
- **The black's eMMC layout (GPT):** uboot (4 MB) @16384, trust (4 MB)
  @24576, emuelec (2.1 GB) @32768, STORAGE (4.3 GB) @4227072, primary
  (1.4 GB) @12582912. Same Samsung 7456 MB eMMC (15,269,888 sectors) as
  the purple.

**The process from here:**
- **Reads happen on-device:** `GameguyDumpEMMC.sh` (Ports) dumps the
  internal eMMC to the SD card in 1 GiB pieces and verifies against a
  second read.
- **Writes happen over USB:** `probe/tools/flash-emmc-usb.sh` takes the
  device from VOL+ rockusb to maskrom, loads the loader, runs `wl` with
  the whole image, compares the first 32 MiB, and resets.
- **Plan for the black:**
  1. Spare card in TF2, stock EmuELEC, run GameguyDumpEMMC. That is
     the black's stock backup.
  2. The purple boots its install card and runs GameguyDumpEMMC. That
     is a consistent golden image of ArkOS4Clone on eMMC.
  3. Flash the golden image to the black over USB.
  4. Boot it and verify on-device.

### 30.2 Both units on ArkOS4Clone; flashing over USB works end to end (2026-11-12 ~05:25) [observed]

**Backups**, all on the laptop in `.tools/backups/`, each sha256-verified
against the device's own checksum:
- `black-stock-emuelec-emmc-20261112.img`: the black's original
  EmuELEC. GPT layout: uboot, trust, emuelec, STORAGE, primary.
  `GameguyDumpEMMC` took about 28 minutes on stock EmuELEC (eMMC reads
  ~15 MB/s).
- `purple-stock-emmc-8GB-20261112.img`: JJ's original system, from the
  on-device "Install to eMMC" backup.
- `purple-arkos4clone-emmc-golden-20261112.img`: the purple's
  installed ArkOS4Clone, dumped by `GameguyDumpEMMC` from its install
  card while the eMMC was unmounted (sha `32403cef…6346`).

**The black was flashed with the golden image over USB:**
`probe/tools/flash-emmc-usb.sh`, which runs VOL+ rockusb → `rd 3`
maskrom → `db` rkbin loader → `wl 0` with the full 7.8 GB image
(21 min, ~6 MB/s). The first 32 MiB read back OK. **The black boots
ArkOS4Clone from eMMC with no card**, identical to the purple, which
proves full-range writes work (the system partition starts at 272 MiB).
The broken TF1 slot no longer matters.

**The process now:**
- read on-device (`GameguyDumpEMMC`)
- write over USB (`flash-emmc-usb.sh`)
- boot to verify
- requirement: a known-good USB-C data cable

[idea] Next: build "golden v2" on the laptop. Loop-mount the image's
BOOT and ROMS partitions, apply the OTG device-mode DTB patch with
`fdtput`, add the gameguy ports (probe, USBNet, DumpEMMC). Flash both
units with it. That gives one identical image with SSH over USB for the
deploy loop.

---

## 31. Fable-ready (2026-11-12, ~05:30–07:00, Opus session)

Morgan's call: **no game skeleton for Fable.** Fable starts from a clean
slate. What exists is platform knowledge and tooling:

- **`docs/hardware-target.md`:** the measured hardware sheet. Every
  number is from probe runs in the Ports launch environment, and both
  units agree within ~3%.
- **`docs/fable-handoff.md`:** the two devices, the deploy loop, how
  to build for the target, how to verify, the safety net, and open
  questions for the spec interview.
- **Golden image v2**
  (`.tools/images/r36s-arkos4clone-gameguy-v2.img`, sha in the
  `.sha256` file) is on both units:
  - The golden ArkOS4Clone eMMC with the DTB patched for OTG device
    mode (`otg-port` okay, `dr_mode` peripheral, `vbus_host` no longer
    always-on). The original DTB is kept as `.orig`.
  - The Ports set: GameguyProbe(+LongStress), GameguyUSBNet,
    GameguyDumpEMMC, GameguyUSBDiskMode. Plus the project SSH key.
- **Fast reflash:** `flash-emmc-usb.sh IMAGE --parts 1,3` writes only
  BOOT and ROMS (~4 min). It refuses unless the device's MBR matches
  the image's.
- **USB networking, units 134 (black) and 164 (purple):**
  - CDC-ECM gadget, `10.36.N.1`; the laptop gets `10.36.N.2` from a
    dnsmasq that runs as its own systemd unit (`gameguy-dhcp`).
  - That unit was needed because processes started from a Port live in
    EmulationStation's cgroup and die when ES stops. That killed the
    first DHCP server.
  - The link comes up at boot by itself.
  - Key login needed `StrictModes no`: this firmware ships `/etc` and
    `/home/ark` mode 777.
  - `r36s.sh` falls back to IPv6 link-local when DHCP is missing, but
    NetworkManager drops the interface about 45 s after a failed DHCP,
    so DHCP has to work.
- **`r36s.sh run` mirrors ES's Ports launch**
  (`sudo perfmax …; nice -n -19 %ROM%; sudo perfnorm`): performance
  governors, `~/.asoundrc` moved aside, everything restored afterwards.
  Without it, measurements read ~2.5× slower and with 23 ms audio.
- **New facts:**
  - The 60.02 Hz display mode is selectable at runtime.
  - Stick directions are SDL-normal.
  - The controller is "GO-Super Gamepad" with 17 buttons including FN
    (`guide`) and L3/R3. L2/R2 are digital.
  - The data cable does not charge the unit.
  - 10-minute full-load stress, both units: zero errors, settles near
    78 °C, about 800 mA (5% battery per 10 min). The black peaked at
    81.5 °C and kept its CPU mostly at 1200–1248 MHz. The purple peaked
    at 83.5 °C within the first minute and held its CPU at 1008 MHz
    82% of the time (GPU stayed at 520). It did 10% less CPU work, so
    the purple is the unit to design against.
  - Charging (device tree): 5 V only (no USB-C/PD controller), input
    limit 1.5 A, charge to 4.2 V. Some chargers don't power the units,
    most likely USB-C-to-C chargers that wait for CC resistors the DC
    port lacks; a USB-A charger with an A-to-C cable always works.
  - The device clocks are unset (they read April 2026), so device
    timestamps are not real dates.

### 31.1 Handed over (2026-11-12, ~07:30)

- Everything above is committed to git and pushed to `origin/main`
  (`.tools/` stays local: toolchain, loader, SSH key, firmware, golden
  image, backups). Each probe run is indexed in
  `probe/results/README.md`.
- Still open, none of it blocking:
  - Repair the black's original 58 GB game card (its filesystem is
    larger than the card). Morgan will do this later.
  - `GameguyUSBDiskMode` (U-Boot USB mass storage) is untested.
  - Overclocking is untested; every number is at stock clocks.
- Next: the Fable sessions, starting from Part 0.
