# Toys

Small, throwaway programs that each test one idea on the handheld before the game is designed
around it. They are not the game and not a starting point for it.

| toy | tests | status |
|---|---|---|
| `remainder/` | steering by being slightly out of tune (2D, with live synthesis) | played on the black unit 2026-11-12. Verdict: interesting mechanic, "not much feels like a game". Its measurements are in `docs/hardware-target.md`. |
| `meadow/` | how much 3D world the handheld draws, and how moving through it feels | runs on the laptop; not yet run on the handheld |
| `common/` | shared code: SDL2 and OpenGL ES loaded at run time, PNG frame dumps, the label font, a heads-up text layer | |

Each toy builds with its own `build.sh` (Zig from `.tools/zig`) into git-ignored `build/` and
`dist/` folders. `dist/ports/` is what gets copied to the handheld.
