#!/usr/bin/env python3
"""Two listening sketches for part two of the design (design/the-depths.md). Kept in design/listen/sketches/ beside the clips it makes.
Everything is struck and dies away; nothing is held.

  j-one-chord-six-grounds.wav   home's own chord (C, E, G, tuned pure) struck over the note of each
                                place of a day in C: home, the cave that remembers (A), the cave
                                that aches (E), the land that floats (F), the cave that runs (D),
                                the land that leans (G). Then the lean's own chord over that same
                                G, and home.
  k-what-moves-least.wav        the seven chords of the key with every root falling a fifth
                                (F, B, E, A, D, G, C), first as full chords led by the nearest
                                step, then as a bass and two lines only: at each change one line
                                stays and the other steps down.

Usage: python3 -I sketches4.py OUTDIR
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sketches2 as s2  # noqa: E402

C4 = s2.C4


def ground(m, ratio, t, gain=0.5):
    """The place's own note, struck low, with enough top for a small speaker."""
    m.note(C4 * ratio, t, 1.0, gain, wave=s2.BASS, attack=0.008, release=0.4, decay=0.75)


def sketch_j():
    m = s2.Mix(40)
    chord = [C4 * 1.0, C4 * 3 / 2, C4 * 5 / 2]          # opened out: C4, G4, E5
    # (ground as a ratio to middle C, in the bass)
    # low, so each ground sits well under the chord: nearer, the ears measured more roughness
    places = [1 / 2, 5 / 12, 5 / 8, 1 / 3, 9 / 16, 3 / 8]      # C3, A2, E3, F2, D3, G2
    t = 0.3
    for r in places:
        ground(m, r, t)
        m.struck(chord, t + 0.28, 0.42, wave=s2.KEYS, ring=1.2)
        ground(m, r, t + 1.7, gain=0.34)
        m.struck(chord, t + 1.98, 0.30, wave=s2.KEYS, ring=1.0)
        t += 3.6
    # the hang falls: the lean's own chord over the same G, then home over C
    ground(m, 3 / 8, t)
    m.struck([C4 * 9 / 8, C4 * 3 / 2, C4 * 15 / 8], t + 0.28, 0.42, wave=s2.KEYS, ring=1.3)   # D4 G4 B4
    t += 2.4
    ground(m, 1 / 2, t, gain=0.55)
    m.struck(chord, t + 0.28, 0.46, wave=s2.KEYS, ring=2.2)
    m.save("j-one-chord-six-grounds.wav")


def sketch_k():
    m = s2.Mix(40)
    # every root falls a fifth: F, B, E, A, D, G, C. Bass, then three voices led by the nearest step.
    bass = [2 / 3, 15 / 32, 5 / 8, 5 / 12, 5 / 9, 3 / 8, 1 / 2]   # F3 B2 E3 A2 D3 G2 C3
    triads = [
        [2 / 3, 5 / 6, 1.0],            # F3 A3 C4
        [2 / 3, 15 / 16, 9 / 8],        # F3 B3 D4
        [3 / 4, 15 / 16, 5 / 4],        # G3 B3 E4
        [5 / 6, 1.0, 5 / 4],            # A3 C4 E4
        [5 / 6, 10 / 9, 4 / 3],         # A3 D4 F4
        [15 / 16, 9 / 8, 3 / 2],        # B3 D4 G4
        [1.0, 5 / 4, 3 / 2],            # C4 E4 G4
    ]
    t = 0.3
    for i, (b, tri) in enumerate(zip(bass, triads)):
        last = i == len(bass) - 1
        ground(m, b, t, gain=0.42)
        m.struck([C4 * 2 * r for r in tri], t + 0.05, 0.36, wave=s2.KEYS, ring=2.0 if last else 0.9)
        t += 2.6 if last else 1.35
    t += 0.9
    # the same seven as a bass and two lines: thirds and sevenths. One stays, one steps, every time.
    upper = [5 / 2, 9 / 4, 9 / 4, 2.0, 2.0, 15 / 8, 15 / 8]       # E5 D5 D5 C5 C5 B4 B4
    lower = [5 / 3, 5 / 3, 3 / 2, 3 / 2, 4 / 3, 4 / 3, 5 / 4]     # A4 A4 G4 G4 F4 F4 E4
    for i, (b, u, lo) in enumerate(zip(bass, upper, lower)):
        last = i == len(bass) - 1
        ground(m, b, t, gain=0.42)
        ring = 2.2 if last else 1.15
        m.note(C4 * lo, t + 0.05, ring, 0.20, wave=s2.HUM, attack=0.02, release=0.5, decay=ring * 0.9)
        m.note(C4 * u, t + 0.07, ring, 0.15, wave=s2.HUM, attack=0.02, release=0.5, decay=ring * 0.9)
        t += 2.8 if last else 1.5
    m.save("k-what-moves-least.wav")


if __name__ == "__main__":
    s2.OUT = sys.argv[1] if len(sys.argv) > 1 else "."
    sketch_j()
    sketch_k()
