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

The wheel (../the-wheel.md, ../experience-fixes.md, ../the-way-home.md):
  17-two-ways-home.wav        a full close, then an amen.
  18-home-the-long-way.wav    walks home of two, three, four and five chords, then the whole key.
  19-it-turns.wav             a close that lands on its neighbour; then on a borrowed chord.
  20-borrowing-home.wav       a phrase in D that borrows the chord on C for one bar and returns.
  21-the-slide.wav            home by a fifth, then home by a half step from the far side.
  22-stand-where-they-meet.wav  three against five, then the note under both comes in on the one.
  23-rising-doubled.wav       an echo's tune at four dusks: three warnings, then the howl.
  24-the-comma-in-time.wav    a comma at middle C at 107 beats a minute: the wobble is eighth
                              notes; a third voice between the two halves it into a heartbeat.
  25-twelve-mornings.wav      twelve steps up by pure fifths in one breath, and the arrival.
  26-one-note-seven-homes.wav one held note while home walks under it through the seven moods.
  27-placed-and-true.wav      four fork strikes as the game places them, then as they ring when
                              you were on the beat yourself.
  28-two-tellings.wav         a day sung back with its earlier telling: the same, then different.
  29-two-suns.wav             five dawns that open a comma apart and close; a sixth that doesn't.
  30-be-the-ground.wav        five reeds wandering, then one low held note they come to stand on.
  31-the-close-that-misses.wav  a close that lands; one that lands on the wolf fifth; then a
                              third note between the wolf's two ends, and it rings.
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


# ---------------------------------------------------------------- the wheel (clips 17-31)
# Sketches for ../the-wheel.md, ../experience-fixes.md and ../the-way-home.md.

COMMA = (3 / 2) ** 12 / 2 ** 7          # the Pythagorean comma, 23.46 cents
SOFT = table([1.0, 0.22, 0.07])          # a rounder voice: upper partials beat faster, so keep them low


def glide(m, f0, f1, start, length, gain, at=0.0, over=0.0, wave=PAD, attack=0.12, release=0.4, phase0=0.0, swell=None):
    """A note that can slide from f0 to f1 (starting `at` seconds in, taking `over` seconds).
    `phase0` is in cycles. `swell` (seconds) fades it in slowly instead of `attack`."""
    size = len(wave)
    phase = phase0 * size
    first = int(start * RATE)
    held = int(length * RATE)
    total = held + int(release * RATE)
    a = max(1, int((swell or attack) * RATE))
    r = max(1, int(release * RATE))
    g0, g1 = int(at * RATE), int((at + over) * RATE)
    for i in range(total):
        j = first + i
        if j >= len(m.buf):
            break
        if i <= g0 or over <= 0:
            f = f0 if i <= g0 else f1
        elif i >= g1:
            f = f1
        else:
            f = f0 * (f1 / f0) ** ((i - g0) / (g1 - g0))
        env = min(1.0, i / a)
        if i > held:
            env *= max(0.0, 1.0 - (i - held) / r)
        m.buf[j] += gain * env * wave[int(phase) % size]
        phase += f * size / RATE


def just(root, kind="maj"):
    """Chord tones as pure ratios above a root."""
    shapes = {
        "maj": [1, 5 / 4, 3 / 2],
        "min": [1, 6 / 5, 3 / 2],
        "dom7": [1, 5 / 4, 3 / 2, 7 / 4],        # the seventh harmonic: the barbershop seventh
        "maj7": [1, 5 / 4, 3 / 2, 15 / 8],
        "maj9": [1, 5 / 4, 3 / 2, 15 / 8, 9 / 4],
        "dim": [1, 6 / 5, 7 / 5],                 # the top three notes of a dominant seventh
        "sus4": [1, 4 / 3, 3 / 2],
        "five": [1, 3 / 2],
    }
    return [root * r for r in shapes[kind]]


def low(f, top=160.0):
    while f > top:
        f /= 2
    while f < top / 2:
        f *= 2
    return f


def progression(m, chords, t0, each, last, gain=0.6, tick=True):
    """Play chords (lists of tones) voice-led into the middle of the keyboard, over their bass.
    Returns the time after the last chord."""
    prev = []
    t = t0
    for k, tones in enumerate(chords):
        length = last if k == len(chords) - 1 else each
        prev = voice_lead(prev, tones)
        m.chord(prev + [low(tones[0])], t, length - 0.08, gain, attack=0.05)
        if tick:   # a small pluck marks each step of the thumb
            m.note(low(tones[0], 640.0), t, 0.2, 0.22, wave=PLUCK, attack=0.004, release=0.2, decay=0.25)
        t += length
    return t


# degrees of a pure major key, as ratios above its home note
D2, D2LOW, D3, D4, D5, D6, D7 = 9 / 8, 10 / 9, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 15 / 8


def key_chords(home):
    return {
        "I": just(home), "IV": just(home * D4), "V": just(home * D5), "V7": just(home * D5, "dom7"),
        "ii": just(home * D2LOW, "min"), "vi": just(home * D6, "min"), "iii": just(home * D3, "min"),
        "vii": just(home * D7, "dim"), "Imaj7": just(home, "maj7"), "Imaj9": just(home, "maj9"),
    }


# 17: two ways home. The full close (the creature on your right comes home), then the amen
# (the one on your left is sung to sleep).
K = key_chords(220.0)
m = Mix(13.5)
t = progression(m, [K["I"], K["vi"], K["V7"], K["I"]], 0.2, 1.15, 2.4)
progression(m, [K["I"], K["vi"], K["IV"], K["I"]], t + 0.9, 1.15, 2.6)
m.save("17-two-ways-home.wav")

# 18: home the long way. Walks of two, three, four and five homes, then the whole key.
# Each longer walk lands on a chord with one more colour in it.
walks = [
    ["V7", "I"],
    ["ii", "V7", "I"],
    ["vi", "ii", "V7", "Imaj7"],
    ["iii", "vi", "ii", "V7", "Imaj9"],
    ["I", "IV", "vii", "iii", "vi", "ii", "V7", "Imaj9"],
]
m = Mix(sum(len(w) - 1 for w in walks) * 0.85 + len(walks) * 3.0 + 1.0)
t = 0.2
for w in walks:
    t = progression(m, [K[c] for c in w], t, 0.85, 2.2) + 0.8
m.save("18-home-the-long-way.wav")

# 19: it turns. The chord that should come home lands on its neighbour instead; then the bigger
# turn, onto a borrowed chord, which walks home by a different road.
m = Mix(14.0)
t = progression(m, [K["I"], K["IV"], K["V7"], K["vi"]], 0.2, 1.1, 2.4)
flat6, flat7 = just(220.0 * 8 / 5), just(220.0 * 9 / 5)
progression(m, [K["I"], K["IV"], K["V7"], flat6, flat7, K["I"]], t + 0.9, 1.1, 2.6)
m.save("19-it-turns.wav")

# 20: borrowing home. The third morning is in D. For one bar the world borrows the garden's
# chord, C, the note that set this morning, and comes back.
Dk = key_chords(146.83)
garden = just(146.83 * 16 / 9)            # two fifths below D: yesterday's yesterday
m = Mix(15.0)
t = progression(m, [Dk["I"], Dk["IV"], Dk["I"], Dk["V"]], 0.2, 1.1, 1.1)
tune = [(0, D5 * 2), (0.55, D3 * 2), (1.1, D4 * 2), (1.65, D6 * 2), (2.2, D5 * 2), (2.75, D3 * 2), (3.3, D2 * 2), (3.85, D7)]
for at, r in tune:
    m.note(146.83 * 2 * r, 0.2 + at, 0.4, 0.3, wave=PLUCK, attack=0.005, release=0.25, decay=0.5)
t = progression(m, [garden, Dk["I"]], t, 2.2, 2.6)
for at, r in [(0, 16 / 9 * 5 / 4), (0.55, 16 / 9 * 3 / 2), (1.1, 16 / 9 * 2), (1.65, 16 / 9 * 3 / 2), (2.2, 2 * D3)]:
    m.note(146.83 * 2 * r, t - 4.8 + at, 0.5, 0.3, wave=PLUCK, attack=0.005, release=0.3, decay=0.6)
progression(m, [Dk["I"], just(146.83 * 8 / 5), just(146.83 * 9 / 5), Dk["I"]], t + 0.8, 1.1, 2.6)
m.save("20-borrowing-home.wav")

# 21: the slide. Home by a fifth, then home by a half step from the far side of the wheel
# (the ferry).
m = Mix(11.5)
t = progression(m, [K["ii"], K["V7"], K["I"]], 0.2, 1.2, 2.4)
ferry = just(220.0 * 16 / 15, "dom7")
progression(m, [K["ii"], ferry, K["I"]], t + 0.9, 1.2, 2.6)
m.save("21-the-slide.wav")

# 22: stand where they meet. Two strands, three to the bar and five to the bar, singing C and
# A. Then the note under both of them (F) comes in on the one, and the stumble is a groove.
bar = 1.6
bars_alone, bars_with = 4, 6
root = 87.31                                  # F: its 3rd harmonic is C, its 5th is A
m = Mix((bars_alone + bars_with) * bar + 2.5)
for b in range(bars_alone + bars_with):
    t0 = 0.2 + b * bar
    for k in range(3):
        m.note(root * 3, t0 + k * bar / 3, 0.12, 0.34, wave=PLUCK, attack=0.004, release=0.15, decay=0.16)
    for k in range(5):
        m.note(root * 5, t0 + k * bar / 5, 0.1, 0.3, wave=PLUCK, attack=0.004, release=0.12, decay=0.12)
    if b >= bars_alone:
        m.note(root * 2, t0, 0.5, 0.5, wave=PAD, attack=0.01, release=0.5, decay=0.5)
        m.note(root, t0, 0.5, 0.3, wave=PAD, attack=0.01, release=0.5, decay=0.5)
m.chord([root * 2, root * 4, root * 5, root * 6], 0.2 + bars_alone * bar, bars_with * bar, 0.3, attack=1.5, release=1.5)
m.save("22-stand-where-they-meet.wav")

# 23: rising doubled. An echo's tune at three dusks, its last note doubled a comma apart for a
# moment before the dusk chord takes it in; a little longer each dusk. Then the eleventh dusk.
C4 = 261.6256
echo = [(0.0, 1), (0.3, D3), (0.6, D5), (0.9, D6), (1.2, D5), (1.5, D3), (1.8, D2)]
m = Mix(27.0)
t = 0.2
for tail in (1.0, 1.5, 2.0):
    for at, r in echo:
        m.note(C4 * r, t + at, 0.28, 0.4, wave=PLUCK, attack=0.005, release=0.25, decay=0.6)
    t1 = t + 2.1
    glide(m, C4, C4, t1, tail, 0.3, wave=SOFT, release=0.5)
    glide(m, C4 * COMMA, C4 * COMMA, t1, tail, 0.3, wave=SOFT, release=0.5)
    m.chord([C4 / 2, C4 * 3 / 4, C4, C4 * 5 / 4, C4 * 3 / 2], t1 + tail, 1.6, 0.55, attack=0.25, release=0.8)
    t = t1 + tail + 2.9
for at, r in echo:
    m.note(C4 * r, t + at, 0.28, 0.4, wave=PLUCK, attack=0.005, release=0.25, decay=0.6)
glide(m, C4, C4, t + 2.1, 3.2, 0.34, wave=PAD, release=1.2)
glide(m, C4 * COMMA, C4 * COMMA, t + 2.1, 3.2, 0.34, wave=PAD, release=1.2)
glide(m, C4 * 3 / 2 / COMMA, C4 * 3 / 2 / COMMA, t + 2.5, 2.8, 0.22, wave=PAD, release=1.2)   # the fifth that falls short
m.save("23-rising-doubled.wav")

# 24: the comma in time. At 107 beats a minute a comma at middle C beats in eighth notes, so
# the wobble is the pulse. Then a third voice comes in between the two, the pulse halves into a
# heartbeat, and a chord grows on the note in the middle.
beat_hz = C4 * (COMMA - 1)                    # 3.569 a second
eighth = 1 / beat_hz
q = 2 * eighth                                # one beat: 0.5604 s, 107.07 a minute
mid = C4 * (1 + COMMA) / 2                    # what two near-unisons sum to
m = Mix(52 * q + 3.0)
t0 = 0.2
for b in range(52):                           # the heartbeat, quiet, all the way through
    m.note(C4 / 2, t0 + b * q, 0.1, 0.16 if b < 36 else 0.22, wave=SOFT, attack=0.004, release=0.2, decay=0.12)
ta = t0 + 4 * q                               # the two voices start together, on a downbeat
glide(m, C4, C4, ta, 40 * q, 0.3, wave=SOFT, attack=0.02, release=4 * q)
glide(m, C4 * COMMA, C4 * COMMA, ta, 40 * q, 0.3, wave=SOFT, attack=0.02, release=4 * q)
tb = ta + 16 * q                              # the third voice, in step with what they already sum to
glide(m, mid, mid, tb, 30 * q, 0.8, wave=SOFT, swell=4 * q, release=3.0, phase0=(mid * (tb - ta)) % 1.0)
tc = tb + 16 * q                              # home, built on the note in the middle
for r, g in ((0.5, 0.3), (0.75, 0.2), (1.25, 0.18), (1.5, 0.2)):
    glide(m, mid * r, mid * r, tc, 14 * q, g, wave=PAD, swell=4 * q, release=3.0, phase0=(mid * r * (tc - ta)) % 1.0)
m.save("24-the-comma-in-time.wav")

# 25: twelve mornings in one breath. Home, then twelve steps up by pure fifths, one a bar, and
# the arrival: the same key as the start on a piano, a comma above it in truth. The first
# note comes back and the two sit side by side.
m = Mix(13 * 4 * q * 0.5 + 5 * 4 * q + 4.0)
half = 2 * q                                  # one step every two beats
t = 0.2
m.chord([C4 / 2, C4, C4 * 5 / 4, C4 * 3 / 2], t, 2 * half - 0.1, 0.55, attack=0.1)
t += 2 * half
prev = []
root = C4 / 2
for step in range(1, 13):
    root *= 3 / 2
    if root > 190:
        root /= 2
    prev = voice_lead(prev, just(root))
    m.chord(prev + [root], t, half - 0.06, 0.55, attack=0.04, release=0.3)
    for k, f in enumerate(sorted(prev)):
        m.note(f * 2, t + k * half / 4, 0.2, 0.2, wave=PLUCK, attack=0.004, release=0.2, decay=0.3)
    t += half
arrive = C4 * COMMA                           # twelve fifths up, seven octaves down
glide(m, arrive, arrive, t, 16 * q, 0.3, wave=SOFT, attack=0.02, release=2.5)
glide(m, C4, C4, t + 4 * q, 12 * q, 0.3, wave=SOFT, attack=0.02, release=2.5, phase0=(C4 * 4 * q) % 1.0)
for b in range(16):
    m.note(C4 / 2, t + b * q, 0.1, 0.16, wave=SOFT, attack=0.004, release=0.2, decay=0.12)
m.save("25-twelve-mornings.wav")

# 26: one note, seven homes. One held note, and home walks underneath it from the brightest
# mood to the darkest, then back to sunny home. The note never moves; what it is does.
homes = [
    ("wonder", D4 / 2, [D4 / 2, D6 / 2]),             # F under it: the note is the fifth
    ("sunny home", 0.5, [0.5, D3 / 2, D5 / 2]),        # C: the note is home
    ("drive", D5 / 2, [D5 / 2, D2]),                    # G and D: the note hangs as the fourth
    ("cool soul", D2LOW / 2, [D2LOW / 2, D4 / 2, D6 / 2]),   # D minor: the note is the seventh
    ("tenderness", D6 / 2, [D6 / 2, D3]),               # A and E: the note is the minor third
    ("fierceness", D3 / 2, [D3 / 2, D5 / 2]),           # E and G: the note is the minor sixth
    ("the darkest", D7 / 4, [D7 / 4, D2LOW / 2, D4 / 2]),    # B, D, F: the note grinds a half step above
    ("sunny home", 0.5, [0.5, D3 / 2, D5 / 2]),
]
span = 2.6
m = Mix(len(homes) * span + 3.0)
glide(m, C4, C4, 0.2, len(homes) * span + 0.8, 0.34, wave=SOFT, attack=0.3, release=1.5)
for k, (_, bass, tones) in enumerate(homes):
    t0 = 0.2 + k * span
    length = span - 0.15 if k < len(homes) - 1 else span + 0.6
    m.note(low(C4 * bass, 180.0), t0, length, 0.34, attack=0.25, release=0.5)
    m.note(low(C4 * bass, 180.0) / 2, t0, length, 0.2, attack=0.25, release=0.5)
    for r in tones[1:]:
        m.note(C4 * r, t0, length, 0.2, attack=0.3, release=0.5)
m.save("26-one-note-seven-homes.wav")

# 27: a placed strike and a true one. Four fork strikes as the game places them, then the same
# four as they ring when you were on the beat yourself.
m = Mix(9.5)
strikes = [220.0 * 2, 220.0 * 2 * D3, 220.0 * 2 * D5, 220.0 * 4]
m.chord([110.0, 165.0, 220.0], 0.2, 8.4, 0.3, attack=0.3, release=0.8)
for k, f in enumerate(strikes):
    m.note(f, 0.4 + k * 0.56, 0.3, 0.5, wave=PLUCK, attack=0.004, release=0.3, decay=0.35)
for k, f in enumerate(strikes):
    t0 = 4.4 + k * 0.56
    m.note(f, t0, 0.5, 0.5, wave=PLUCK, attack=0.004, release=0.6, decay=0.7)
    m.note(f * 2, t0, 0.5, 0.26, wave=PLUCK, attack=0.004, release=0.6, decay=0.9)
    m.note(f * 3, t0 + 0.02, 0.5, 0.1, wave=SINE, attack=0.004, release=0.8, decay=1.1)
m.save("27-placed-and-true.wav")

# 28: two tellings. The river sings a repeated day back with its earlier telling. First the two
# are the same, note for note: one voice. Then the second telling differs, and there are two.
first = [(0.0, 1), (0.4, D2), (0.8, D3), (1.2, D5), (1.8, D6), (2.2, D5), (2.6, D3), (3.0, D2), (3.4, D3), (4.0, 1)]
second = [(0.0, 1), (0.4, D2), (0.8, D3), (1.2, D5), (1.8, 2.0), (2.2, D7), (2.6, D5), (3.2, D4), (3.6, D5), (4.0, D3)]
m = Mix(12.5)
for t0, other in ((0.2, first), (6.2, second)):
    m.chord([110.0, 165.0], t0, 4.8, 0.22, attack=0.3, release=0.8)
    for at, r in first:
        m.note(220.0 * r, t0 + at, 0.34, 0.4, wave=PLUCK, attack=0.005, release=0.3, decay=0.7)
    for at, r in other:
        m.note(220.0 * r, t0 + at, 0.34, 0.4, wave=SOFT, attack=0.03, release=0.3, decay=0.9)
m.save("28-two-tellings.wav")

# 29: two suns. Five dawns on the way home. Each opens with the land's note and the day's a
# comma apart; the land gives way and the dawn chord blooms. It takes longer each morning.
# The sixth dawn is the garden's, and it doesn't give way.
m = Mix(38.5)
t = 0.2
for morning, wait in zip(range(8, 13), (0.5, 1.0, 1.0, 2.0, 3.0)):
    note = C4 * (3 / 2) ** (morning - 1)
    while note > 330:
        note /= 2
    glide(m, note, note, t, wait + 2.6, 0.3, wave=SOFT, attack=0.05, release=0.8)
    glide(m, note / COMMA, note, t, wait + 2.6, 0.3, at=wait, over=0.45, wave=SOFT, attack=0.05, release=0.8)
    for k, r in enumerate((0.5, 0.75, 1.25, 1.5, 2.0)):
        m.note(note * r, t + wait + 0.45 + k * 0.12, 2.0 - k * 0.12, 0.2, attack=0.2, release=0.8)
    t += wait + 4.3
note = C4 * COMMA
glide(m, note, note, t, 5.0, 0.3, wave=SOFT, attack=0.05, release=2.0)
glide(m, C4, C4, t, 5.0, 0.3, wave=SOFT, attack=0.05, release=2.0)
m.save("29-two-suns.wav")

# 30: be the ground. Five reeds, each singing by itself with no floor under them. Then one low
# held note comes in, and one by one they stand on it.
REED2 = table([1.0, 0.0, 0.4, 0.0, 0.2, 0.0, 0.1])
scale = [1, D2, D4, D5, D6, 2, 2 * D2, 2 * D4]      # a five-note chant mode on D
seed = 12345
def rnd():
    global seed
    seed = (seed * 1103515245 + 12345) % 2 ** 31
    return seed / 2 ** 31
base = 146.83 * 2
total = 24.0
m = Mix(total + 2.5)
drone_at = 9.0
m.note(base / 2, drone_at, total - drone_at, 0.42, attack=1.2, release=1.5)
m.note(base / 4, drone_at, total - drone_at, 0.28, attack=1.2, release=1.5)
m.note(base * 3 / 4, drone_at + 4.0, total - drone_at - 4.0, 0.2, attack=1.5, release=1.5)
for reed in range(5):
    t = 0.2 + rnd() * 0.9
    lock_at = drone_at + 1.5 + reed * 2.2       # when this reed finds the ground
    step = int(rnd() * len(scale))
    while t < total:
        if t < lock_at:
            length = 0.5 + rnd() * 0.9            # each in its own time
            step = max(0, min(len(scale) - 1, step + int(rnd() * 5) - 2))
            f = base * scale[step] * (2 ** ((rnd() - 0.5) * 0.007))
        else:
            length = 0.9                          # together, in the ground's time
            t = drone_at + round((t - drone_at) / 0.9) * 0.9
            chant = [1, D2, D4, D5, D4, D2, 1, D5 / 2]
            f = base * chant[int((t - drone_at) / 0.9) % len(chant)] * (1.5 if reed % 2 else 1.0)
        m.note(f, t, length * 0.85, 0.16, wave=REED2, attack=0.08, release=0.3)
        t += length
m.save("30-be-the-ground.wav")

# 31: the close that misses. A close that lands (E flat falling home to A flat, tuned pure).
# Then the same close in the Hollow's own tuning, where home's fifth is the wolf. Then the wolf
# again, and a third note comes in between its two ends: both move a hair to tune to it, and
# the howl is a chord.
m = Mix(19.5)
ab = 207.65
m.chord(just(ab * 3 / 4) + [ab * 3 / 8], 0.2, 1.3, 0.6, attack=0.05)
m.chord([ab / 2, ab, ab * 3 / 2], 1.6, 2.2, 0.55)
t = 4.9
m.chord([mt(-3, -1), mt(-3), mt(1), mt(-2)], t, 1.3, 0.6, attack=0.05)     # E flat major, in meantone
wolf_low, wolf_high = mt(8), mt(-3, 1)        # G sharp and the E flat above it
m.chord([wolf_low / 2, wolf_low, wolf_high], t + 1.4, 2.4, 0.55)
t += 5.0
third = wolf_low * 2 ** (17.84 / 1200) * 5 / 4     # the green note between them
glide(m, wolf_low, third * 4 / 5, t, 7.0, 0.32, at=2.4, over=0.9, release=1.5)
glide(m, wolf_high, third * 6 / 5, t, 7.0, 0.32, at=2.4, over=0.9, release=1.5)
glide(m, third, third, t + 1.6, 5.4, 0.34, swell=0.8, release=1.5)
glide(m, third * 2 / 5, third * 2 / 5, t + 3.6, 3.4, 0.3, wave=SINE, swell=1.2, release=1.5)
m.save("31-the-close-that-misses.wav")
