#!/usr/bin/env python3
"""One listening sketch for part three of the design (design/the-wormhole.md). Kept in design/listen/sketches/ beside the clips it makes.
Everything is struck and dies away; nothing is held.

  l-the-elevator.wav   one note on top that never moves (C), struck again with each chord, while the
                       roots under it go flatward round the wheel a cell at a time: C, F, B flat,
                       E flat, A flat, D flat, and home. Each chord is a plain major chord tuned pure
                       to its own root, with the top C exactly where it was: the 1, then the 5, the
                       9, the 13, the 3 and the 7 of what is under it.

Usage: python3 -I sketches5.py OUTDIR
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sketches2 as s2  # noqa: E402

C4 = s2.C4


def sketch_l():
    m = s2.Mix(40)
    top = C4 * 2                                   # the one note: C5
    # the root of each chord as a ratio to middle C, chosen so the top C is pure over it
    # (bass root, the two notes of the chord between middle C and the top note), as ratios to
    # middle C, each chord pure to its own root and the top C pure over it
    chords = [
        (1 / 2, [5 / 4, 3 / 2]),      # C:  E4 G4      the top C is its 1
        (2 / 3, [4 / 3, 5 / 3]),      # F:  F4 A4      its 5
        (4 / 9, [10 / 9, 4 / 3]),     # Bb: D4 F4      its 9
        (3 / 5, [6 / 5, 3 / 2]),      # Eb: Eb4 G4     its 13
        (2 / 5, [6 / 5, 8 / 5]),      # Ab: Eb4 Ab4    its 3
        (8 / 15, [4 / 3, 8 / 5]),     # Db: F4 Ab4     its 7
        (1 / 2, [5 / 4, 3 / 2]),      # C
    ]
    t = 0.3
    for i, (r, mid) in enumerate(chords):
        last = i == len(chords) - 1
        m.note(C4 * r, t, 1.0, 0.42, wave=s2.BASS, attack=0.008, release=0.4, decay=0.8)
        m.struck([C4 * x for x in mid], t + 0.05, 0.34, wave=s2.KEYS, ring=2.0 if last else 1.1)
        ring = 2.4 if last else 1.3
        m.note(top, t + 0.08, ring, 0.20, wave=s2.HUM, attack=0.02, release=0.5, decay=ring * 0.9)
        t += 3.0 if last else 2.3
    m.save("l-the-elevator.wav")


if __name__ == "__main__":
    s2.OUT = sys.argv[1] if len(sys.argv) > 1 else "."
    sketch_l()
