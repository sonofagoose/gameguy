#!/usr/bin/env python3
"""Four more listening sketches for the brainstorm of 2026-11-25 (part two). Kept in design/listen/sketches/ beside the clips it makes.

No held pads: every sound here is struck or sung and dies away, and every ground is struck again
rather than held, because held synth tones were what Morgan's ears disliked most in the room.

  d-one-voice-over-a-moving-ground.wav   Hum sings one short tune made only of the overtones of
                             its one note (3, 4, 5, 6 and 8 of C). The tune never changes. The
                             ground under it moves: C, A, F, G, then C, E, A, D, G, C.
  e-down-and-back-up.wav     a figure on C's chord; two of its notes stay and one rises (G to A),
                             and the ground drops a third: the same notes from underneath. A
                             phrase down there. Then the way up (the chord on G lifts to C). Then
                             down again, and this time a note that is not the land's (G sharp)
                             makes underneath a home.
  f-the-trade.wav            one phrase four ways: at home and far away under the treaty (the
                             same); then at home with its thirds made sweet, and far away as that
                             leaves it: pure fifths and harsh thirds, sung the way that tuning
                             sounds best, and then once as a full chord.
  g-up-from-the-ground-down-from-the-ceiling.wav
                             a low note and its 4th, 5th and 6th overtones: a major chord,
                             standing. A high note and the notes a 4th, 5th and 6th of it: a minor
                             chord, hanging. Then three soft bells that ring every 4, 5 and 6
                             beats, slowly, then faster, until they are that same minor chord.

Usage: python3 -I sketches2.py OUTDIR
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


HUM = table([1.0, 0.28, 0.10, 0.04])                 # a round sung voice
KEYS = table([1.0, 0.5, 0.3, 0.15, 0.08])            # struck, bright
DARK = table([1.0, 0.18, 0.05])                      # struck, soft: underneath
BASS = table([1.0, 0.7, 0.35, 0.18, 0.08])           # a low string, with enough top for a small speaker
BELL = table([1.0, 0.0, 0.32, 0.0, 0.1])
SINE = table([1.0])


class Mix:
    def __init__(self, seconds):
        self.buf = [0.0] * int(seconds * RATE)

    def note(self, freq, start, length, gain, wave=KEYS, attack=0.006, release=0.3, decay=None):
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
            if j < 0:
                phase += step
                continue
            env = min(1.0, i / a)
            if i > held:
                env *= max(0.0, 1.0 - (i - held) / r)
            if decay:
                env *= math.exp(-i / (decay * RATE))
            self.buf[j] += gain * env * wave[int(phase) % size]
            phase += step

    def struck(self, freqs, start, gain, wave=KEYS, ring=1.1, spread=0.012):
        """A chord struck and left to die away, its notes a hair apart like a hand."""
        for n, f in enumerate(sorted(freqs)):
            self.note(f, start + n * spread, ring * 1.6, gain / len(freqs) ** 0.5, wave=wave,
                      attack=0.005, release=0.5, decay=ring * 0.55)

    def reverb(self, wet=0.22, long=1.0):
        dry = self.buf
        out = [0.0] * len(dry)
        for delay_ms, fb in [(29.7, 0.78), (37.1, 0.76), (41.1, 0.74), (43.7, 0.72)]:
            d = int(delay_ms * long * RATE / 1000)
            fb = min(0.9, fb ** (1.0 / long)) if long > 1.0 else fb
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

    def add(self, other, at=0.0):
        first = int(at * RATE)
        need = first + len(other.buf)
        if need > len(self.buf):
            self.buf.extend([0.0] * (need - len(self.buf)))
        for i, x in enumerate(other.buf):
            self.buf[first + i] += x

    def save(self, name, peak=0.45, wet=0.22):
        if wet:
            self.reverb(wet)
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


def cents(r):
    return 1200 * math.log2(r)


C4 = 261.6256


# ---------------------------------------------------------------------------------------------
# d: one voice over a moving ground
# ---------------------------------------------------------------------------------------------
def sketch_d():
    beat = 60.0 / 96
    bar = 4 * beat
    # Hum's tune: two bars, only overtones 3, 4, 5, 6 and 8 of its one note (the C two octaves
    # under middle C): G, C, E, G, C. (beat, overtone, length in beats)
    tune = [(0.0, 4, 0.9), (1.0, 5, 0.45), (1.5, 6, 0.9), (2.5, 5, 0.45), (3.0, 4, 0.9),
            (4.0, 3, 0.9), (5.0, 4, 0.45), (5.5, 5, 0.45), (6.0, 6, 0.45), (6.5, 8, 1.2)]
    fund = C4 / 4
    # the grounds, each as a pure ratio to C: where home is, under the same tune
    grounds = [("C", 1.0), ("A", 5 / 6), ("F", 2 / 3), ("G", 3 / 4),
               ("E", 5 / 8), ("D", 9 / 16), ("G", 3 / 4), ("C", 1.0)]
    m = Mix(len(grounds) * 2 * bar + 6)
    t = 0.3
    # first the tune alone, once, so it is known
    for at, n, ln in tune:
        m.note(fund * n, t + at * beat, ln * beat, 0.40, wave=HUM, attack=0.03, release=0.18, decay=1.4)
    t += 2 * bar + 0.5 * beat
    report = []
    for name, r in grounds:
        g = C4 / 2 * r
        while g < 80:
            g *= 2
        for b in range(2):
            m.note(g, t + b * bar, 1.6 * beat, 0.46, wave=BASS, attack=0.008, release=0.4, decay=0.9)
            m.note(g * 2, t + b * bar + 2 * beat, 1.2 * beat, 0.26, wave=BASS, attack=0.008, release=0.4, decay=0.7)
        for at, n, ln in tune:
            m.note(fund * n, t + at * beat, ln * beat, 0.40, wave=HUM, attack=0.03, release=0.18, decay=1.4)
        # what Hum's own note (overtone 4) is to this ground, folded into one octave
        rel = 1.0 / r
        while rel >= 2:
            rel /= 2
        while rel < 1:
            rel *= 2
        report.append((name, round(cents(rel), 1)))
        t += 2 * bar
    # the last C, landed
    m.note(C4 / 2, t, 2.0, 0.46, wave=BASS, attack=0.008, release=0.8, decay=1.4)
    m.struck([C4, C4 * 5 / 4, C4 * 3 / 2], t, 0.34, wave=HUM, ring=1.6)
    m.save("d-one-voice-over-a-moving-ground.wav")
    return {"hum's own note over each ground, in cents": report}


# ---------------------------------------------------------------------------------------------
# e: down, and back up
# ---------------------------------------------------------------------------------------------
def sketch_e():
    c = C4
    e, g, a, b = c * 5 / 4, c * 3 / 2, c * 5 / 3, c * 15 / 8
    d_low = c * 10 / 9               # underneath, D is a pure fourth over A
    gs = c * 25 / 16                 # G sharp: a pure third over E, not one of the land's notes
    beat = 60.0 / 84
    out = Mix(1.0)

    def above(t0, m, ground=True):
        """The land: C's chord as a rising figure, bright, with the octave over it."""
        fig = [(0, c), (1, e), (2, g), (3, c * 2), (4, g), (5, e)]
        for k, f in fig:
            m.note(f, t0 + k * beat / 2, 0.3, 0.36, wave=KEYS, attack=0.004, release=0.35, decay=0.8)
            m.note(f * 2, t0 + k * beat / 2, 0.2, 0.10, wave=BELL, attack=0.004, release=0.3, decay=0.4)
        if ground:
            m.note(c / 2, t0, 1.2, 0.40, wave=BASS, attack=0.008, release=0.5, decay=1.0)
        return t0 + 3 * beat

    def below(t0, m):
        """Underneath: the same notes with A under them, soft and close."""
        fig = [(0, a / 2), (1, c), (2, e), (3, a), (4, e), (5, c)]
        for k, f in fig:
            m.note(f, t0 + k * beat / 2, 0.3, 0.34, wave=DARK, attack=0.008, release=0.4, decay=0.9)
        m.note(a / 4, t0, 1.2, 0.44, wave=BASS, attack=0.01, release=0.5, decay=1.1)
        return t0 + 3 * beat

    # 1. above, twice
    up = Mix(8)
    t = 0.3
    t = above(t, up)
    t = above(t, up)
    # 2. the door: C and E are struck again and stay; G steps up to A; then the ground drops
    up.note(c, t, 0.9, 0.30, wave=KEYS, attack=0.004, release=0.5, decay=1.2)
    up.note(e, t, 0.9, 0.30, wave=KEYS, attack=0.004, release=0.5, decay=1.2)
    up.note(g, t, 0.5, 0.32, wave=KEYS, attack=0.004, release=0.2, decay=0.9)
    up.reverb(0.20)
    out.add(up, 0.0)
    t_door = t + 1.5 * beat
    down = Mix(16)
    td = 0.0
    down.note(c, td, 1.0, 0.26, wave=DARK, attack=0.01, release=0.6, decay=1.3)
    down.note(e, td, 1.0, 0.26, wave=DARK, attack=0.01, release=0.6, decay=1.3)
    down.note(a, td, 1.0, 0.34, wave=DARK, attack=0.01, release=0.6, decay=1.3)
    down.note(a / 4, td + 1.5 * beat, 1.4, 0.46, wave=BASS, attack=0.01, release=0.6, decay=1.2)
    td += 3.5 * beat
    # 3. underneath: the figure, then a phrase that settles without any pull (no raised note)
    td = below(td, down)
    td = below(td, down)
    phrase = [(0, e, 1), (1, d_low, 1), (2, c, 1), (3, a / 2, 0.5), (3.5, g / 2, 0.5), (4, a / 2, 2)]
    for at, f, ln in phrase:
        down.note(f, td + at * beat, ln * beat * 0.8, 0.34, wave=HUM, attack=0.03, release=0.3, decay=1.2)
    down.note(a / 4, td, 1.4, 0.42, wave=BASS, attack=0.01, release=0.6, decay=1.2)
    down.note(a / 4, td + 4 * beat, 1.6, 0.42, wave=BASS, attack=0.01, release=0.6, decay=1.4)
    td += 6.5 * beat
    len_down = td
    down.reverb(0.42, long=1.6)
    out.add(down, t_door)
    # 4. the way up: the chord on G (the land's own notes), then C, and the day again
    t = t_door + len_down + 0.2
    lift = Mix(9)
    tl = 0.0
    lift.struck([g / 2, b / 2, c * 9 / 8], tl, 0.40, wave=KEYS, ring=1.0)
    lift.note(g / 4, tl, 1.0, 0.42, wave=BASS, attack=0.008, release=0.5, decay=1.0)
    tl += 2 * beat
    tl = above(tl, lift)
    tl = above(tl, lift)
    lift.struck([c, e, g, c * 2], tl, 0.36, wave=KEYS, ring=1.4)
    lift.note(c / 2, tl, 1.6, 0.42, wave=BASS, attack=0.008, release=0.6, decay=1.3)
    tl += 3.2 * beat
    lift.reverb(0.20)
    out.add(lift, t)
    t += tl + 0.9
    # 5. down again; this time G sharp, and the chord on E falls onto A: underneath is home
    stay = Mix(14)
    ts = 0.0
    ts = below(ts, stay)
    stay.struck([e / 2, gs / 2, b / 2], ts, 0.40, wave=DARK, ring=1.1)
    stay.note(e / 4, ts, 1.1, 0.44, wave=BASS, attack=0.01, release=0.5, decay=1.0)
    stay.note(gs, ts + 1.0 * beat, 0.8 * beat, 0.34, wave=HUM, attack=0.03, release=0.2, decay=0.9)
    ts += 2 * beat
    stay.struck([a / 2, c, e, a], ts, 0.42, wave=DARK, ring=1.8)
    stay.note(a, ts, 1.4 * beat, 0.34, wave=HUM, attack=0.03, release=0.5, decay=1.4)
    stay.note(a / 4, ts, 2.0, 0.48, wave=BASS, attack=0.01, release=0.8, decay=1.6)
    stay.reverb(0.42, long=1.6)
    out.add(stay, t)
    out.save("e-down-and-back-up.wav", wet=0.0)
    return {"G to A": round(cents(a / g), 3), "G sharp to A": round(cents(a / gs), 3),
            "ground drops": round(cents((a / 2) / c), 3)}


# ---------------------------------------------------------------------------------------------
# f: the trade
# ---------------------------------------------------------------------------------------------
def sketch_f():
    beat = 60.0 / 80

    def phrase(m, t0, root, third, fifth, fourth_r, wave=KEYS, thirds=True, gain=0.40):
        """Home, the chord a fourth up, the chord a fifth up, home. `third` and `fifth` are the
        sizes of this tuning's major third and fifth as ratios; `fourth_r` its fourth."""
        roots = [root, root * fourth_r, root * fifth / 2, root]
        for k, r in enumerate(roots):
            tones = [r, r * fifth, r * 2]
            if thirds:
                tones.insert(1, r * third)
            tt = t0 + k * 2 * beat
            # broken upward, then struck together, the way a hand tries a chord
            for n, f in enumerate(tones):
                m.note(f, tt + n * beat / 4, 0.3, gain * 0.6, wave=wave, attack=0.004, release=0.35, decay=0.7)
            m.struck(tones, tt + beat, gain, wave=wave, ring=1.0)
            m.note(r / 2, tt, 1.0, 0.36, wave=BASS, attack=0.008, release=0.5, decay=0.9)
        return t0 + 8 * beat + 0.9

    et = lambda n: 2 ** (n / 12)
    home = C4                        # C
    far = home * et(6)               # F sharp, the far side
    m = Mix(60)
    t = 0.3
    # 1 and 2: under the treaty, home and the far side are the same
    t = phrase(m, t, home, et(4), et(7), et(5))
    t = phrase(m, t, far, et(4), et(7), et(5))
    t += 0.6
    # 3: home, with its thirds made sweet
    t = phrase(m, t, home, 5 / 4, 3 / 2, 4 / 3)
    # 4: the far side as that leaves it: pure fifths, sung as fifths and octaves
    far_p = far
    t = phrase(m, t, far_p, 81 / 64, 3 / 2, 4 / 3, thirds=False)
    # 5: and once with its third, to hear what was given up there
    m.struck([far_p, far_p * 81 / 64, far_p * 3 / 2, far_p * 2], t, 0.40, wave=KEYS, ring=1.2)
    m.note(far_p / 2, t, 1.0, 0.36, wave=BASS, attack=0.008, release=0.5, decay=0.9)
    t += 2.4 * beat
    # 6: home once more, sweet
    m.struck([home, home * 5 / 4, home * 3 / 2, home * 2], t, 0.40, wave=KEYS, ring=1.6)
    m.note(home / 2, t, 1.4, 0.38, wave=BASS, attack=0.008, release=0.6, decay=1.2)
    m.save("f-the-trade.wav")
    return {"treaty third is sharp by": round(cents(et(4) / (5 / 4)), 3),
            "far third is sharp by": round(cents((81 / 64) / (5 / 4)), 3),
            "treaty fifth is narrow by": round(cents((3 / 2) / et(7)), 3)}


# ---------------------------------------------------------------------------------------------
# g: up from the ground, down from the ceiling
# ---------------------------------------------------------------------------------------------
def sketch_g():
    low = C4 / 4                     # 65.4 Hz: the ground
    high = low * 20                  # 1308 Hz: the ceiling (an E)
    m = Mix(64)
    t = 0.3
    # the ground, then its 4th, 5th and 6th overtones, one at a time, then together: standing
    m.note(low * 2, t, 1.2, 0.34, wave=BASS, attack=0.01, release=0.6, decay=1.2)
    m.note(low, t, 1.2, 0.30, wave=BASS, attack=0.01, release=0.6, decay=1.2)
    t += 1.3
    for n in (4, 5, 6):
        m.note(low * n, t, 0.5, 0.36, wave=KEYS, attack=0.004, release=0.4, decay=0.9)
        t += 0.55
    m.struck([low * 4, low * 5, low * 6], t, 0.42, wave=KEYS, ring=1.6)
    m.note(low * 2, t, 1.4, 0.30, wave=BASS, attack=0.01, release=0.6, decay=1.3)
    t += 2.7
    # the ceiling, then the notes a 4th, a 5th and a 6th of it, then together: hanging
    m.note(high, t, 1.0, 0.20, wave=BELL, attack=0.004, release=0.6, decay=0.9)
    t += 1.3
    for n in (4, 5, 6):
        m.note(high / n, t, 0.5, 0.36, wave=KEYS, attack=0.004, release=0.4, decay=0.9)
        t += 0.55
    m.struck([high / 4, high / 5, high / 6], t, 0.42, wave=KEYS, ring=1.6)
    m.note(high / 12, t, 1.4, 0.30, wave=BASS, attack=0.01, release=0.6, decay=1.3)
    t += 2.9
    # three soft bells that ring every 4, 5 and 6 ticks, 7 ticks a second, for one whole round
    # of 60 ticks, when they meet again. Then the tick doubles every 0.4 seconds, a short rise
    # like a tape coming up to speed; once a bell rings often enough its ringing is a note, and
    # that note is drawn as a plain tone. They end as the notes a 4th, 5th and 6th of the
    # ceiling: the same hanging chord.
    start_rate = 7.0
    end_rate = high
    hold = 60.0 / start_rate                     # one whole round: the bells meet again at tick 60
    double = 0.40                                # then a short rise, like a tape coming up to speed
    rise = double * math.log2(end_rate / start_rate)
    land = 2.2

    def rate(tt):
        if tt < hold:
            return start_rate
        if tt < hold + rise:
            return start_rate * 2 ** ((tt - hold) / double)
        return end_rate

    total = hold + rise + land
    n0 = int(t * RATE)
    bells = {4: (KEYS, high / 2), 5: (KEYS, high / 2.5), 6: (KEYS, high / 3)}
    ticks = 0.0
    last = {4: -1, 5: -1, 6: -1}
    phase = {4: 0.0, 5: 0.0, 6: 0.0}
    need = n0 + int((total + 1.0) * RATE)
    if need > len(m.buf):
        m.buf.extend([0.0] * (need - len(m.buf)))
    size = len(SINE)
    for i in range(int(total * RATE)):
        tt = i / RATE
        r = rate(tt)
        ticks += r / RATE
        for p in (4, 5, 6):
            f = r / p                            # how often this bell rings, a second
            # a struck bell while slow, fading out as its ringing becomes a note
            strike_gain = max(0.0, min(1.0, (30.0 - f) / 22.0))
            k = int(ticks / p)
            if k != last[p]:
                last[p] = k
                if strike_gain > 0.0:
                    wv, pitch = bells[p]
                    m.note(pitch, t + tt, 0.05, 0.30 * strike_gain, wave=wv, attack=0.003, release=0.12,
                           decay=0.10)
            # the ringing itself, as a tone, fading in as it becomes one
            tone_gain = max(0.0, min(1.0, (f - 70.0) / 110.0))
            phase[p] += f * size / RATE
            if tone_gain > 0.0:
                fade = 1.0
                left = total - tt
                if left < 1.4:
                    fade = max(0.0, left / 1.4)
                m.buf[n0 + i] += 0.15 * tone_gain * fade * SINE[int(phase[p]) % size]
    t += total + 0.5
    # and that chord struck plainly, to be sure of it
    m.struck([high / 4, high / 5, high / 6], t, 0.42, wave=KEYS, ring=1.8)
    m.note(high / 12, t, 1.6, 0.30, wave=BASS, attack=0.01, release=0.7, decay=1.4)
    m.save("g-up-from-the-ground-down-from-the-ceiling.wav")
    return {"standing": [round(low * n, 2) for n in (4, 5, 6)], "hanging": [round(high / n, 2) for n in (6, 5, 4)],
            "steps of the hanging chord": [round(cents((high / 5) / (high / 6)), 1), round(cents((high / 4) / (high / 5)), 1)],
            "the rise lasts": round(rise, 2)}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    which = sys.argv[2] if len(sys.argv) > 2 else "defg"
    for name, f in (("d", sketch_d), ("e", sketch_e), ("f", sketch_f), ("g", sketch_g)):
        if name in which:
            print(f.__name__, f())
