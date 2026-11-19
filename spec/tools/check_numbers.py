#!/usr/bin/env python3
"""Recompute the numbers the specification states, so each can be checked against the text.

    python3 -I spec/tools/check_numbers.py

Every line names the place in SPEC.md or spec/ that states the number.
"""
import math

C4 = 261.63
FIFTH = 1200 * math.log2(3 / 2)


def cents(ratio):
    return 1200 * math.log2(ratio)


def ratio(c):
    return 2 ** (c / 1200)


print("== the spiral (SPEC 6.4; spec/world.md, the long spiral)")
for n in (12, 41, 53, 306, 665):
    c = n * FIFTH
    octs = round(c / 1200)
    miss = c - octs * 1200
    beat = C4 * abs(ratio(miss) - 1)
    print(f"  {n:>3} fifths = {octs:>3} octaves {miss:+8.3f} cents; "
          f"at middle C two tones beat {beat:.4f} a second, once in {1 / beat:7.2f} s")
print(f"  the thirteenth morning's note: {C4 * 3 ** 12 / 2 ** 19:.2f} Hz")

print("== sympathy: how much two overtones share (spec/laws.md, law 1)")
for d, what in ((0, "pure"), (1.955, "an equal-tempered fifth"), (13.69, "an equal-tempered third"),
                (21.51, "the third four pure fifths make"), (23.46, "a comma"), (100, "a semitone")):
    print(f"  {d:6.2f} cents ({what}): {math.exp(-(d / 15) ** 2):.3f}")

print("== beats at middle C (spec/laws.md, law 5; design/drawn-in-light.md)")
g_et = C4 * ratio(700)
g_mt = C4 * ratio(1200 * math.log2(5) / 4)
e_et = C4 * ratio(400)
e_py = C4 * 81 / 64
print(f"  fifth, equal temperament:  {abs(3 * C4 - 2 * g_et):.2f} a second")
print(f"  fifth, sweet thirds:       {abs(3 * C4 - 2 * g_mt):.2f}")
print(f"  third, equal temperament:  {abs(5 * C4 - 4 * e_et):.2f}")
print(f"  third, pure fifths:        {abs(5 * C4 - 4 * e_py):.2f}")
print(f"  the comma:                 {C4 * (3 ** 12 / 2 ** 19 - 1):.2f}")

print("== tunings, cents above the land's note (spec/laws.md, tuning)")
mt5 = 1200 * math.log2(5) / 4


def fold(c):
    return c % 1200


rows = {
    "pure": [cents(r) for r in (9 / 8, 5 / 4, 4 / 3, 3 / 2, 5 / 3, 15 / 8)],
    "pure fifths": [fold(k * FIFTH) for k in (2, 4, -1, 1, 3, 5)],
    "sweet thirds": [fold(k * mt5) for k in (2, 4, -1, 1, 3, 5)],
    "equal": [200, 400, 500, 700, 900, 1100],
}
for name, row in rows.items():
    print(f"  {name:<13}" + " ".join(f"{c:7.1f}" for c in row))
print(f"  the wolf fifth in sweet thirds: {1200 * 7 - 11 * mt5:.1f} cents, "
      f"{1200 * 7 - 11 * mt5 - FIFTH:.1f} wide")
print(f"  the harmonic seventh: {cents(7 / 4):.1f} cents, {1000 - cents(7 / 4):.1f} flat of the piano's")

print("== speed bends pitch: coming toward you at a fraction of the speed of sound (law 6)")
for n in (9, 5, 4, 3, 2):
    r = 1 / (1 - 1 / n)
    print(f"  one {n}th: x{r:.4f} = {cents(r):7.1f} cents")

print("== light, forty octaves up (spec/world.md, the sky)")
for name, hz, octs in (("A 440", 440.0, 40), ("middle C", C4, 41)):
    f = hz * 2 ** octs
    print(f"  {name} raised {octs} octaves: {f:.3e} Hz = {299792458 / f * 1e9:.0f} nm")

print("== lives that meet (spec/people.md)")
print(f"  rounds of 3 and 4 meet every {math.lcm(3, 4)} mornings; 3, 4 and 5 every {math.lcm(3, 4, 5)};")
print(f"  3, 4, 5 and 7 every {math.lcm(3, 4, 5, 7)}; 13 and 17 every {math.lcm(13, 17)}")
print("  periods 3, 4, 5 sped up are rates 1/3 : 1/4 : 1/5 = 20 : 15 : 12:")
print(f"    {cents(15 / 12):.1f} and {cents(20 / 15):.1f} cents: a pure third under a pure fourth, "
      "which is a minor chord (C E A)")

print("== sizes (SPEC 18; measured values are quoted there, these are the sums)")
print(f"  one step of the world is {48000 // 60} samples; a buffer is {128 / 48000 * 1000:.2f} ms")
print(f"  overtones in half a buffer at 4.7 ns each: {0.5 * 128 / 48000 / (4.7e-9 * 128):.0f}")
print(f"  backlight share of the idle draw at full: {(388 - 180) / 388 * 100:.0f}%; "
      f"saved at 120 from 200: {(350 - 275) / 350 * 100:.0f}%; at 60: {(350 - 226) / 350 * 100:.0f}%")
