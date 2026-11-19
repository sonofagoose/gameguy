#!/usr/bin/env python3
"""The promise book's keeper (spec/promises.md).

    python3 -I spec/tools/promises.py              check every promise and write the board
    python3 -I spec/tools/promises.py --show ID    one promise and each of its rungs
    python3 -I spec/tools/promises.py --zig FILE   write the list of witnessed promises for the game
    python3 -I spec/tools/promises.py --room FILE  write the walk's list for the room

It reads the promises (spec/promises/*.md and the atlas), then what today's build proved
(game/build/), what the handhelds logged (game/results/), which frames were looked at
(spec/promises/seen/) and what a fresh reader graded (spec/promises/graded.md). It exits with 1
if it has to refuse something. Nothing here is typed in by hand as "done": every rung is worked
out from evidence.
"""
import glob
import os
import re
import struct
import sys
import zlib

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
PROMISES = os.path.join(ROOT, 'spec', 'promises')
BUILD = os.path.join(ROOT, 'game', 'build')

LANDS = ['garden', 'alfalfa', 'glass', 'bell', 'highway', 'chrome', 'seam', 'steps', 'verbena',
         'rain', 'reeds', 'porch']
LAND_STAGE = [2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4]
FIELDS = {
    'said': 'said', 'stage': 'stage', 'scene': 'scene', 'the moment': 'moment', 'far': 'far',
    'at its foot': 'foot', 'inside': 'inside', 'after': 'after', 'a cheat would be': 'cheat',
    'full size': 'full', 'asks': 'asks',
}
MEASURES = ('fact', 'test', 'take', 'frame', 'owed')
refusals = []
notes = []


def read(path):
    with open(os.path.join(ROOT, path), encoding='utf-8') as f:
        return f.read()


def plain(text):
    """Text as it is said: no emphasis marks, no line breaks."""
    return re.sub(r'\s+', ' ', re.sub(r'[*`]', '', text)).strip()


_plain_cache = {}


def said_in(path, quote):
    if path not in _plain_cache:
        try:
            _plain_cache[path] = plain(read(path))
        except OSError:
            _plain_cache[path] = None
    text = _plain_cache[path]
    return text is not None and plain(quote) in text


def slug(name):
    return re.sub(r'[^a-z0-9]+', '-', name.lower().replace('the ', '', 1) if name.lower().startswith('the ') else name.lower()).strip('-')


class Promise:
    def __init__(self, pid, title, source):
        self.id, self.title, self.source = pid, title, source
        self.stage = 0
        self.said_file = self.said_quote = ''
        self.scene = self.moment = self.cheat = self.asks = ''
        self.far = self.foot = self.inside = self.after = ''
        self.measures = []  # (kind, spec, words)
        self.sized_entry = False


# ------------------------------------------------------------------ reading the promises

def parse_said(text):
    m = re.match(r'\s*`?([^`"]+?)`?\s+"(.+)"\s*$', text, re.S)
    return (m.group(1).strip(), m.group(2)) if m else ('', '')


def read_sized(path):
    out = []
    cur = field = None
    name = os.path.relpath(path, ROOT)
    for raw in open(path, encoding='utf-8').read().split('\n'):
        head = re.match(r'^### `([a-z0-9.\-]+)` (.+)$', raw)
        if head:
            cur = Promise(head.group(1), head.group(2).strip(), name)
            cur.sized_entry = True
            cur.raw = {}
            out.append(cur)
            field = None
            continue
        if cur is None or raw.startswith('#'):
            if raw.startswith('#'):
                cur = None
            continue
        top = re.match(r'^- \*\*(.+?):\*\*\s*(.*)$', raw)
        if top:
            key = FIELDS.get(top.group(1).strip().lower())
            if key is None:
                refusals.append(f'{name}: `{cur.id}` has a field nobody knows: "{top.group(1)}"')
                field = None
                continue
            field = key
            cur.raw[field] = [top.group(2)]
            continue
        if field and raw.strip():
            sub = re.match(r'^  - (.*)$', raw)
            if field == 'full' and sub:
                cur.raw[field].append('\x00' + sub.group(1))
            else:
                cur.raw[field].append(raw.strip())
    for p in out:
        raw = p.raw
        get = lambda k: ' '.join(raw.get(k, [])).strip()
        p.said_file, p.said_quote = parse_said(get('said'))
        try:
            p.stage = int(get('stage'))
        except ValueError:
            refusals.append(f'{p.source}: `{p.id}` has no stage')
        p.scene, p.moment, p.cheat, p.asks = get('scene'), get('moment'), get('cheat'), get('asks')
        p.far, p.foot, p.inside, p.after = get('far'), get('foot'), get('inside'), get('after')
        items, buf = [], None
        for line in raw.get('full', []):
            if line.startswith('\x00'):
                if buf is not None:
                    items.append(buf)
                buf = line[1:]
            elif buf is not None:
                buf += ' ' + line
        if buf is not None:
            items.append(buf)
        for item in items:
            m = re.match(r'^`([a-z]+)(?: ([^`]*))?`\s*(.*)$', item)
            if not m or m.group(1) not in MEASURES:
                refusals.append(f'{p.source}: `{p.id}` has a measure nobody knows: "{item[:60]}"')
                continue
            p.measures.append((m.group(1), (m.group(2) or '').strip(), m.group(3).strip()))
    return out


def read_said_table():
    out = []
    for line in read('spec/promises/said.md').split('\n'):
        m = re.match(r'^\| `([a-z0-9.\-]+)` \| (\d+) \| (.+?) \| (.+?) \|\s*$', line)
        if not m:
            continue
        p = Promise(m.group(1), m.group(4).strip(), 'spec/promises/said.md')
        p.stage = int(m.group(2))
        p.said_file, p.said_quote = parse_said(m.group(3))
        out.append(p)
    return out


def read_atlas():
    """Lands, great instruments and wonders from world.md; lives from people.md."""
    out = []
    counts = {'land': 0, 'great': 0, 'wonder': 0, 'life': 0}
    land = -1
    for line in read('spec/world.md').split('\n'):
        head = re.match(r'^## (\d+)\. (The .+?|[A-Z].+?) \(', line)
        if head:
            land = int(head.group(1)) - 1
            p = Promise(f'{LANDS[land]}.land', head.group(2), 'spec/world.md')
            p.stage, p.said_file, p.said_quote = LAND_STAGE[land], 'spec/world.md', line[3:].strip()
            out.append(p)
            counts['land'] += 1
            continue
        if line.startswith('## ') and not re.match(r'^## \d+\.', line):
            if land >= 0 and counts['land'] == 12:
                land = -2  # past the twelve lands
            continue
        if land < 0:
            continue
        great = re.match(r'^\*\*Its great instrument: (.+?)\.\*\*', line)
        if great:
            p = Promise(f'{LANDS[land]}.great', great.group(1)[0].upper() + great.group(1)[1:], 'spec/world.md')
            p.stage, p.said_file, p.said_quote = LAND_STAGE[land], 'spec/world.md', f'Its great instrument: {great.group(1)}.'
            out.append(p)
            counts['great'] += 1
            continue
        wonder = re.match(r'^(\d+)\. \*\*(.+?)\.\*\*', line)
        if wonder:
            p = Promise(f'{LANDS[land]}.w{int(wonder.group(1)):02d}', wonder.group(2), 'spec/world.md')
            p.stage, p.said_file, p.said_quote = LAND_STAGE[land], 'spec/world.md', wonder.group(2) + '.'
            out.append(p)
            counts['wonder'] += 1
    land = -1
    seen_ids = set()
    for line in read('spec/people.md').split('\n'):
        if line.startswith('### '):
            land += 1 if land < 11 and re.match(r'^### The .+?: ', line) else 0
            continue
        if line.startswith('## ') and land >= 0 and not line.startswith('## The lands'):
            land = 99
        if not (0 <= land < 12):
            continue
        row = re.match(r'^\| (.+?) \| (.+?) \|', line)
        if not row or row.group(1).strip() in ('who', '---') or set(row.group(1).strip()) <= set('-'):
            continue
        who = row.group(1).strip()
        pid = f'{LANDS[land]}.{slug(who)}'
        if pid in seen_ids:
            pid += '-2'
        seen_ids.add(pid)
        p = Promise(pid, who[0].upper() + who[1:], 'spec/people.md')
        p.stage, p.said_file, p.said_quote = LAND_STAGE[land], 'spec/people.md', f'{who} | {row.group(2).strip()}'
        out.append(p)
        counts['life'] += 1
    want = {'land': 12, 'great': 12, 'wonder': 144, 'life': 96}
    for kind, n in want.items():
        if counts[kind] != n:
            refusals.append(f'the atlas has {counts[kind]} {kind} entries where the specification says {n}')
    return out


# ------------------------------------------------------------------ reading the evidence

def read_facts():
    facts, witness = {}, {}
    for name in ('same-take-x86_64.txt', 'facts.txt'):
        path = os.path.join(BUILD, name)
        if not os.path.exists(path):
            continue
        for line in open(path, encoding='utf-8', errors='replace'):
            m = re.match(r'^fact (\S+) (-?[0-9.]+)\s*$', line)
            if m:
                facts[m.group(1)] = float(m.group(2))
            m = re.match(r'^witness (\S+) first=(\d+) held=(\d+)', line)
            if m:
                witness[m.group(1)] = (int(m.group(2)), int(m.group(3)))
    return facts, witness


def read_handhelds(facts):
    """The newest line of each kind in the logs the handhelds left, and every answer in the room."""
    hands = {}  # id -> {who: (verdict, where)}
    logs = sorted(glob.glob(os.path.join(ROOT, 'game', 'results', '**', '*.txt'), recursive=True))
    for path in logs:
        where = os.path.relpath(path, ROOT)
        for line in open(path, encoding='utf-8', errors='replace'):
            for scene in ('dark', 'asters'):
                m = re.search(rf'the {scene}: (\d+) frames, (\d+) late.*?slowest sound buffer ([0-9.]+) ms', line)
                if m and int(m.group(1)) >= 600:
                    facts[f'handheld.{scene}.frames'] = float(m.group(1))
                    facts[f'handheld.{scene}.late'] = float(m.group(2))
                    facts[f'handheld.{scene}.sound_ms'] = float(m.group(3))
            m = re.search(r'room: promise (\S+) (yes|no) by (\w+)(.*)$', line)
            if m:
                hands.setdefault(m.group(1), {})[m.group(3)] = (m.group(2), where, m.group(4).strip(' ;'))
    return hands


def read_tests():
    names = set()
    for path in glob.glob(os.path.join(ROOT, 'game', '**', '*.zig'), recursive=True):
        if os.sep + 'build' + os.sep in path:
            continue
        for m in re.finditer(r'^test "(.+?)"', open(path, encoding='utf-8').read(), re.M):
            names.add(m.group(1))
    return names


def read_table(path, columns):
    rows = []
    full = os.path.join(ROOT, path)
    if not os.path.exists(full):
        return rows
    for line in open(full, encoding='utf-8'):
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if len(cells) >= columns and not set(cells[0]) <= set('-') and cells[0] not in ('frame', 'id'):
            rows.append(cells)
    return rows


def png_pixels(path):
    data = open(path, 'rb').read()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        return None
    pos, idat, w = 8, b'', 0
    while pos < len(data):
        n, kind = struct.unpack('>I4s', data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        if kind == b'IHDR':
            w, h, depth, colour, _, _, lace = struct.unpack('>IIBBBBB', body)
            if depth != 8 or colour not in (2, 6) or lace:
                return None
            bpp = 3 if colour == 2 else 4
        elif kind == b'IDAT':
            idat += body
        pos += 12 + n
    raw = zlib.decompress(idat)
    stride = w * bpp
    out = bytearray()
    prev = bytearray(stride)
    for y in range(h):
        f = raw[y * (stride + 1)]
        line = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        if f == 1:
            for i in range(bpp, stride):
                line[i] = (line[i] + line[i - bpp]) & 255
        elif f == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 255
        elif f == 3:
            for i in range(stride):
                left = line[i - bpp] if i >= bpp else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 255
        elif f == 4:
            for i in range(stride):
                a = line[i - bpp] if i >= bpp else 0
                b = prev[i]
                c = prev[i - bpp] if i >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        out += line if bpp == 3 else bytes(v for i, v in enumerate(line) if i % 4 != 3)
        prev = line
    return (w, h, bytes(out))


def frame_state(name, seen_rows):
    """'ok', or why not."""
    kept = os.path.join(PROMISES, 'seen', name + '.png')
    today = os.path.join(BUILD, 'frames', 'promise-' + name + '.png')
    if not os.path.exists(kept) or not any(r[0].strip('`') == name for r in seen_rows):
        return 'nobody has looked at it yet'
    if not os.path.exists(today):
        return "today's build has not dumped it"
    a, b = png_pixels(kept), png_pixels(today)
    if a is None or b is None or a[:2] != b[:2]:
        return 'it can not be compared with the copy that was looked at'
    if a[2] == b[2]:
        return 'ok'
    diff = sum(abs(x - y) for x, y in zip(a[2], b[2])) / len(a[2])
    return 'ok' if diff <= 1.5 else f'it has changed since it was looked at (by {diff:.1f} of 255 a channel)'


def read_stages():
    states = {}
    for line in read('PROGRESS.md').split('\n'):
        m = re.match(r'^\| (\d)\. .+? \| (.+?) \|\s*$', line)
        if m:
            word = m.group(2).strip().lower()
            states[int(m.group(1))] = 'not started' if word.startswith('not') else 'done' if word.startswith('done') else 'begun'
    return states


# ------------------------------------------------------------------ the rungs

class Rungs:
    pass


def weigh(p, facts, witness, tests, seen_rows, hands, graded):
    r = Rungs()
    r.said = said_in(p.said_file, p.said_quote) if p.said_file else False
    r.sized = bool(p.sized_entry and p.moment and p.cheat and p.measures and p.asks)
    r.lines = []  # (ok or None, text)
    r.owed = 0
    r.takes = False
    proven = True
    reached = None
    for kind, spec, words in p.measures:
        if kind == 'owed':
            r.owed += 1
            proven = False
            r.lines.append((False, 'owed: ' + words))
        elif kind == 'test':
            ok = spec in tests
            if not ok:
                refusals.append(f'`{p.id}` names a test that does not exist: "{spec}"')
            proven &= ok
            r.lines.append((ok, f'test "{spec}"'))
        elif kind == 'fact':
            m = re.match(r'^(\S+) (>=|<=|==) (-?[0-9.]+)$', spec)
            if not m:
                refusals.append(f'`{p.id}` has a fact nobody can read: "{spec}"')
                proven = False
                continue
            have = facts.get(m.group(1))
            want = float(m.group(3))
            ok = have is not None and ((m.group(2) == '>=' and have >= want) or (m.group(2) == '<=' and have <= want)
                                       or (m.group(2) == '==' and abs(have - want) < 1e-6))
            proven &= ok
            shown = 'not reported' if have is None else f'{have:g}'
            r.lines.append((ok, f'{spec}  (is {shown})'))
        elif kind == 'frame':
            state = frame_state(spec, seen_rows)
            ok = state == 'ok'
            proven &= ok
            r.lines.append((ok, f'frame {spec}' + ('' if ok else f': {state}')))
        elif kind == 'take':
            r.takes = True
            got = witness.get(p.id)
            reached = got is not None
            r.lines.append((reached, 'take: ' + (f'met at step {got[0]}, stayed {got[1] / 60:.1f} s' if got else 'the scripted player did not meet it')))
    r.proven = r.sized and proven
    r.reached = reached  # None: nothing to reach by playing
    r.asked = bool(p.asks) and not p.asks.lower().startswith('nobody')
    r.hands = hands.get(p.id, {})
    r.felt = (r.hands.get('morgan', ('',))[0] == 'yes') if r.asked else None
    verdicts = [g for g in graded if g[0].strip('`') == p.id]
    r.graded = bool(verdicts) and verdicts[-1][3].lower().startswith('full')
    r.kept = bool(r.said and r.sized and r.proven and r.reached is not False and r.felt is not False and r.graded)
    return r


def mark(v):
    return 'yes' if v else '-' if v is None else 'no'


# ------------------------------------------------------------------ main

def main():
    args = sys.argv[1:]
    sized = []
    for path in sorted(glob.glob(os.path.join(PROMISES, '*.md'))):
        if os.path.basename(path) in ('said.md', 'seen.md', 'graded.md', 'BOARD.md'):
            continue
        sized += read_sized(path)
    listed = read_said_table() + read_atlas()
    by_id = {}
    for p in sized:
        if p.id in by_id:
            refusals.append(f'two promises are called `{p.id}`')
        by_id[p.id] = p
    order = [p.id for p in sized]
    for p in listed:
        if p.id in by_id:
            if not by_id[p.id].sized_entry:
                refusals.append(f'two promises are called `{p.id}`')
            continue
        by_id[p.id] = p
        order.append(p.id)
    promises = [by_id[i] for i in order]

    if '--zig' in args:
        out = args[args.index('--zig') + 1]
        ids = [p.id for p in promises if any(k == 'take' for k, _, _ in p.measures)]
        lines = ['//! The promises the world itself must witness. Written by spec/tools/promises.py from',
                 '//! spec/promises/: do not edit. A promise is here because its full size has a `take` line.',
                 'pub const Id = enum(u16) {']
        lines += [f'    {i.replace(".", "_").replace("-", "_")},' for i in ids]
        lines += ['};', '', 'pub const names = [_][]const u8{']
        lines += [f'    "{i}",' for i in ids]
        lines += ['};', '']
        text = '\n'.join(lines)
        if not os.path.exists(out) or open(out, encoding='utf-8').read() != text:
            open(out, 'w', encoding='utf-8').write(text)
        return 0

    if '--room' in args:
        out = args[args.index('--room') + 1]
        rows = [f'{p.id}|{p.scene}|{p.title}|{p.asks}' for p in promises
                if p.sized_entry and p.scene and p.asks and not p.asks.lower().startswith('nobody')]
        open(out, 'w', encoding='utf-8').write('\n'.join(rows) + '\n')
        return 0

    facts, witness = read_facts()
    hands = read_handhelds(facts)
    tests = read_tests()
    seen_rows = read_table('spec/promises/seen.md', 3)
    graded = read_table('spec/promises/graded.md', 4)
    stages = read_stages()

    rungs = {}
    for p in promises:
        if not p.said_file or not said_in(p.said_file, p.said_quote):
            refusals.append(f'`{p.id}` quotes words that are not in {p.said_file or "any file"}: "{plain(p.said_quote)[:70]}"')
        if p.sized_entry and not (p.moment and p.cheat and p.measures and p.asks):
            missing = [n for n, v in (('the moment', p.moment), ('a cheat', p.cheat), ('full size', p.measures), ('asks', p.asks)) if not v]
            refusals.append(f'`{p.id}` is in {p.source} without {", ".join(missing)}')
        rungs[p.id] = weigh(p, facts, witness, tests, seen_rows, hands, graded)

    for stage, state in sorted(stages.items()):
        mine = [p for p in promises if p.stage == stage]
        if state in ('begun', 'done'):
            unsized = [p.id for p in mine if not rungs[p.id].sized]
            if unsized:
                refusals.append(f'stage {stage} is marked {state} in PROGRESS.md while {len(unsized)} of its promises are not sized: '
                                + ', '.join(unsized[:8]) + (' ...' if len(unsized) > 8 else ''))
        if state == 'done':
            unkept = [p.id for p in mine if not rungs[p.id].kept]
            if unkept:
                refusals.append(f'stage {stage} is marked done in PROGRESS.md while {len(unkept)} of its promises are not kept: '
                                + ', '.join(unkept[:8]) + (' ...' if len(unkept) > 8 else ''))

    if '--show' in args:
        pid = args[args.index('--show') + 1]
        p = by_id.get(pid)
        if p is None:
            print(f'no promise is called {pid}')
            return 1
        r = rungs[pid]
        print(f'{p.id}: {p.title}   (stage {p.stage}; {p.source})')
        print(f'  said    {mark(r.said)}   {p.said_file} "{plain(p.said_quote)}"')
        print(f'  sized   {mark(r.sized)}')
        print(f'  proven  {mark(r.proven)}')
        for ok, text in r.lines:
            print(f'            [{"x" if ok else " "}] {text}')
        print(f'  reached {mark(r.reached)}')
        print(f'  felt    {mark(r.felt)}   ' + ('; '.join(f'{who}: {v[0]} ({v[2]})' for who, v in r.hands.items()) or ('asks: ' + p.asks)))
        print(f'  graded  {mark(r.graded)}')
        print(f'  KEPT    {mark(r.kept)}')
        return 0

    # the board
    n = len(promises)
    count = lambda f: sum(1 for p in promises if f(rungs[p.id]))
    b = ['# The board', '',
         '_Where every promise stands today. `spec/tools/promises.py` writes this on every build from',
         "what the build proved, what the handhelds logged and what was looked at: nobody types a rung",
         'in. What the rungs mean is in `../promises.md`._', '',
         '| rung | promises |', '|---|---|',
         f'| said: in the specification and on the list | {count(lambda r: r.said)} of {n} |',
         f'| sized: its moment, its cheat, its full size and its question written | {count(lambda r: r.sized)} |',
         f'| proven: every measure passes today and nothing is owed | {count(lambda r: r.proven)} |',
         f'| reached: the scripted player met it by playing | {count(lambda r: r.reached)} |',
         f'| felt: Morgan, holding the handheld, answered yes | {count(lambda r: r.felt)} |',
         f'| graded full by a fresh reader | {count(lambda r: r.graded)} |',
         f'| **kept** | **{count(lambda r: r.kept)}** |', '']
    walk = [p for p in promises if p.sized_entry and p.scene and rungs[p.id].asked]
    b += ['## Waiting for hands', '',
          'On the handheld, in the room (Ports, GameguyRoom), the walk puts a person in each of these and',
          'asks its question.', '',
          '| promise | it asks | answers so far |', '|---|---|---|']
    for p in walk:
        r = rungs[p.id]
        said = '; '.join(f'{who}: {v[0]}' for who, v in sorted(r.hands.items())) or 'none'
        b.append(f'| `{p.id}` {p.title} | {p.asks} | {said} |')
    b += ['', '## The sized promises', '',
          '| promise | stage | proven | reached | felt | graded | kept | what stands in the way |', '|---|---|---|---|---|---|---|---|']
    for p in promises:
        if not p.sized_entry:
            continue
        r = rungs[p.id]
        failing = [text for ok, text in r.lines if ok is False and not text.startswith('owed')]
        way = []
        if r.owed:
            way.append(f'{r.owed} owed')
        way += failing[:2]
        if r.asked and not r.felt:
            way.append('no yes from Morgan yet' if 'morgan' not in r.hands else 'Morgan said no')
        if r.proven and not r.graded:
            way.append('not graded')
        b.append(f'| `{p.id}` {p.title} | {p.stage} | {mark(r.proven)} | {mark(r.reached)} | {mark(r.felt)} | {mark(r.graded)} | '
                 f'{"**yes**" if r.kept else "no"} | {"; ".join(way)} |')
    b += ['', '## Said, and waiting to be sized', '', '| stage | promises | of which |', '|---|---|---|']
    for stage in sorted({p.stage for p in promises}):
        rest = [p for p in promises if p.stage == stage and not p.sized_entry]
        if not rest:
            continue
        kinds = {}
        for p in rest:
            tail = p.id.split('.', 1)[1]
            kind = ('wonders' if re.match(r'^w\d\d$', tail) else 'great instruments' if tail == 'great' else 'lands' if tail == 'land'
                    else 'lives' if p.source.endswith('people.md') else 'other')
            kinds[kind] = kinds.get(kind, 0) + 1
        b.append(f'| {stage} | {len(rest)} | ' + ', '.join(f'{v} {k}' for k, v in sorted(kinds.items())) + ' |')
    b.append('')
    text = '\n'.join(b)
    board = os.path.join(PROMISES, 'BOARD.md')
    if not os.path.exists(board) or open(board, encoding='utf-8').read() != text:
        open(board, 'w', encoding='utf-8').write(text)

    print(f'promises: {n} said, {count(lambda r: r.sized)} sized, {count(lambda r: r.proven)} proven, '
          f'{count(lambda r: r.reached)} reached, {count(lambda r: r.felt)} felt, {count(lambda r: r.graded)} graded, '
          f'{count(lambda r: r.kept)} kept')
    for line in notes:
        print('  note: ' + line)
    for line in refusals:
        print('  REFUSED: ' + line)
    return 1 if refusals else 0


if __name__ == '__main__':
    sys.exit(main())
