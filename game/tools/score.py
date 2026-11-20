#!/usr/bin/env python3
"""Turn a land's score into its tables (spec/engine.md, "Places and scores").

    python3 -I tools/score.py scores/garden.txt src/world/land.zig

A score is a text file, one thing to a line: a word saying what it is, then its numbers and named
numbers. A note is written as a ratio over the land's own note (4/3). The tables are a Zig file the
world reads when it begins, every number written as the score gives it, so the same score always
makes the same world on every machine. Nothing in the output is computed here: a ratio is written
as its numerator and denominator, or as the division the code always made, so its rounding is
exactly what it was.
"""
import sys


def fail(line_no, text):
    sys.exit(f'score, line {line_no}: {text}')


def number(word, line_no):
    """A number as Zig should read it: a float literal with its point, or a whole hex number."""
    if word.startswith('0x'):
        int(word, 16)
        return word
    try:
        float(word)
    except ValueError:
        fail(line_no, f'not a number: {word}')
    return word if ('.' in word or 'e' in word) else word + '.0'


def ratio(word, line_no):
    """A ratio like 4/3, as its numerator and denominator, each a float literal."""
    if '/' not in word:
        return number(word, line_no), '1.0'
    a, b = word.split('/', 1)
    return number(a, line_no), number(b, line_no)


def named(words, line_no):
    """The named numbers after a line's first words: `tall 92 76` gives tall: ['92', '76']."""
    out = {}
    key = None
    for w in words:
        if w[0].isalpha() and not w.startswith('0x'):
            key = w
            out[key] = []
        elif key is None:
            fail(line_no, f'a number with no name: {w}')
        else:
            out[key].append(w)
    return out


def read(path):
    land = {'puddles': [], 'knots': [], 'keep': {}}
    for line_no, raw in enumerate(open(path, encoding='utf-8'), 1):
        line = raw.split('#', 1)[0].strip()
        if not line:
            continue
        words = line.split()
        what, rest = words[0], words[1:]
        if what == 'note':
            land['note'] = number(rest[0], line_no)
        elif what in ('wake', 'clear', 'lake'):
            land[what] = (number(rest[0], line_no), number(rest[1], line_no))
        elif what == 'great':
            land['great'] = (number(rest[0], line_no), number(rest[1], line_no))
            land['great_tall'] = number(named(rest[2:], line_no)['tall'][0], line_no)
        elif what == 'asters':
            n = named(rest, line_no)
            land['asters'] = {
                'across': number(n['across'][0], line_no),
                'cells': str(int(n['cells'][0])),
                'from': number(n['from'][0], line_no),
                'jitter': number(n['jitter'][0], line_no),
                'tall_least': number(n['tall'][0], line_no),
                'tall_more': number(n['tall'][1], line_no),
                'skip': str(int(n['skip'][0])),
                'seed': n['seed'][0],
            }
        elif what == 'keep':
            land['keep'][rest[0]] = number(rest[1], line_no)
        elif what == 'puddle':
            n = named(rest[2:], line_no)
            note = None
            if 'note' in n:
                a, b = ratio(n['note'][0], line_no)
                note = f'{a} / {b}'
            land['puddles'].append((number(rest[0], line_no), number(rest[1], line_no), str(int(n['shape'][0])), note))
        elif what == 'knot':
            land['knots'].append((number(rest[0], line_no), number(rest[1], line_no)))
        elif what == 'knots':
            root = None
            strands = []
            i = 0
            while i < len(rest):
                if rest[i] == 'root':
                    root = ratio(rest[i + 1], line_no)
                    i += 2
                elif rest[i] == 'strand':
                    strands.append((*ratio(rest[i + 1], line_no), str(int(rest[i + 2]))))
                    i += 3
                else:
                    fail(line_no, f'a knot has a root and strands, not {rest[i]}')
            land['knot_root'] = root
            land['knot_strands'] = strands
        else:
            fail(line_no, f'nothing in a score is called {what}')
    for need in ('note', 'wake', 'great', 'clear', 'lake', 'asters', 'knot_root'):
        if need not in land:
            sys.exit(f'score: {path} says nothing of its {need}')
    for need in ('wake', 'great', 'clear', 'puddle'):
        if need not in land['keep']:
            sys.exit(f'score: {path} says nothing of how far the asters keep from the {need}')
    return land


def write(land, src, out):
    a = land['asters']
    k = land['keep']
    lines = [
        f'//! The land\'s tables, written by tools/score.py from {src}: do not edit. Change the',
        '//! score and build again (spec/engine.md, "Places and scores").',
        '',
        'pub const Puddle = struct { x: f32, z: f32, shape: u8, note: f32 = 1.0 };',
        '/// A knot\'s strand: its note over the land\'s, as a numerator and a denominator, and how many',
        '/// times it pulses to the knot\'s cycle.',
        'pub const Strand = struct { num: f32, den: f32, over: u8 };',
        'pub const AsterRule = struct { across: f32, cells: u32, from: f32, jitter: f32, tall_least: f32, tall_more: f32, skip: u32, seed: u32 };',
        '',
        f'pub const note: f32 = {land["note"]};',
        f'pub const wake = [2]f32{{ {land["wake"][0]}, {land["wake"][1]} }};',
        f'pub const great = [2]f32{{ {land["great"][0]}, {land["great"][1]} }};',
        f'pub const great_tall: f32 = {land["great_tall"]};',
        f'pub const clear = [2]f32{{ {land["clear"][0]}, {land["clear"][1]} }};',
        f'pub const lake = [2]f32{{ {land["lake"][0]}, {land["lake"][1]} }};',
        f'pub const aster_rule = AsterRule{{ .across = {a["across"]}, .cells = {a["cells"]}, .from = {a["from"]}, .jitter = {a["jitter"]}, .tall_least = {a["tall_least"]}, .tall_more = {a["tall_more"]}, .skip = {a["skip"]}, .seed = {a["seed"]} }};',
        f'pub const keep_wake: f32 = {k["wake"]};',
        f'pub const keep_great: f32 = {k["great"]};',
        f'pub const keep_clear: f32 = {k["clear"]};',
        f'pub const keep_puddle: f32 = {k["puddle"]};',
        'pub const puddles = [_]Puddle{',
    ]
    for x, z, shape, note in land['puddles']:
        extra = f', .note = {note}' if note else ''
        lines.append(f'    .{{ .x = {x}, .z = {z}, .shape = {shape}{extra} }},')
    lines.append('};')
    lines.append('pub const knots = [_][2]f32{')
    for x, z in land['knots']:
        lines.append(f'    .{{ {x}, {z} }},')
    lines.append('};')
    r = land['knot_root']
    lines.append(f'pub const knot_root = [2]f32{{ {r[0]}, {r[1]} }};')
    lines.append('pub const knot_strands = [_]Strand{')
    for num, den, over in land['knot_strands']:
        lines.append(f'    .{{ .num = {num}, .den = {den}, .over = {over} }},')
    lines.append('};')
    text = '\n'.join(lines) + '\n'
    try:
        if open(out, encoding='utf-8').read() == text:
            return
    except FileNotFoundError:
        pass
    open(out, 'w', encoding='utf-8').write(text)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    write(read(sys.argv[1]), sys.argv[1], sys.argv[2])
