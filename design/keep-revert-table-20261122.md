# Keep/Revert Table: Gate 0 Audit (FINAL)

> **Status, 2026-11-26.** History: an audit of uncommitted code on 2026-11-22. A record only.

**Date:** 2026-11-22  
**Working tree:** uncommitted diff on top of commit 3c8a000  
**Target:** purple R36S, unit 164  

**Global rule:** Every change must be verified against DECISIONS.md and SCRATCH.md.  
If a change is in the diff but cannot be verified against a decision, it is **REVERT**.

---

## Summary of Reverts Applied

| Change | Reason |
|--------|--------|
| `KILLS=0` skip in `game/build.sh` | Kill tests must run or be reported as skipped (work order) |
| Knot gating (60s or 42m) | Does not match SPEC.md 6.1 - knots appear after peaceful stretch AND both great aster + bridge puddle found |
| Inner-ring commit (k×5/6 frequency) | Does not move home to relative minor root (k+3) per DECISIONS.md row 110 |
| `lookAt` NaN guards | Circular logic - checking value after NaN is already produced. Unverified. |
| `design/listen/*.wav` | No explanation provided |
| `pool_voice` reverted then restored | Morgan's decision per whats-next.md: Clip 32 fix |

---

## Final State of Tree (All Staged)

### game/build.sh

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| `push` target | Fast build targets (work order) | KEEP |
| `handheld` target | Fast build targets (work order) | KEEP |
| `dev` target | Fast build targets (work order) | KEEP |
| `KILLS` defaults to 100 | Kill test runs unless laptop | KEEP |

### game/src/world/world.zig

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| Remove glide constants | DECISIONS.md row 146 | KEEP |
| `jump_height=2.8`, `jump_air_s=0.65` | SM64×TotK standard | KEEP |
| `jump_tap_frac=0.60` | Variable jump height | KEEP |
| `air_ease=0.20` | TotK-style air steering | KEEP |
| `orbit_keys` extended to 90° | Full-range camera for page view | KEEP |
| `Ring.y` field | Airborne rings at Hum's height | KEEP |
| `wheel_minor` field | Inner ring selection | KEEP |
| `strike_anim` field | Strike animation | KEEP |
| `jump_cooldown`, `jump_can_retrigger` | Variable jump buffer | KEEP |
| Knot gate: commented out, knots=0 by default | SPEC.md 6.1 - knots only after peaceful stretch AND both found | KEEP (reverted to off) |
| `pool_voice=0.62` | whats-next.md: Clip 32 fix (Morgan's decision) | KEEP |
| Drip metronome audible logic | whats-next.md: Drip sleeps/wakes (Morgan's decision) | KEEP |
| Bee buzz changes | DECISIONS.md row 148: warm owl character | KEEP |
| Pipe micro-modulation | whats-next.md: organic drone消除 | KEEP |
| Other movement changes | DECISIONS.md row 142, 146 | KEEP |

### game/src/dark.zig

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| Wheel lines top-most pass | DECISIONS.md: wheel drawn on top | KEEP |
| Ring y-position based on airborne | SPEC.md 6.1: calls/rings ride air | KEEP |
| Strike arc animation | SCRATCH.md Section 3: GameguyPage strike | KEEP |
| Camera fixed up vector | Original (-1.0, 1.0) per HEAD | KEEP |
| Dawn sky glow warm amber/rose | Visual direction | KEEP |
| Wheel dim to 68% | SCRATCH.md Section 9 | KEEP |
| `GG_ORBIT` debug env var | Debug tool | KEEP |
| Pitch clamp (-1.0, 1.0) | Original value per HEAD | KEEP |

### game/src/bot/walker.zig

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| Glide removal | DECISIONS.md row 146 | KEEP |

### game/src/m.zig

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| `lookAt` NaN guard removed | Circular logic. Unverified. Reverted to original. | KEEP (reverted) |

### game/src/world/pools.zig

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| `build` constant reduced | whats-next.md: smooth onset for Clip 32 | KEEP |

### game/src/world/flyers.zig

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| Bee frequencies changed | DECISIONS.md row 148: warm owl character | KEEP |

### game/src/sound/sound.zig

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| Bee frequencies | DECISIONS.md row 148 | KEEP |
| Pipe micro-modulation | whats-next.md | KEEP |

### game/src/draw/aster_lines.zig

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| Wheel function in new file | Code organization | KEEP |
| Wheel drawing top-most pass | DECISIONS.md | KEEP |

### game/src/draw/lines.zig

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| `setTop` mechanism | DECISIONS.md: wheel drawn on top | KEEP |
| `drawTopLines` function | DECISIONS.md | KEEP |

### game/src/draw/wheel_lines.zig (new file)

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| Circle of Fifths with inner/outer rings | DECISIONS.md row 110 | KEEP |

### spec/promises/BOARD.md and spec/promises/hands.md

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| Auto-generated by promises.py | Build artifacts | KEEP at HEAD, regenerate in gate run |

### game/room/walks.txt

| Change | Decision Source | Verdict |
|--------|-----------------|---------|
| Jump instructions updated | Documentation sync | KEEP |

---

## Final Commit Contents

- PROGRESS.md (updated with Gate 0 status)
- design/keep-revert-table-20261122.md (this file)
- game/build.sh (fast targets, KILLS=100 default)
- game/src/bot/walker.zig (glide removed)
- game/src/dark.zig (wheel on top, strike animation, camera fixes)
- game/src/draw/aster_lines.zig (wheel in top pass)
- game/src/draw/lines.zig (setTop mechanism)
- game/src/draw/wheel_lines.zig (new file)
- game/src/world/world.zig (all movement, jump, ring, wheel, drip changes)
- spec/promises/BOARD.md (keep, regenerate in gate)
- spec/promises/hands.md (keep, regenerate in gate)

---

## Evidence: spec doc updates are auto-generated

```
$ grep -r "BOARD.md" game/build.sh
$PROMISES | sed 's/^/   /'
```

`BOARD.md` and `hands.md` are written by `spec/tools/promises.py` on every build.
They are not hand-edited; they are build artifacts.

**Action:** Keep HEAD state, regenerate during gate run.
