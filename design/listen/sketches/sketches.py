#!/usr/bin/env python3
"""Three listening sketches for the brainstorm of 2026-11-25. Kept in design/listen/sketches/ beside the clips it makes.

Same voices and room as design/listen/make.py (22,050 Hz mono, pure Python), so they compare
fairly with the clips Morgan has already judged.

  a-home-a-comma-later.wav   the first evening's call, answered; the whole shore walked by pure
                             fifths; the same call a comma warm, and home barely answers (law 1:
                             8.7% at 23.46 cents); then the call half a comma down, a second voice
                             meets it there, and the garden half lights (54%).
  b-the-same-day-underneath.wav  a short day over its home; the same notes sung back with home a
                             pure minor third lower (the relative minor); then home walks back up
                             by fifths to morning.
  c-the-pump.wav             four chords, each pure, each keeping a note of the last: C, A minor,
                             D minor, G. Four laps. A bell on the first C sounds before each lap.
                             Then the same laps on the treaty's notes, where nothing moves.

Usage: python3 -I sketches.py OUTDIR
"""
import math
import os
import struct
import sys
import wave

RATE = 22050
OUT = sys.argv[1] if len(sys.argv) > 1 else "."


def table(partials, size=4096):
    t = [sum(a * math.sin(2 * math.pi * (k + 1) * i / size) for k, a in enumerate(partials)) for i in range(size)]
    peak = max(abs(x) for x in t)
    return [x / peak for x in t]


PAD = table([1.0, 0.45, 0.25, 0.14, 0.08, 0.05, 0.03])
PLUCK = table([1.0, 0.5, 0.3, 0.15, 0.08])
SOFT = table([1.0, 0.22, 0.07])
BELL = table([1.0, 0.0, 0.32, 0.0, 0.1])


class Mix:
    def __init__(self, seconds):
        self.buf = [0.0] * int(seconds * RATE)

    def note(self, freq, start, length, gain, wave=PAD, attack=0.12, release=0.4, decay=None):
        size = len(wave)
        step = freq * size / RATE
        phase = 0.0
        first = int(start * RATE)
        total = int((length + release) * RATE)
        a = max(1, int(attack * RATE))
        held = int(length * RATE)
        r = max(1, int(release * RATE))
        for i in range(total):
            j = first + i
            if j >= len(self.buf):
                break
            env = min(1.0, i / a)
            if i > held:
                env *= max(0.0, 1.0 - (i - held) / r)
            if decay:
                env *= math.exp(-i / (decay * RATE))
            self.buf[j] += gain * env * wave[int(phase) % size]
            phase += step

    def chord(self, freqs, start, length, gain, **kw):
        for f in freqs:
            self.note(f, start, length, gain / len(freqs) ** 0.5, **kw)

    def reverb(self, wet=0.22):
        dry = self.buf
        out = [0.0] * len(dry)
        for delay_ms, fb in [(29.7, 0.78), (37.1, 0.76), (41.1, 0.74), (43.7, 0.72)]:
            d = int(delay_ms * RATE / 1000)
            line = [0.0] * len(dry)
            for i in range(len(dry)):
                line[i] = dry[i] + (fb * line[i - d] if i >= d else 0.0)
                out[i] += line[i] * 0.25
        for delay_ms, g in [(5.0, 0.7), (1.7, 0.7)]:
            d = int(delay_ms * RATE / 1000)
            y = [0.0] * len(out)
            for i in range(len(out)):
                xd = out[i - d] if i >= d else 0.0
                yd = y[i - d] if i >= d else 0.0
                y[i] = -g * out[i] + xd + g * yd
            out = y
        self.buf = [x + wet * w for x, w in zip(dry, out)]

    def save(self, name, peak=0.45):
        self.reverb()
        top = max(1e-9, max(abs(x) for x in self.buf))
        last = max(i for i, x in enumerate(self.buf) if abs(x) > top * 2e-3)
        self.buf = self.buf[: min(len(self.buf), last + int(0.6 * RATE))]
        k = peak / top
        path = os.path.join(OUT, name)
        with wave.open(path, "wb") as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(RATE)
            f.writeframes(b"".join(struct.pack("<h", int(x * k * 32767)) for x in self.buf))
        print("wrote", path, "%.1f s" % (len(self.buf) / RATE))


def cents(c):
    return 2 ** (c / 1200)


def voice_lead(prev, tones, lo=180, hi=520):
    out = []
    for t in tones:
        best = None
        for octave in range(-3, 4):
            f = t * 2 ** octave
            if lo <= f <= hi:
                d = min(abs(math.log2(f / p)) for p in prev) if prev else abs(math.log2(f / 300))
                if best is None or d < best[0]:
                    best = (d, f)
        out.append(best[1])
    return sorted(out)


def low(f, top=160.0):
    while f > top:
        f /= 2
    while f < top / 2:
        f *= 2
    return f


C4 = 261.6256
COMMA = (3 / 2) ** 12 / 2 ** 7            # 23.460 cents
SYNTONIC = 81 / 80                        # 21.506 cents
WIDTH = 15.0                              # law 1's width, in cents (spec/laws.md, "to tune")


def shares(c):
    """How much two overtones `c` cents apart share (spec/laws.md, law 1)."""
    return math.exp(-(c / WIDTH) ** 2)


# ---------------------------------------------------------------------------------------------
# a: home, a comma later
# ---------------------------------------------------------------------------------------------
def call(m, f, t, gain=0.5):
    m.note(f, t, 0.5, gain, wave=SOFT, attack=0.05, release=0.3)
    m.note(f, t, 0.5, gain * 0.25, wave=PAD, attack=0.07, release=0.3)


# the garden's things, each on its own pure note of C, each heard late by how far off it stands
GARDEN = [(0.42, 2.0, 0.36), (0.60, 1.5, 0.34), (0.83, 2.5, 0.30), (1.02, 3.0, 0.26),
          (1.30, 2.0, 0.22), (1.55, 1.5, 0.20), (1.86, 2.5, 0.15)]


def answers(m, t, how_much):
    for late, ratio, gain in GARDEN:
        m.note(C4 * ratio, t + late, 0.5, gain * how_much, wave=BELL, attack=0.006, release=0.5, decay=0.85)


def sketch_a():
    m = Mix(41.0)
    # the first evening: you call, and home answers
    t = 0.3
    for _ in range(2):
        call(m, C4, t)
        answers(m, t, shares(0.0))
        t += 3.4
    # the whole shore, true at every step: twelve pure fifths
    t += 0.4
    step = 0.46
    prev = []
    root = C4 / 2
    for _ in range(12):
        root *= 3 / 2
        if root > 190:
            root /= 2
        prev = voice_lead(prev, [root, root * 5 / 4, root * 3 / 2])
        m.chord(prev + [root], t, step - 0.08, 0.42, attack=0.04, release=0.16)
        m.note(max(prev) * 2, t, 0.15, 0.13, wave=PLUCK, attack=0.004, release=0.2, decay=0.25)
        t += step
    # home again, and the same call: a comma warm
    t += 1.1
    warm = C4 * COMMA
    for _ in range(2):
        call(m, warm, t)
        answers(m, t, shares(1200 * math.log2(COMMA)))
        t += 3.4
    # half a comma down; a second voice meets it there, a pure fifth above, and the note under
    # them both comes in; the garden answers each of them at 54%
    t += 0.5
    mid = C4 * math.sqrt(COMMA)
    half = 1200 * math.log2(COMMA) / 2
    call(m, mid, t)
    answers(m, t, shares(half))
    t += 3.2
    m.note(mid, t, 6.0, 0.36, wave=SOFT, attack=0.25, release=1.6)
    m.note(mid * 3 / 2, t + 0.9, 5.1, 0.30, wave=PAD, attack=0.35, release=1.6)
    for r, g in ((0.5, 0.30), (1.0, 0.0), (1.25, 0.12)):
        if g:
            m.note(mid * r, t + 2.4, 3.6, g, wave=SOFT, attack=1.2, release=1.8)
    answers(m, t + 2.4, shares(half))
    answers(m, t + 4.6, shares(half) * 0.8)
    m.save("a-home-a-comma-later.wav")
    return {"comma_cents": 1200 * math.log2(COMMA), "answer_at_a_comma": shares(1200 * math.log2(COMMA)),
            "answer_at_half": shares(half)}


# ---------------------------------------------------------------------------------------------
# b: the same day, underneath
# ---------------------------------------------------------------------------------------------
D2, D2LOW, D3, D4, D5, D6, D7 = 9 / 8, 10 / 9, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 15 / 8


def sketch_b():
    home = 220.0
    # the day: clip 28's first telling, over home and its fifth
    day = [(0.0, 1), (0.4, D2), (0.8, D3), (1.2, D5), (1.8, D6), (2.2, D5), (2.6, D3), (3.0, D2), (3.4, D3), (4.0, 1)]
    # at night home is a pure minor third lower, and the second degree gives a comma to stay
    # pure with it (10/9, a pure fourth over the night's home, where 9/8 would be 27/20)
    night = [(at, D2LOW if r == D2 else r) for at, r in day]
    m = Mix(27.0)
    t = 0.3
    m.chord([home / 2, home * D5 / 2], t, 4.8, 0.24, attack=0.3, release=0.8)
    for at, r in day:
        m.note(home * r, t + at, 0.34, 0.42, wave=PLUCK, attack=0.005, release=0.3, decay=0.7)
    # night: the same notes, a little slower and softer, over the home underneath
    t += 6.4
    slow = 1.22
    under = home * D6 / 2                 # a pure minor third under home
    m.chord([under / 2, under * 3 / 4, under], t, 4.8 * slow + 0.6, 0.30, attack=0.5, release=1.2)
    for at, r in night:
        m.note(home * r, t + at * slow, 0.36, 0.34, wave=SOFT, attack=0.04, release=0.3, decay=0.75)
        m.note(home * r / 2, t + at * slow, 0.36, 0.10, wave=SOFT, attack=0.06, release=0.3, decay=0.75)
    # toward morning home walks back up by falling fifths: the second, the fifth, home
    t += 4.8 * slow + 1.2
    walk = [([home * D2LOW / 2, home * D4 / 2, home * D6 / 2], home * D2LOW / 4, 1.5),
            ([home * D5 / 2, home * D7 / 2, home * D2], home * D5 / 4, 1.5),
            ([home / 2, home * D3 / 2, home * D5 / 2, home], home / 4, 3.6)]
    prev = []
    tail = [D4, D3, D2, D3, 1]
    k = 0
    for tones, bass, length in walk:
        prev = voice_lead(prev, tones, 150, 460)
        m.chord(prev + [bass * 2], t, length - 0.1, 0.36, attack=0.12, release=0.7)
        if k < 2:
            m.note(home * tail[k * 2], t + 0.1, 0.34, 0.30, wave=SOFT, attack=0.03, release=0.4, decay=0.9)
            m.note(home * tail[k * 2 + 1], t + 0.85, 0.34, 0.30, wave=SOFT, attack=0.03, release=0.4, decay=0.9)
        else:
            m.note(home * tail[4], t + 0.1, 1.2, 0.38, wave=PLUCK, attack=0.005, release=0.8, decay=1.4)
        t += length
        k += 1
    m.save("b-the-same-day-underneath.wav")
    return {"night_home_under_day": 1200 * math.log2(D6 / 2 * 2 / 1) - 1200, "second_gives": 1200 * math.log2(D2 / D2LOW)}


# ---------------------------------------------------------------------------------------------
# c: the pump
# ---------------------------------------------------------------------------------------------
def lap_pure(c):
    """One lap from a C at `c`: each chord pure, each keeping a note of the one before.
    Returns the four chords and the C the lap comes home to."""
    e, g = c * 5 / 4, c * 3 / 2
    a = e * 2 / 3                       # A minor keeps C and E
    d = a * 2 / 3                       # D minor keeps A
    f = d * 6 / 5
    g2 = d * 4 / 3                      # G keeps D
    b = g2 * 5 / 4
    c2 = g2 * 4 / 3                     # C keeps G
    return [[c, e, g], [a, c, e], [d, f, a], [g2, b, d]], c2


def lap_treaty(c):
    s = lambda n: c * 2 ** (n / 12)
    return [[s(0), s(4), s(7)], [s(-3), s(0), s(4)], [s(-10), s(-7), s(-3)], [s(-5), s(-1), s(2)]], c


def sketch_c():
    each = 0.72
    gap = 0.62
    laps_pure, laps_treaty = 4, 2
    m = Mix(0.4 + (laps_pure + laps_treaty) * (4 * each + gap + 0.38) + 2 * 7.2 + 5.5)
    first = 220.0
    report = []

    def run(make_lap, laps, t):
        c = first
        prev = []
        for _ in range(laps):
            # the bell on the first C, alone, before the lap
            m.note(first * 2, t, 0.12, 0.34, wave=BELL, attack=0.004, release=0.2, decay=0.22)
            t += gap
            chords, nxt = make_lap(c)
            for n, tones in enumerate(chords):
                prev = voice_lead(prev, tones)
                m.chord(prev + [low(tones[0])], t, each - 0.07, 0.56, attack=0.05)
                if n == 0:   # this lap's home, in the bell's own voice, so the two can be told apart
                    m.note(low(tones[0], 640.0), t, 0.12, 0.30, wave=BELL, attack=0.004, release=0.2, decay=0.22)
                else:
                    m.note(low(tones[0], 640.0), t, 0.2, 0.2, wave=PLUCK, attack=0.004, release=0.2, decay=0.25)
                t += each
            report.append(1200 * math.log2(nxt / first))
            c = nxt
            t += 0.38          # a breath, so the next bell is heard alone
        # home, where the laps left it; then the bell and that home, one after the other
        chord = [c, c * 5 / 4, c * 3 / 2] if make_lap is lap_pure else lap_treaty(c)[0][0]
        prev2 = voice_lead(prev, chord)
        m.chord(prev2 + [low(chord[0])], t, 1.7, 0.56, attack=0.05, release=0.7)
        t += 3.3
        for _ in range(2):
            m.note(first * 2, t, 0.22, 0.36, wave=BELL, attack=0.004, release=0.22, decay=0.26)
            m.note(c * 2, t + 0.85, 0.22, 0.36, wave=BELL, attack=0.004, release=0.22, decay=0.26)
            t += 1.9
        return t, c

    t, end_pure = run(lap_pure, laps_pure, 0.4)
    t, end_treaty = run(lap_treaty, laps_treaty, t + 1.2)
    m.save("c-the-pump.wav")
    return {"after_each_pure_lap_cents": [round(x, 3) for x in report[:laps_pure]],
            "pure_home_ends_cents_from_bell": round(1200 * math.log2(end_pure / first), 3),
            "treaty_home_ends_cents_from_bell": round(1200 * math.log2(end_treaty / first), 3)}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for f in (sketch_a, sketch_b, sketch_c):
        print(f.__name__, f())
