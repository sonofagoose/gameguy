#!/usr/bin/env python3
"""Clips for Morgan's ears, cut from the game's own sound (spec/promises/rules.md, rules.ears).

The build plays the first evening with the scripted player and keeps its sound
(build/evening.wav, 48,000 Hz, one channel, 16-bit) and its log (build/evening.out), where the
scripted player's marks are written as "mark NAME at step N". Each clip here is a stretch of that
sound around a mark, with a fade at each end, and one question. They are written into
design/listen/ beside the sketches, and listed in its README, so the room plays them.

    python3 -I game/tools/clips.py          # from the repository's root, after game/build.sh
"""
import os
import re
import struct
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BUILD = os.path.join(ROOT, 'game', 'build')
LISTEN = os.path.join(ROOT, 'design', 'listen')
SAMPLES_PER_STEP = 800
RATE = 48000

# name, the mark it is cut round, seconds before and after the mark, what it is, the question
CLIPS = [
    ('32-water-sings-back', 'pool', 14.0, 1.0,
     'Hum hums at the edge of the bridge puddle; the water comes up in a ring and a cross and sings Hum\'s note back, about 4 dB louder as it stands',
     'did the note bloom nicely as the water stood, or was it too much, or too little?'),
    ('33-the-bee', 'bee', 4.0, 8.0,
     'the bee working the clover a little way ahead of Hum, its hum the garden\'s note, falling as it goes by',
     'does the bee sound like a bee you would want near you?'),
    ('34-underfoot', 'foot', 15.0, 0.0,
     'walking to the great aster over lawn and fallen leaves: dew ticks behind Hum, leaves ring underfoot in the garden\'s scale',
     'pleasant to walk through, or fussy?'),
    ('35-wonder', 'wonder', 12.0, 1.0,
     'home moved to wonder, the F below; Hum hums at the puddle sized for it, and it stands and sings F back',
     'does home on wonder sound like another place than sunny home?'),
    ('36-the-amen', 'swell', 6.0, 9.0,
     'the swell, Gentle: Hum holds its note and never touches the stick; after a bar home drifts up a fifth beside the grey knots, and Hum lets go on the next downbeat: the amen lands, a chord from Hum, the knots sigh and settle asleep, and the garden answers',
     'does letting go on the one feel like landing somewhere?'),
    ('37-placed-then-timed', 'placed', 0.5, 6.0,
     'a strike pressed well off the beat, which the game places on the next beat, its note alone; then the downbeat struck on time by the hands, its note with its octave, and the knots ringing harder',
     'does the strike you time yourself sound like more power than the one the game placed?'),
    ('38-the-hose-opens', 'open', 6.0, 12.0,
     'the hose stopped by its knot hums low and hollow, odd overtones only, from wherever you are; the knots settle and it springs open: an octave up, every overtone back, and the water runs down it and pours into the pool',
     'did the hose sound like the same pipe, opened?'),
    ('39-a-stalk-brushed', 'brush', 0.5, 6.5,
     'Hum runs at the great aster and brushes its stalk: a short low knock where it touched, and the aster\'s bells ringing softly far overhead, each arriving when its sound has come down',
     'did brushing the stalk sound like touching something that belongs to the bells?'),
]


def marks():
    out = {}
    path = os.path.join(BUILD, 'evening.out')
    for line in open(path, encoding='utf-8', errors='replace'):
        m = re.match(r'mark (\S+) at step (\d+)', line)
        if m:
            out.setdefault(m.group(1), int(m.group(2)))
    return out


def cut(samples, start, end):
    start = max(0, start)
    end = min(len(samples), end)
    part = list(samples[start:end])
    fade = int(0.03 * RATE)
    for i in range(min(fade, len(part))):
        k = i / fade
        part[i] = int(part[i] * k)
        part[-1 - i] = int(part[-1 - i] * k)
    return part


def main():
    found = marks()
    src = wave.open(os.path.join(BUILD, 'evening.wav'))
    if src.getframerate() != RATE or src.getnchannels() != 1 or src.getsampwidth() != 2:
        sys.exit('the evening\'s sound is not 48,000 Hz, one channel, 16-bit')
    raw = src.readframes(src.getnframes())
    samples = struct.unpack('<%dh' % (len(raw) // 2), raw)
    rows = []
    for name, mark, before, after, what, question in CLIPS:
        if mark not in found:
            print(f'{name}: the mark "{mark}" is not in the evening\'s log; not cut')
            continue
        at = found[mark] * SAMPLES_PER_STEP
        part = cut(samples, at - int(before * RATE), at + int(after * RATE))
        path = os.path.join(LISTEN, name + '.wav')
        out = wave.open(path, 'wb')
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(struct.pack('<%dh' % len(part), *part))
        out.close()
        loudest = max(abs(v) for v in part) / 32768.0 if part else 0.0
        print(f'{name}: {len(part) / RATE:.1f} s from step {found[mark]}, loudest {loudest:.2f}')
        rows.append(f'| {name} | {what} | {question} |')
    # list them in the README, under their own heading, replacing an older list
    readme = os.path.join(LISTEN, 'README.md')
    text = open(readme, encoding='utf-8').read()
    heading = '## From the game itself (clips 32 on)'
    block = (heading + '\n\nCut from the first evening as the scripted player plays it, by `game/tools/clips.py`: the game\'s\n'
             'own sound at 48,000 Hz, not a sketch. Rebuilt whenever the evening changes.\n\n'
             '| clip | what it is | the question |\n|---|---|---|\n' + '\n'.join(rows) + '\n')
    if heading in text:
        start = text.index(heading)
        nxt = text.find('\n## ', start + len(heading))
        text = text[:start] + block + (text[nxt:] if nxt != -1 else '')
    else:
        text = text.rstrip('\n') + '\n\n' + block
    open(readme, 'w', encoding='utf-8').write(text)


if __name__ == '__main__':
    main()
