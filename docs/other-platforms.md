# Other platforms

_PC, other consoles and phones: what already travels, what doesn't, and the rules to keep from now
so a port stays possible. Written on 2026-11-17, when Morgan asked whether to keep them in mind. The
R36S stays the target._

Morgan, today: "this console is the current target and all but if this game turns out to be a hit it
might be cool to move forward keeping in mind the possibilities of PC / other console / mobile
format... thoughts"

## Short answer

- **Yes, keep them in mind.** None of it changes what the handheld game is. The rules below are ones
  the game needs anyway, because takes have to replay exactly.
- **Most of the game already travels:**
  - the R36S's controls are a standard controller;
  - lines of light redraw at any size;
  - every sound is synthesised, so there are no recordings to redo;
  - there's one line of text at most, so translating is small;
  - the world gives the same result on every machine tried so far (measured today, below).
- **Three things don't travel by themselves:**
  - the cable, which becomes a network;
  - the R36S's short sound delay: most other devices are slower and some much slower, and this is a
    game about letting go on the one;
  - touch screens, which need controls of their own.
- **Starting on the smallest machine is the right direction.** A game built for this handheld fits
  every bigger machine. Going the other way is where ports usually lose things.

## Measured today: one take, many builds

The replay test (`toys/wheel/tools/same-take.zig`, fixed this evening, see below) runs twenty
minutes of the wheel toy's rules and sound at fixed steps. Every minute it prints a fingerprint of
the world, one of the sound, and the loudest sample. Built in other ways, it gives:

| build | where it ran | world and sound, twenty minutes |
|---|---|---|
| Zig, for x86_64 Linux | laptop | the reference |
| Zig, for aarch64 Linux | the purple | identical |
| Zig, for WebAssembly | laptop, in Node 24's engine (V8, the one in Chrome) | identical |
| Zig's C output, compiled by Clang, for x86_64 | laptop | identical |
| the same C, Clang, for aarch64 | laptop, emulated (qemu) | identical |
| the same C, with multiply-add fusion allowed, x86_64 | laptop | both differ from the first minute |
| the same, aarch64 | laptop, emulated | both differ, and its world differs from the x86_64 build with fusion too |
| the same C, GCC 16 | | doesn't compile |

- **WebAssembly needed two changes,** made in a scratch copy, not in the toy:
  - The toy hands the beat from the sound thread to the world as a 64-bit atomic, which Zig doesn't
    allow on WebAssembly. There is one thread there, so plain reads and writes do.
  - The WASI C library stopped the program at start-up under Node (exit code 71), so it was built
    without a C library. The maths comes from Zig's own code either way.
- **The first version of this test compared silence.** It never built the synth's wavetables, so
  this morning's "identical sound" on the laptop and the purple was two machines agreeing on
  nothing. The C build exposed it: Zig's C output fills unset memory with a marker pattern, where
  Zig's own build happened to find zeros, so its "sound" differed. The world's fingerprints were
  real all along. Every row above is from the fixed test, which prints the loudest sample on every
  line (0.946 of full scale here).
- **The C route** is how code reaches compilers that take only C or C++, which is mostly what
  console kits provide. Through it the world and the sound came out identical. It showed three
  traps:
  - With multiply-add fusion allowed, the world changes from the first minute. Zig never fuses
    unless asked; a C compiler may, so a C build must turn it off (`-ffp-contract=off`).
  - Zig's C output computes a float `@mod` as a - floor(a/b) * b, which rounds twice, so it differs
    from Zig's own unless the divisor is a power of two. In a separate check of two million values,
    sine, cosine, exp, tanh and atan2 matched exactly and float `@mod` didn't. The toys' rules only
    divide by powers of two.
  - GCC 16 doesn't compile Zig's C output (it declares thread-local variables twice). Clang does.
- **Windows and Apple Silicon Macs:** Zig builds this test for both from the laptop. They were
  built, not run.

## Platform by platform

| platform | controls | picture | what's new |
|---|---|---|---|
| Steam Deck, Linux PCs | the same layout, plus extras the game doesn't need | OpenGL ES 3 through Mesa, as on the laptop; the Deck is 1280×800 | almost nothing: the laptop build |
| Windows | any pad, through SDL | OpenGL ES through ANGLE (Google's layer over Direct3D), or desktop OpenGL | Zig builds for Windows from this laptop (the test above: built, not run) |
| Mac | any pad | Apple deprecated OpenGL in 2018 and it still runs; the lasting route is Metal | Apple's tools to sign and ship it; Zig builds for Apple Silicon from this laptop (built, not run) |
| web browsers | pads, through the browser | WebGL 2 is OpenGL ES 3.0, so the toys' shaders run as written | measured identical above; sound timing differs by browser |
| Android | pads, or touch | OpenGL ES 3 is the phone's own | touch controls; sound delay varies a lot by phone |
| iPhone, iPad | pads, or touch | OpenGL ES deprecated since iOS 12 and still runs; the lasting route is Metal | touch controls |
| Switch, PlayStation, Xbox | the Switch's pads match the R36S; the others' too | through each maker's kit | the makers' licences and kits, under NDA; SDL3 already runs on all three for licensed developers |

## Sound delay matters most

- **The game judges a release against the beat you hear.**
- **On the R36S** the sound goes out in 128-frame buffers at 48,000 Hz, 2.7 ms each (measured), to a
  wired speaker or headphones. The whole delay from a button to your ear hasn't been measured.
- **Elsewhere it's longer.** Phones vary by model, and Bluetooth headphones commonly add a tenth of
  a second or more (general knowledge, not measured here).
- **So every other platform needs:**
  - a calibration: tap along to a click once, and the game learns the delay;
  - judging in heard time: the game knows when each beat reaches your ears and judges against that.
- **And the game needs, everywhere, this one included:** the world counts beats by its own steps,
  and the sound follows. That's the fixed-step rule again.

## Screens

- **R36S:** 640×480, 4:3, 3.5 inches, 229 pixels per inch.
- **Elsewhere:** 16:10 (Deck), 16:9 (TVs and most PCs), about 20:9 (phones), 4:3 (iPads).
- **Compose for 4:3.** A wider screen shows more sky and water at the sides, never more information.
- **Lines of light redraw at any resolution** (Walt's poster in `design/the-card.md`), so a bigger
  screen gets finer lines, not blurrier ones.
- **Faster screens** (90 to 144 Hz): the world still steps 60 times a second, and the picture is
  drawn between steps. Takes don't change.

## Controls

- **The R36S has** two clickable sticks, four face buttons, L1 and R1, L2 and R2 (buttons, not
  pressure triggers), a d-pad, Select and Start. That's an Xbox, PlayStation or Switch pad, and
  everything maps one to one.
- **Keep the game to that pad:** nothing that needs pressure triggers, motion or touch.
- **Face buttons by position,** as the toys already do, so it doesn't matter that Nintendo's and
  Microsoft's pads print their letters in different places.
- **Touch is its own design.** The game's verbs are hold, steer and let go on the one, which are
  natural on glass: press, slide, lift. The wheel especially. Moving and singing at once is the hard
  part. A touch scheme should be a toy of its own, tested by hand.

## Together, elsewhere

The design in `design/together.md`, on other machines:

- **Two devices on one network** (two Decks, two Switches, two phones on the same Wi-Fi) do what the
  cable does, with a few milliseconds where the cable has half of one. Visits work unchanged.
- **One screen, two pads** (a TV, a PC, a docked Deck): Drip's seat works as it is, because Drip
  rides on Hum's head and needs no second camera. Two Hums on one screen need a camera that frames
  both, or a split screen, and a visit reads best on two screens, because each screen draws the
  world through one player's home.
- **Far apart, online.** Across the internet a friend is often 30 to 150 ms away, which is too late
  to play on the same beat. Online jamming tools get round this by delaying the other player by a
  whole bar or more, so they arrive late but in time (NINJAM works this way). Here a far-away friend
  would be a live echo, a bar behind, in canon with you. Call and response keeps working. Unison,
  like the clap together and the duet, stays a thing for one room.
- **Letters work everywhere as they are.** A take from an R36S plays on a phone and the other way
  round, because the world gives the same result everywhere it has been tried.

## Rules to keep from now

1. **The world is pure.** The rules and the sound don't call the platform. They take hands and a
   step and give back a world and samples. The toys already work this way
   (`toys/wheel/src/world.zig`, `music.zig`, `synth.zig`).
2. **The world keeps its own time.** Fixed steps, with the beat counted by steps, never taken from
   the sound card or the screen. The toys don't do this yet: `world.step(in, dt, shared.beat())`
   takes the beat from the sound.
3. **Our own maths.** Sine, exponential and the rest come from Zig's own code, never from the
   platform's C library. Nothing fuses a multiply and an add in the world: Zig's default is strict,
   so keep it, and build any C route with fusion off. Float `@mod` only by powers of two, or written
   out ourselves, because Zig's C output computes it differently.
4. **One thread runs the world.** The sound can have its own thread, but the world never depends on
   thread timing.
5. **The same-take test on every build,** on every platform, before every release. A mismatch is a
   bug, and so is a test that can pass on silence: it prints the loudest sample for that reason.
6. **Takes are documented files:** little-endian, versioned, and marked with the game version that
   wrote them (`design/the-card.md`).
7. **OpenGL ES 3.0, which is WebGL 2.** Nothing from 3.1 or 3.2 without a fallback, even though the
   Mali-G31 has them.
8. **Composed for 4:3, shown at any width.**
9. **The pad, by position.**
10. **One line of text at most,** as already ruled.
11. **Files behind one door.** The card is one place to keep the world and the book; a phone or a PC
    keeps the same files somewhere else.
12. **Together-play is call and response first** (`design/together.md`).
13. **The platform layer stays small.** In the toys it is one file, `toys/common/platform.zig` (288
    lines), which loads SDL2 and OpenGL ES at run time. A move to SDL3, or to Metal and Vulkan
    through SDL3's own GPU layer, changes that file and the drawing code and nothing in the world.

## If it's a hit: an order

My recommendation, by how much each platform would change the game:

1. **Steam: Linux, the Steam Deck and Windows.** The same pad and the same screen shape, near
   enough, and the Deck is a handheld like this one. The game there is the same game.
2. **The web,** first for the book and for letters: a page that plays any take anyone sends you.
   Then perhaps the whole game.
3. **Switch-class consoles,** through the makers' programmes. The pads match; the kits come under
   NDA.
4. **Phones last,** because touch and sound delay each need their own design, and both change how it
   plays.

## Sources

- SDL wiki: [Nintendo Switch](https://wiki.libsdl.org/SDL3/README-switch/raw) ("SDL3 runs on the
  Nintendo Switch", Switch 2 included, for developers under NDA with Nintendo),
  [PS5](https://wiki.libsdl.org/SDL3/README-ps5) (commercial games ship with the port), [Xbox
  (GDK)](https://wiki.libsdl.org/SDL3/README-gdk/raw) (licensed Xbox developers), [supported
  platforms](https://wiki.libsdl.org/SDL3/SupportedPlatforms/raw).
- [AnandTech, 2018: Apple deprecates OpenGL across all its
  systems](https://www.anandtech.com/show/12894); [Apple: migrating OpenGL code to
  Metal](https://developer.apple.com/documentation/metal/migrating-opengl-code-to-metal.md).
- From general knowledge, not looked up today: NINJAM's interval delay; typical Bluetooth audio
  delay; typical internet round trips.
- Measured here, 2026-11-17: the builds in the table above, from `toys/wheel/tools/same-take.zig`.
