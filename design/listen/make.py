#!/usr/bin/env python3
"""Short listening tests for design decisions that only ears can settle.

Writes 22,050 Hz mono WAV files next to this script. Pure Python, no packages.
Usage: python3 -I design/listen/make.py

  1-echoes-sour.wav      Volta as first drafted: today plus echoes kept 3 and 4 days, as the
                         arithmetic makes them (one interval 21.5 cents sour).
  2-echoes-sweet.wav     the same three voices retuned sweetly into today.
  3-comma-and-swell.wav  two tones a comma apart (about 3 wobbles a second), then two tones
                         2 cents apart (one slow swell every few seconds).
  4-seven-moods.wav      one phrase in the seven modes over a drone, brightest to darkest:
                         Lydian, Ionian, Mixolydian, Dorian, Aeolian, Phrygian, Locrian.
  5-piano-then-ring.wav  a major chord in equal temperament (like a piano), then tuned pure.
  6-home-then-longing.wav  a phrase that comes home, then the same phrase that almost does
                         (the deceptive cadence wasatch's lake rule uses).
  7-the-day-rises.wav    a motif that returns five times, each time a fifth higher.
  8-third-voice.wav      two voices lock on a pure third, and their common root fades in
                         beneath them (synthesised here; in a room it is the ear's own).

Lands, one tuning system each, each played the way it sounds best:
  9-land-just.wav           pure ratios: a chord sequence that rings, ending on a seventh tuned
                            to the seventh harmonic (the barbershop "ring").
  10-land-fifths.wav        Pythagorean: built from pure fifths; a chant-like line over an open
                            fifth drone.
  11-land-sweet-thirds.wav  quarter-comma meantone: sweet thirds in a near key, then the wolf
                            fifth (G sharp to E flat) on its own for two seconds.
  12-land-treaty.wav        equal temperament: twelve chords falling by fifths through every key
                            and arriving exactly home.
  13-land-well-tempered.wav Werckmeister III: the same four chords in C (gentle), then in F sharp
                            (tense): each key its own colour.
  14-land-shimmer.wav       paired bronze bars tuned a few hertz apart so they beat on purpose
                            (the way Balinese gamelan pairs instruments); five notes per octave.
  15-land-no-octave.wav     Bohlen-Pierce: thirteen steps of a 3:1 "tritave" instead of the
                            octave, with a clarinet-like tone; a world where the octave isn't home.
  16-rhythm-becomes-pitch.wav  two pulses in 3-against-2 speed up until they fuse into a fifth.
"""
import math
import os
import struct
import wave

RATE = 22050
HERE = os.path.dirname(os.path.abspath(__file__))


def table(partials, size=4096):
    """One cycle of a tone made of the given harmonic strengths, normalised."""
    t = [sum(a * math.sin(2 * math.pi * (k + 1) * i / size) for k, a in enumerate(partials)) for i in range(size)]
    peak = max(abs(x) for x in t)
    return [x / peak for x in t]


PAD = table([1.0, 0.45, 0.25, 0.14, 0.08, 0.05, 0.03])
PLUCK = table([1.0, 0.5, 0.3, 0.15, 0.08])
SINE = table([1.0])


class Mix:
    def __init__(self, seconds):
        self.buf = [0.0] * int(seconds * RATE)

    def note(self, freq, start, length, gain, wave=PAD, attack=0.12, release=0.4, decay=None):
        """Add one note. `decay` (seconds) makes it fade like a plucked string."""
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
        """A small room: four feedback combs and two all-passes (Schroeder)."""
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
        k = peak / top
        with wave.open(os.path.join(HERE, name), "wb") as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(RATE)
            f.writeframes(b"".join(struct.pack("<h", int(x * k * 32767)) for x in self.buf))
        print("wrote", name)


def et(semitones, base=220.0):
    return base * 2 ** (semitones / 12)


# 1, 2: today's note (220 Hz) with echoes kept 3 and 4 days, as drafted and then retuned
m = Mix(6.0)
m.chord([220 * 16 / 27, 220 * 64 / 81, 220.0], 0.2, 5.0, 0.6)
m.save("1-echoes-sour.wav")
m = Mix(6.0)
m.chord([220 * 3 / 5, 220 * 4 / 5, 220.0], 0.2, 5.0, 0.6)
m.save("2-echoes-sweet.wav")

# 3: a comma apart, then a schisma apart
comma = 2 ** (23.46 / 1200)
schisma = 2 ** (1.95 / 1200)
m = Mix(13.0)
m.chord([220.0, 220.0 * comma], 0.2, 5.0, 0.6)
m.chord([220.0, 220.0 * schisma], 7.0, 5.0, 0.6)
m.save("3-comma-and-swell.wav")

# 4: the seven modes, brightest to darkest, over a drone
modes = [
    ("lydian", [0, 2, 4, 6, 7, 9, 11, 12]),
    ("ionian", [0, 2, 4, 5, 7, 9, 11, 12]),
    ("mixolydian", [0, 2, 4, 5, 7, 9, 10, 12]),
    ("dorian", [0, 2, 3, 5, 7, 9, 10, 12]),
    ("aeolian", [0, 2, 3, 5, 7, 8, 10, 12]),
    ("phrygian", [0, 1, 3, 5, 7, 8, 10, 12]),
    ("locrian", [0, 1, 3, 5, 6, 8, 10, 12]),
]
phrase = [0, 1, 2, 3, 4, 5, 6, 7, 5, 4, 2, 0]
note_len, gap = 0.21, 0.7
span = len(phrase) * note_len + gap
m = Mix(len(modes) * span + 1.5)
for k, (_, steps) in enumerate(modes):
    t0 = 0.2 + k * span
    m.chord([110.0, 220.0], t0, len(phrase) * note_len, 0.35, attack=0.2)
    for i, degree in enumerate(phrase):
        m.note(et(steps[degree], 440.0), t0 + i * note_len, note_len, 0.5, wave=PLUCK, attack=0.005, release=0.2, decay=0.45)
m.save("4-seven-moods.wav")

# 5: the same chord as a piano tunes it, then pure
m = Mix(10.0)
m.chord([220.0, et(4), et(7)], 0.2, 4.0, 0.6)
m.chord([220.0, 275.0, 330.0], 5.2, 4.0, 0.6)
m.save("5-piano-then-ring.wav")

# 6: I IV V7 I (home), then I IV V7 vi (almost)
I_ = [et(-12), et(4), et(7), et(12)]
IV = [et(-7), et(5), et(9), et(12)]
V7 = [et(-5), et(2), et(5), et(11)]   # E, B, D, G sharp
vi = [et(-3), et(4), et(9), et(12)]
m = Mix(13.0)
for k, ch in enumerate([I_, IV, V7, I_]):
    m.chord(ch, 0.2 + k * 1.2, 1.1 if k < 3 else 2.0, 0.55)
for k, ch in enumerate([I_, IV, V7, vi]):
    m.chord(ch, 6.6 + k * 1.2, 1.1 if k < 3 else 2.0, 0.55)
m.save("6-home-then-longing.wav")

# 7: a motif that comes back each "day" a fifth higher (folded so it stays in range)
m = Mix(9.0)
shift = 0
for day in range(5):
    t0 = 0.2 + day * 1.6
    for i, s in enumerate([0, 4, 7, 12]):
        m.note(et(s + shift), t0 + i * 0.25, 0.3, 0.5, wave=PLUCK, attack=0.005, release=0.25, decay=0.5)
    m.chord([et(shift - 12), et(shift - 5)], t0, 1.3, 0.3, attack=0.15)
    shift += 7
    if shift >= 12:
        shift -= 12
m.save("7-the-day-rises.wav")

# 8: two voices on a pure major third; their common root fades in beneath them
m = Mix(9.0)
m.note(440.0, 0.2, 7.5, 0.4)
m.note(550.0, 1.2, 6.5, 0.4)
m.note(110.0, 3.4, 4.3, 0.35, wave=SINE, attack=1.6, release=0.8)
m.save("8-third-voice.wav")


# ---------------------------------------------------------------- lands: one tuning each

def ratio_cents(c):
    return 2 ** (c / 1200)


class Bars(Mix):
    def bar(self, freq, start, gain, partials=((1.0, 1.0, 1.6), (2.76, 0.35, 0.6), (5.40, 0.12, 0.25))):
        """A struck metal bar: inharmonic partials, each fading at its own rate."""
        first = int(start * RATE)
        n = int(3.0 * RATE)
        for ratio, amp, decay in partials:
            w = 2 * math.pi * freq * ratio / RATE
            for i in range(n):
                j = first + i
                if j >= len(self.buf):
                    break
                attack = min(1.0, i / 40.0)
                self.buf[j] += gain * amp * attack * math.exp(-i / (decay * RATE)) * math.sin(w * i)


# 9: just intonation, home: I IV I V7(7/4) I on A
A = 220.0
m = Mix(9.0)
just = [
    [A / 2, A, A * 5 / 4, A * 3 / 2],
    [A * 2 / 3, A * 4 / 3, A * 5 / 3, A * 2],
    [A / 2, A, A * 5 / 4, A * 3 / 2],
    [A * 3 / 4, A * 3 / 2 * 5 / 4, A * 3 / 2 * 3 / 2, A * 3 / 2 * 7 / 4],
    [A / 2, A, A * 5 / 4, A * 3 / 2],
]
for k, ch in enumerate(just):
    m.chord(ch, 0.2 + k * 1.5, 1.4 if k < 4 else 2.4, 0.6)
m.save("9-land-just.wav")

# 10: Pythagorean, a chant over an open fifth (A Dorian, pure fifths throughout)
pyth = {0: 1, 1: 9 / 8, 2: 32 / 27, 3: 4 / 3, 4: 3 / 2, 5: 27 / 16, 6: 16 / 9, 7: 2}
line = [0, 2, 3, 4, 3, 2, 1, 0, 4, 6, 4, 3, 2, 3, 1, 0]
m = Mix(len(line) * 0.42 + 2.0)
m.chord([110.0, 165.0], 0.1, len(line) * 0.42 + 0.6, 0.45, attack=0.4)
for i, d in enumerate(line):
    m.note(440.0 * pyth[d], 0.2 + i * 0.42, 0.4, 0.42, attack=0.06, release=0.25)
m.save("10-land-fifths.wav")

# 11: quarter-comma meantone: C F G C with sweet thirds, then the wolf (G sharp to E flat)
f5 = 5 ** 0.25
def mt(k, octave=0):
    """Pitch k fifths from C in quarter-comma meantone, folded into the octave above C3."""
    r = f5 ** k
    while r >= 2:
        r /= 2
    while r < 1:
        r *= 2
    return 130.81 * r * 2 ** octave
C, G, D, E, F, A_, B_ = 0, 1, 2, 4, -1, 3, 5
m = Mix(11.0)
prog = [[mt(C, -1), mt(C), mt(E), mt(G)], [mt(F, -1), mt(C), mt(F), mt(A_)],
        [mt(G, -1), mt(D), mt(G), mt(B_)], [mt(C, -1), mt(C), mt(E), mt(G)]]
for k, ch in enumerate(prog):
    m.chord(ch, 0.2 + k * 1.4, 1.3 if k < 3 else 2.0, 0.6)
m.chord([mt(8), mt(-3, 1)], 7.6, 2.0, 0.55)   # G sharp and the E flat above it: the wolf
m.save("11-land-sweet-thirds.wav")

# 12: equal temperament: twelve major chords falling by fifths, every key, home exactly
def voice_lead(prev, tones):
    """Place each chord tone in the octave nearest the previous voicing."""
    out = []
    for t in tones:
        best = None
        for octave in range(-2, 3):
            f = t * 2 ** octave
            if 180 <= f <= 520:
                d = min(abs(math.log2(f / p)) for p in prev) if prev else abs(math.log2(f / 300))
                if best is None or d < best[0]:
                    best = (d, f)
        out.append(best[1])
    return sorted(out)
m = Mix(12 * 0.75 + 2.5)
root = 261.63
prev = []
for k in range(13):
    r = root * 2 ** (-7 * k / 12)
    while r < 130:
        r *= 2
    tones = [r, r * 2 ** (4 / 12), r * 2 ** (7 / 12)]
    prev = voice_lead(prev, tones)
    bass = r
    while bass > 130:
        bass /= 2
    m.chord(prev + [bass], 0.2 + k * 0.75, 0.7 if k < 12 else 1.8, 0.6, attack=0.05)
m.save("12-land-treaty.wav")

# 13: Werckmeister III: I IV V I in C, then in F sharp
werck = [0, 90.225, 192.180, 294.135, 390.225, 498.045, 588.270, 696.090, 792.180, 888.270, 996.090, 1092.180]
def wk(pc, octave=0):
    return 130.81 * ratio_cents(werck[pc % 12]) * 2 ** (octave + pc // 12)
def triad(root_pc):
    return [wk(root_pc, -1), wk(root_pc), wk(root_pc + 4), wk(root_pc + 7)]
m = Mix(13.0)
for k, r in enumerate([0, 5, 7, 0]):
    m.chord(triad(r), 0.2 + k * 1.3, 1.2 if k < 3 else 1.8, 0.6)
for k, r in enumerate([6, 11, 13, 6]):
    m.chord(triad(r), 6.8 + k * 1.3, 1.2 if k < 3 else 1.8, 0.6)
m.save("13-land-well-tempered.wav")

# 14: shimmering pairs: each note struck on two bars a few hertz apart (five notes per octave)
slendro = [0, 240, 480, 720, 960, 1200]
pattern = [0, 2, 1, 3, 2, 4, 3, 1, 2, 0, 1, 3, 4, 5, 4, 2]
m = Bars(len(pattern) * 0.32 + 3.0)
for i, d in enumerate(pattern):
    f = 392.0 * ratio_cents(slendro[d])
    t0 = 0.2 + i * 0.32
    m.bar(f, t0, 0.32)
    m.bar(f + 5.0, t0, 0.32)          # the higher partner: about five beats a second
    if i % 4 == 0:
        m.bar(f / 2, t0, 0.22)
        m.bar(f / 2 + 5.0, t0, 0.22)
m.save("14-land-shimmer.wav")

# 15: Bohlen-Pierce: thirteen equal steps of 3:1, odd harmonics only (clarinet-like)
REED = table([1.0, 0.0, 0.45, 0.0, 0.25, 0.0, 0.12, 0.0, 0.06])
step = 3 ** (1 / 13)
lam = [0, 2, 3, 4, 6, 7, 9, 10, 13, 10, 9, 7, 6, 4, 3, 0]
m = Mix(len(lam) * 0.36 + 2.5)
base = 196.0
m.chord([base / 2, base / 2 * 5 / 3, base / 2 * 7 / 3], 0.1, len(lam) * 0.36 + 0.8, 0.4, wave=REED, attack=0.4)
for i, d in enumerate(lam):
    m.note(base * step ** d, 0.2 + i * 0.36, 0.33, 0.42, wave=REED, attack=0.04, release=0.2)
m.save("15-land-no-octave.wav")

# 16: two pulse trains in 3-against-2 accelerate until they become a fifth
seconds = 17.0
m = Mix(seconds)
click = [math.sin(2 * math.pi * 1400 * i / RATE) * math.exp(-i / (0.0025 * RATE)) for i in range(int(0.012 * RATE))]
ramp = 13.0
for rate0, gain in [(2.0, 0.5), (3.0, 0.5)]:
    phase = 0.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        rate = rate0 * (110.0 ** min(t / ramp, 1.0))
        phase += rate / RATE
        if phase >= 1.0:
            phase -= 1.0
            for k, c in enumerate(click):
                if i + k < len(m.buf):
                    m.buf[i + k] += gain * c
m.save("16-rhythm-becomes-pitch.wav")
