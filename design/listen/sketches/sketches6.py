#!/usr/bin/env python3
"""One listening sketch for part three of the design (design/the-wormhole.md, "Melody is the main
character"). Kept in design/listen/sketches/ beside the clips it makes. Everything is struck or sung briefly and dies away.

  m-the-third-is-yours.wav   the ground plays only a root and its fifth, and the one in front
                             decides what the chord is. Five phrases:
                             1. C and G under, the fork adds E: major.
                             2. the same C and G, the fork adds E flat: minor.
                             3. A and E under, and Hum's own held C over them: his note is the third,
                                and the place is minor because he is in it.
                             4. F and C under, Hum's C is the fifth; the fork adds A.
                             5. home again, with its E.

Usage: python3 -I sketches6.py OUTDIR
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sketches2 as s2  # noqa: E402

C4 = s2.C4


def ground(m, root, t, again=1.3):
    """A root and its fifth, with the root again on top: no third anywhere."""
    for at, g in ((t, 0.40), (t + again, 0.28)):
        m.note(C4 * root, at, 0.9, g, wave=s2.BASS, attack=0.008, release=0.4, decay=0.7)
        m.struck([C4 * root * 3 / 2, C4 * root * 2], at + 0.04, g * 0.8, wave=s2.KEYS, ring=0.9)


def fork(m, ratio, t, gain=0.22, ring=1.4):
    m.note(C4 * ratio, t, ring, gain, wave=s2.BELL, attack=0.004, release=0.5, decay=ring * 0.7)


def hum(m, t, length=2.2, gain=0.18):
    m.note(C4 * 2, t, length, gain, wave=s2.HUM, attack=0.05, release=0.5, decay=length * 1.4)


def sketch_m():
    m = s2.Mix(40)
    t = 0.3
    ground(m, 1 / 2, t); fork(m, 5 / 2, t + 0.65); fork(m, 5 / 2, t + 1.95, gain=0.16)          # C G + E
    t += 3.2
    ground(m, 1 / 2, t); fork(m, 12 / 5, t + 0.65); fork(m, 12 / 5, t + 1.95, gain=0.16)        # C G + E flat
    t += 3.4
    ground(m, 5 / 12, t); hum(m, t + 0.5)                                                       # A E + Hum's C
    t += 3.4
    ground(m, 1 / 3, t); hum(m, t + 0.3, length=2.4); fork(m, 5 / 3, t + 1.0); fork(m, 5 / 3, t + 1.95, gain=0.16)   # F C + C, then A
    t += 3.6
    ground(m, 1 / 2, t, again=1.5); fork(m, 5 / 2, t + 0.65, ring=2.2)                          # home, with its E
    m.save("m-the-third-is-yours.wav")


if __name__ == "__main__":
    s2.OUT = sys.argv[1] if len(sys.argv) > 1 else "."
    sketch_m()
