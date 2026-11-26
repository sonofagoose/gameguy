#!/usr/bin/env python3
"""Two more listening sketches for the brainstorm of 2026-11-25 (part three: trouble).
Kept in design/listen/sketches/ beside the clips it makes. Same voices as sketches2.py; nothing is held for long.

  h-a-floor-under-the-floor.wav   a steady low G, dead straight, with a figure over it that
                             never changes: it sounds like home. Then one note is added that the
                             figure never had (the seventh overtone of that G), and the whole
                             thing leans. Then a C comes in underneath, and everything falls onto
                             it. Last, the first figure again, unchanged, over the C.
  i-a-fight-becomes-a-song.wav    clip 22's stumble (three against five). Strikes on your own
                             beat, with home in the wrong place: nothing meets. Then the note
                             under both strands comes in on the one. Four strikes on the one, each
                             the next note of that home's chord. Two bars of swell. Then the
                             landing, and the garden answers.

Usage: python3 -I sketches3.py OUTDIR
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sketches2 as s2                                   # noqa: E402

Mix, HUM, KEYS, DARK, BASS, BELL, SINE, RATE, C4, cents = (s2.Mix, s2.HUM, s2.KEYS, s2.DARK, s2.BASS, s2.BELL,
                                                           s2.SINE, s2.RATE, s2.C4, s2.cents)
PLUCK = s2.table([1.0, 0.5, 0.3, 0.15, 0.08])           # design/listen/make.py's pluck, as in clip 22


def fork(m, f, t, gain, timed=False):
    """Hum's tuning fork: nearly a pure tone with one high clang that dies at once
    (spec/laws.md: overtones 1 and 6.27). A timed strike rings with its octave as well."""
    m.note(f, t, 0.5, gain, wave=SINE, attack=0.004, release=0.4, decay=0.55)
    m.note(f * 6.27, t, 0.05, gain * 0.16, wave=SINE, attack=0.002, release=0.05, decay=0.04)
    if timed:
        m.note(f * 2, t, 0.5, gain * 0.5, wave=SINE, attack=0.004, release=0.4, decay=0.6)
        m.note(f * 12.54, t, 0.05, gain * 0.07, wave=SINE, attack=0.002, release=0.05, decay=0.04)


# ---------------------------------------------------------------------------------------------
# h: a floor under the floor
# ---------------------------------------------------------------------------------------------
def sketch_h():
    c = C4 / 2                      # 130.8 Hz: the note that will come in underneath
    g = c * 3 / 2                   # 196.2 Hz: the ground that everything starts on
    b, d = g * 5 / 4, g * 3 / 2
    f7 = g * 7 / 4                  # the seventh overtone of that ground (343.4 Hz)
    beat = 60.0 / 88
    bar = 4 * beat
    m = Mix(60)

    def figure(t0, gain=0.34, wave=KEYS):
        # two bars over G that go nowhere and come back: G B D B | G D B G
        fig = [(0, g * 2), (1, b * 2), (2, d * 2), (3, b * 2), (4, g * 2), (5, d * 2), (6, b * 2), (7, g * 2)]
        for k, f in fig:
            m.note(f, t0 + k * beat, 0.3, gain, wave=wave, attack=0.004, release=0.3, decay=0.6)

    def ground(t0, f, bars, gain=0.44, straight=True):
        for k in range(bars * 4):
            # dead straight: every beat the same, no swing, no accent
            m.note(f, t0 + k * beat, 0.25, gain * (1.0 if straight or k % 4 == 0 else 0.7), wave=BASS,
                   attack=0.006, release=0.2, decay=0.34)

    t = 0.3
    # 1. the same two bars twice: this is home, as far as anyone can tell
    for _ in range(2):
        ground(t, g / 2, 2)
        figure(t)
        t += 2 * bar
    # 2. the same again, with one new note sung over it: the ground's own seventh overtone
    ground(t, g / 2, 2)
    figure(t)
    m.note(f7, t + 2 * beat, 5.2 * beat, 0.30, wave=HUM, attack=0.25, release=0.5, decay=2.2)
    t += 2 * bar
    ground(t, g / 2, 1)
    for k, f in [(0, g * 2), (1, b * 2), (2, d * 2), (3, f7 * 2)]:
        m.note(f, t + k * beat, 0.3, 0.34, wave=KEYS, attack=0.004, release=0.3, decay=0.6)
    m.note(f7, t, 3.6 * beat, 0.30, wave=HUM, attack=0.2, release=0.4, decay=1.8)
    t += bar
    # 3. the note underneath: C. Everything falls onto it. Hum's own voice is that C.
    e = c * 5 / 2                   # the E the seventh falls to (327.0 Hz)
    m.note(c, t, 2.2 * bar, 0.42, wave=HUM, attack=0.05, release=1.2, decay=3.0)
    m.note(c / 2, t, 1.8, 0.46, wave=BASS, attack=0.008, release=0.8, decay=1.6)
    m.struck([c * 2, e, g * 2, c * 4], t, 0.44, wave=KEYS, ring=1.9)
    for late, f, gn in [(0.42, c * 4, 0.20), (0.66, g * 4, 0.16), (0.9, e * 2, 0.15), (1.2, c * 8, 0.10)]:
        m.note(f, t + late, 0.4, gn, wave=BELL, attack=0.006, release=0.5, decay=0.8)
    t += 2 * bar + 0.4
    # 4. the first figure again, not a note of it changed, with the C under it
    for rep in range(2):
        for k in range(8):
            m.note(c / 2 if k % 4 == 0 else c, t + k * beat, 0.25, 0.40 if k % 4 == 0 else 0.26, wave=BASS,
                   attack=0.006, release=0.25, decay=0.5 if k % 4 == 0 else 0.3)
        figure(t)
        t += 2 * bar
    m.note(c / 2, t, 1.8, 0.46, wave=BASS, attack=0.008, release=0.8, decay=1.6)
    m.struck([c * 2, e, g * 2], t, 0.40, wave=KEYS, ring=1.8)
    m.save("h-a-floor-under-the-floor.wav")
    return {"the seventh over the first ground": round(cents(7 / 4), 3),
            "it falls to the third of the new one by": round(cents(f7 / e), 3),
            "the first ground is the new one's": round(cents(g / c), 3)}


# ---------------------------------------------------------------------------------------------
# i: a fight becomes a song
# ---------------------------------------------------------------------------------------------
def sketch_i():
    bar = 1.6                        # clip 22's bar
    root = 87.31                     # F: its 3rd overtone is C, its 5th is A (clip 22)
    cnote = root * 3                 # the C strand, and the garden's home
    m = Mix(50)
    t = 0.2

    def strands(t0, gain=1.0, together=False):
        if together:
            for f, gn in ((root * 3, 0.34), (root * 5, 0.30)):
                m.note(f, t0, 0.14, gn * gain, wave=PLUCK, attack=0.004, release=0.2, decay=0.22)
            return
        for k in range(3):
            m.note(root * 3, t0 + k * bar / 3, 0.12, 0.34 * gain, wave=PLUCK, attack=0.004, release=0.15, decay=0.16)
        for k in range(5):
            m.note(root * 5, t0 + k * bar / 5, 0.1, 0.30 * gain, wave=PLUCK, attack=0.004, release=0.12, decay=0.12)

    # 1. the stumble alone, as in clip 22
    for _ in range(3):
        strands(t)
        t += bar
    # 2. you strike on your own four, with home still on the garden's note: C, E, G, C.
    #    Only the first of each bar meets anything.
    for _ in range(2):
        strands(t)
        for k, r in enumerate((1, 5 / 4, 3 / 2, 2)):
            fork(m, cnote * r / 1.0, t + k * bar / 4, 0.26)
        t += bar
    # 3. home goes under both strands: the F comes in on the one, and it is a groove
    for b in range(2):
        strands(t)
        m.note(root * 2, t, 0.5, 0.50, wave=BASS, attack=0.008, release=0.5, decay=0.5)
        m.note(root, t, 0.5, 0.30, wave=BASS, attack=0.008, release=0.5, decay=0.5)
        t += bar
    # 4. four strikes, each on the one, each the next note of that home's chord: F, A, C, F
    for r in (4, 5, 6, 8):
        strands(t)
        m.note(root * 2, t, 0.5, 0.50, wave=BASS, attack=0.008, release=0.5, decay=0.5)
        m.note(root, t, 0.5, 0.30, wave=BASS, attack=0.008, release=0.5, decay=0.5)
        fork(m, root * r, t, 0.34, timed=True)
        t += bar
    # 5. the swell: two bars, a voice more each bar; the strands grow quiet and lean
    swell = [[root * 4, root * 6], [root * 4, root * 5, root * 6, root * 9]]
    for b in range(2):
        strands(t, gain=0.7 - 0.25 * b)
        m.note(root * 2, t, 0.5, 0.44, wave=BASS, attack=0.008, release=0.5, decay=0.5)
        for f in swell[b]:
            m.note(f, t, bar * 0.92, 0.17 + 0.05 * b, wave=HUM, attack=0.5, release=0.25, decay=2.4)
        t += bar
    # 6. let go on the one: home falls back to the garden's note (the amen), and the garden answers
    m.note(cnote / 2, t, 2.0, 0.50, wave=BASS, attack=0.008, release=0.9, decay=1.6)
    m.note(cnote / 4, t, 2.0, 0.26, wave=BASS, attack=0.008, release=0.9, decay=1.6)
    m.struck([cnote, cnote * 5 / 4, cnote * 3 / 2, cnote * 2], t, 0.46, wave=KEYS, ring=2.0)
    fork(m, cnote * 2, t, 0.30, timed=True)
    strands(t, together=True)
    for late, r, gn in [(0.40, 2.0, 0.24), (0.58, 3.0, 0.20), (0.80, 2.5, 0.18), (1.02, 4.0, 0.14),
                        (1.30, 3.0, 0.11), (1.62, 5.0, 0.08)]:
        m.note(cnote * r, t + late, 0.45, gn, wave=BELL, attack=0.006, release=0.5, decay=0.85)
    m.save("i-a-fight-becomes-a-song.wav")
    return {"the strands": [round(root * 3, 2), round(root * 5, 2)], "the note under both": round(root, 2),
            "the landing is": "the chord on %.2f Hz" % cnote}


if __name__ == "__main__":
    os.makedirs(s2.OUT, exist_ok=True)
    which = sys.argv[2] if len(sys.argv) > 2 else "hi"
    for name, f in (("h", sketch_h), ("i", sketch_i)):
        if name in which:
            print(f.__name__, f())
