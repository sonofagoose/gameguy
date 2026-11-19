# Toys

Small, throwaway programs that each test one idea on the handheld before the game is designed
around it. They are not the game and not a starting point for it.

| toy | tests | status |
|---|---|---|
| `remainder/` | steering by being slightly out of tune (2D, with live synthesis) | played on the black unit 2026-11-12. Verdict: interesting mechanic, "not much feels like a game". Its measurements are in `docs/hardware-target.md`. That session ran the world at about a quarter speed while the sound ran at full speed (a frame-time bug, fixed 2026-11-14), so the verdict was on a slowed toy. |
| `meadow/` | how much 3D world the handheld draws, and how moving through it feels | its benchmark ran on the black unit 2026-11-14: the whole meadow in 8 to 12 ms of GPU, 76,000 triangles a frame with every frame on time. On 2026-11-17 Morgan dropped its solid look for the page toy's lines of light ("scrap the meadow style"), so it stays only as a measurement. |
| `wheel/` | the wheel in a fight: stand where they meet, strike on the one, walk three creatures home in one breath (2D, live synthesis) | a scripted player has run it through on the black unit 2026-11-14 (17.09 ms a frame, none late, no audio gaps). Nobody has played it by hand yet. |
| `page/` | flat or deep, or both: the wheel toy's garden and rules, seen as a page from above, as a place from behind the creature, or as a page that stands up when the third note sounds and folds flat again while the wheel is held. Since 2026-11-17 also the beam (lines of light that linger like an oscilloscope's) and the book (each session kept on the GAMEGUY card) | a scripted player has run all three looks on the black unit 2026-11-14 (17.1 ms a frame, no audio gaps). Morgan played it by hand the same day: "it was all feeling really good", "really liked the little 'oh' moment"; his fuller report is to come. |
| `common/` | shared code: SDL2 and OpenGL ES loaded at run time, PNG frame dumps, the label font, a heads-up text layer | |

Every launcher does three things while its toy runs (`docs/hardware-target.md` has the
measurements behind each):

- gives the storage controllers' interrupts a core of their own. Without that, any read or write
  of the built-in storage stalls frames for up to a quarter of a second;
- pins the CPU, GPU and memory clocks at full speed. Left to scale, they drop a toy to about two
  thirds of its frame rate;
- lets the sound thread run at real-time priority. Without that, the sound can gap for about a
  hundredth of a second every half minute.

Each toy builds with its own `build.sh` (Zig from `.tools/zig`) into git-ignored `build/` and
`dist/` folders. `dist/ports/` is what gets copied to the handheld.
