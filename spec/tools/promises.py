#!/usr/bin/env python3
"""The promise book's keeper (spec/promises.md).

    python3 -I spec/tools/promises.py              read every claim, check every promise, write the board
    python3 -I spec/tools/promises.py --show ID    one promise and each of its rungs
    python3 -I spec/tools/promises.py --open [N]   the claims no promise speaks for yet (of stage N)
    python3 -I spec/tools/promises.py --packet N   write what a fresh reader needs to grade stage N
    python3 -I spec/tools/promises.py --zig FILE   write the list of witnessed promises for the game
    python3 -I spec/tools/promises.py --room FILE  write the walk's list for the room

Nobody lists the claims. The tool reads every sentence of the specification's game documents
(CLAIM_FILES below) as a claim, so a line written tomorrow is on the board tomorrow. A promise in
spec/promises/ speaks for the sentences it quotes. Then the tool reads what today's build proved
(game/build/), what the handhelds logged (game/results/), which frames were looked at
(spec/promises/seen/) and what a fresh reader graded (spec/promises/graded.md), and works out
every rung from that evidence. It exits with 1 if it has to refuse something.
"""
import hashlib
import glob
import os
import re
import struct
import sys
import zlib

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
PROMISES = os.path.join(ROOT, 'spec', 'promises')
BUILD = os.path.join(ROOT, 'game', 'build')

LAND_STAGE = [2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4]

# Every sentence in these is a claim. (file, first section, last section): None means all of it.
CLAIM_FILES = [
    ('SPEC.md', '4.', '15.'),
    ('spec/laws.md', None, None),
    ('spec/world.md', None, None),
    ('spec/people.md', None, None),
    ('spec/size.md', None, None),
    ('spec/years.md', None, None),
    ('spec/together.md', None, None),
]

# Sections that are about the documents or about other games, not promises to a player.
SKIP_SECTIONS = [
    ('spec/size.md', 'What it is measured against'), ('spec/size.md', 'Still to be measured'), ('spec/size.md', 'Sources'),
    ('spec/years.md', 'What a small world known by heart does'), ('spec/years.md', 'What stays Morgan'),
    ('spec/together.md', 'What is measured'), ('spec/together.md', 'What it never leans on'),
]

# The stage that owes a section, until a promise that quotes a sentence says otherwise. The first
# rule whose file matches and whose words begin a heading on the sentence's path wins.
STAGE_RULES = [
    ('SPEC.md', '6.3', 3), ('SPEC.md', '6.4', 5), ('SPEC.md', '6.5', 5), ('SPEC.md', '12.', 3),
    ('SPEC.md', '14.', 6), ('SPEC.md', '', 2),
    ('spec/laws.md', '', 2),
    ('spec/world.md', 'The shape', 2), ('spec/world.md', 'What every land has', 2),
    ('spec/world.md', 'The lake', 3), ('spec/world.md', 'The Seam', 3), ('spec/world.md', 'The sky', 5),
    ('spec/world.md', 'The deep', 5), ('spec/world.md', 'After the thirteenth', 5),
    ('spec/world.md', 'The calendar', 5),
    ('spec/people.md', 'How a life works', 2), ('spec/people.md', 'The ones who go with you', 3),
    ('spec/people.md', 'The one who remembers', 3), ('spec/people.md', 'The travellers', 3),
    ('spec/people.md', "The ones that aren't people", 3), ('spec/people.md', "The lands' eights", 2),
    ('spec/people.md', 'Left blank', 2), ('spec/people.md', 'On the thirteenth', 5),
    ('spec/size.md', 'What the card', 2), ('spec/size.md', '', 2),
    ('spec/years.md', 'Generations', 5), ('spec/years.md', 'The great year', 5), ('spec/years.md', '', 3),
    ('spec/together.md', '', 6),
]
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
        self.said = []  # (file, quote)
        self.scene = self.moment = self.cheat = self.asks = ''
        self.far = self.foot = self.inside = self.after = ''
        self.measures = []  # (kind, spec, words)
        self.sized_entry = False


# ------------------------------------------------------------------ reading the promises

def parse_said(text):
    """`FILE` "words" "more words" `OTHER` "words": a list of (file, quote)."""
    out, path = [], ''
    for m in re.finditer(r'`([^`]+)`|"((?:[^"\\]|\\.)*)"', text, re.S):
        if m.group(1) is not None:
            path = m.group(1).strip()
        elif path:
            out.append((path, m.group(2)))
    return out


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
        p.said = parse_said(get('said'))
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


class Claim:
    def __init__(self, path, where, text, n):
        self.file, self.where, self.text = path, where, text
        key = os.path.basename(path).split('.')[0].lower()
        self.id = f'{key}.{hashlib.sha1(text.encode()).hexdigest()[:6]}'
        self.order = n
        self.stage = 0
        self.promises = []


def split_sentences(text):
    """Sentences, never broken inside double quotes, with a short one joined to its neighbour."""
    out, cur, quoted = [], '', False
    for i, ch in enumerate(text):
        cur += ch
        if ch == '"':
            quoted = not quoted
        if ch in '.!?' and not quoted:
            rest = text[i + 1:i + 3]
            ends = i + 1 == len(text) or (len(rest) == 2 and rest[0] == ' ' and (rest[1].isupper() or rest[1] in '"(['))
            if ends and not re.search(r'\b(No|e\.g|i\.e|vs)\.$', cur):
                out.append(cur.strip())
                cur = ''
    if cur.strip():
        out.append(cur.strip())
    joined = []
    carry = ''
    for s in out:
        s = (carry + ' ' + s).strip() if carry else s
        carry = ''
        if len(s.split()) < 4:
            carry = s
        else:
            joined.append(s)
    if carry:
        if joined:
            joined[-1] += ' ' + carry
        else:
            joined.append(carry)
    return joined


def is_pointer(sentence):
    """A sentence that only points at another document, or only introduces a list."""
    words = len(sentence.split())
    return ('.md' in sentence and words <= 16) or (sentence.endswith(':') and words < 7)


def read_claims():
    claims = []
    lands_in = {'spec/world.md': -1, 'spec/people.md': -1}
    for path, first, last in CLAIM_FILES:
        try:
            lines = read(path).split('\n')
        except OSError:
            continue
        heads = []       # the path of headings down to here
        inside = first is None
        code = False
        block = None     # (kind, text)
        table_rows = 0
        skipping = False

        def flush():
            nonlocal block
            if block is None:
                return
            kind, text = block
            block = None
            if text.lstrip().startswith('_'):
                return
            # a bold lead is the name of what follows: it stays with the first sentence
            lead = re.match(r'^\*\*(.+?)\*\*\s*(.*)$', text.strip(), re.S)
            title = ''
            if lead and kind != 'row':
                title, text = plain(lead.group(1)), lead.group(2)
            text = plain(text)
            where = ' / '.join(heads)
            if kind == 'row':
                parts = [text] if text else []
            else:
                parts = split_sentences(text)
                if title and parts:
                    parts[0] = f'{title} {parts[0]}'
                elif title and len(title.split()) >= 4:
                    parts = [title]  # a name with nothing after it is a label unless it says something
            for s in parts:
                if not is_pointer(s) and len(s) > 3:
                    claims.append(Claim(path, where, s, len(claims)))

        for raw in lines:
            if raw.strip().startswith('```'):
                flush()
                code = not code
                continue
            if code:
                continue
            head = re.match(r'^(#+)\s+(.*)$', raw)
            if head:
                flush()
                level = len(head.group(1))
                heads = heads[:level - 1] + [plain(head.group(2))]
                if level == 2:
                    skipping = any(f == path and plain(head.group(2)).startswith(words) for f, words in SKIP_SECTIONS)
                if first is not None and level == 2:
                    title = plain(head.group(2))
                    if title.startswith(first):
                        inside = True
                    elif inside and not any(title.startswith(f'{n}.') for n in range(int(first[:-1]), int(last[:-1]) + 1)):
                        inside = False
                table_rows = 0
                continue
            if not inside or skipping:
                continue
            if not raw.strip():
                flush()
                table_rows = 0
                continue
            if raw.lstrip().startswith('|'):
                flush()
                table_rows += 1
                cells = [c.strip() for c in raw.strip().strip('|').split('|')]
                if table_rows <= 2 and (table_rows == 1 or set(''.join(cells)) <= set('-: ')):
                    continue  # the heading row and the rule under it
                if set(''.join(cells)) <= set('-: '):
                    continue
                block = ('row', ' | '.join(c for c in cells if c))
                flush()
                continue
            table_rows = 0
            item = re.match(r'^\s*(?:[-*]|\d+\.)\s+(.*)$', raw)
            if item:
                flush()
                block = ('item', item.group(1))
            elif raw.startswith('_') and block is None:
                block = ('note', raw)
            elif block is None:
                block = ('para', raw.strip())
            else:
                block = (block[0], block[1] + ' ' + raw.strip())
        flush()
    for c in claims:
        c.stage = stage_of(c)
    return claims


_land_order = {}


def stage_of(claim):
    # a land's own section, in the atlas or among the people, is owed by that land's stage
    top = claim.where.split(' / ')
    if claim.file == 'spec/world.md' and len(top) > 1:
        m = re.match(r'^(\d+)\. ', top[1])
        if m and 1 <= int(m.group(1)) <= 12:
            return LAND_STAGE[int(m.group(1)) - 1]
    if claim.file == 'spec/people.md' and len(top) > 2 and top[1].startswith("The lands' eights"):
        order = _land_order.setdefault('people', [])
        if top[2] not in order:
            order.append(top[2])
        i = order.index(top[2])
        if i < 12:
            return LAND_STAGE[i]
    for path, words, stage in STAGE_RULES:
        if path == claim.file and (words == '' or any(h.startswith(words) for h in top)):
            return stage
    refusals.append(f'{claim.file}: the section "{claim.where}" has no stage (STAGE_RULES in spec/tools/promises.py)')
    return 0


def atlas_counts():
    """The atlas says twelve lands, twelve great instruments, 144 wonders and 96 lives."""
    world = read('spec/world.md')
    people = read('spec/people.md')
    lands = len(re.findall(r'^## \d+\. ', world, re.M))
    greats = len(re.findall(r'^\*\*Its great instrument: ', world, re.M))
    body = world[:world.index('## The lake')] if '## The lake' in world else world
    wonders = len(re.findall(r'^\d+\. \*\*', body, re.M))
    eights = people[people.index("## The lands' eights"):] if "## The lands' eights" in people else ''
    eights = eights[:eights.index('\n## ', 5)] if '\n## ' in eights[5:] else eights
    lives = len([row for row in re.findall(r'^\| (.+?) \|', eights, re.M) if row.strip() != 'who' and not set(row.strip()) <= set('-')])
    for name, have, want in (('lands', lands, 12), ('great instruments', greats, 12), ('wonders', wonders, 144), ('lives', lives, 96)):
        if have != want:
            refusals.append(f'the atlas has {have} {name} where the specification says {want}')


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
    r.said = bool(p.claims) and p.said_ok
    r.sized = bool(p.moment and p.cheat and p.measures and p.asks)
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

def claim_state(c, rungs):
    """'kept' when every promise that quotes it is kept, 'answered' when one quotes it, else 'open'."""
    if not c.promises:
        return 'open'
    return 'kept' if all(rungs[p.id].kept for p in c.promises) else 'answered'


def main():
    args = sys.argv[1:]
    promises = []
    for path in sorted(glob.glob(os.path.join(PROMISES, '*.md'))):
        if os.path.basename(path) in ('seen.md', 'graded.md', 'BOARD.md', 'CLAIMS.md'):
            continue
        promises += read_sized(path)
    by_id = {}
    for p in promises:
        if p.id in by_id:
            refusals.append(f'two promises are called `{p.id}`')
        by_id[p.id] = p

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
                if p.scene and p.asks and not p.asks.lower().startswith('nobody')]
        open(out, 'w', encoding='utf-8').write('\n'.join(rows) + '\n')
        return 0

    # every sentence of the specification, and which promises speak for it
    claims = read_claims()
    atlas_counts()
    by_file = {}
    for c in claims:
        by_file.setdefault(c.file, []).append(c)
    for p in promises:
        p.claims, p.said_ok = [], bool(p.said)
        if not p.said:
            refusals.append(f'`{p.id}` in {p.source} quotes nothing from the specification')
        for path, quote in p.said:
            q = plain(quote)
            hits = [c for c in by_file.get(path, []) if q in c.text]
            if not hits:
                p.said_ok = False
                refusals.append(f'`{p.id}` quotes words that no sentence of {path} holds: "{q[:70]}"')
            for c in hits:
                if p not in c.promises:
                    c.promises.append(p)
                    p.claims.append(c)
        if not (p.moment and p.cheat and p.measures and p.asks):
            missing = [n for n, v in (('the moment', p.moment), ('a cheat', p.cheat), ('full size', p.measures), ('asks', p.asks)) if not v]
            refusals.append(f'`{p.id}` is in {p.source} without {", ".join(missing)}')

    facts, witness = read_facts()
    hands = read_handhelds(facts)
    tests = read_tests()
    seen_rows = read_table('spec/promises/seen.md', 3)
    graded = read_table('spec/promises/graded.md', 4)
    stages = read_stages()
    rungs = {p.id: weigh(p, facts, witness, tests, seen_rows, hands, graded) for p in promises}
    state = {c.id: claim_state(c, rungs) for c in claims}

    for stage, word in sorted(stages.items()):
        mine = [p for p in promises if p.stage == stage]
        owed = [c for c in claims if c.stage == stage]
        if word in ('begun', 'done'):
            unsized = [p.id for p in mine if not rungs[p.id].sized]
            if unsized:
                refusals.append(f'stage {stage} is marked {word} in PROGRESS.md while {len(unsized)} of its promises are not sized: ' + ', '.join(unsized[:8]))
            unanswered = [c for c in owed if state[c.id] == 'open']
            if unanswered:
                refusals.append(f'stage {stage} is marked {word} in PROGRESS.md while {len(unanswered)} of its claims have no promise that speaks for them. '
                                f'The first: "{unanswered[0].text[:80]}" ({unanswered[0].file}). All of them: --open {stage}')
        if word == 'done':
            unkept = [p.id for p in mine if not rungs[p.id].kept]
            if unkept:
                refusals.append(f'stage {stage} is marked done in PROGRESS.md while {len(unkept)} of its promises are not kept: ' + ', '.join(unkept[:8]))
            loose = [c for c in owed if state[c.id] != 'kept']
            if loose:
                refusals.append(f'stage {stage} is marked done in PROGRESS.md while {len(loose)} of its claims are not kept')

    if '--show' in args:
        pid = args[args.index('--show') + 1]
        p = by_id.get(pid)
        if p is None:
            print(f'no promise is called {pid}')
            return 1
        r = rungs[pid]
        print(f'{p.id}: {p.title}   (stage {p.stage}; {p.source})')
        print(f'  speaks for {len(p.claims)} sentences:')
        for c in p.claims:
            print(f'            {c.file}: {c.text[:110]}')
        print(f'  sized   {mark(r.sized)}')
        print(f'  proven  {mark(r.proven)}')
        for ok, text in r.lines:
            print(f'            [{"x" if ok else " "}] {text}')
        print(f'  reached {mark(r.reached)}')
        print(f'  felt    {mark(r.felt)}   ' + ('; '.join(f'{who}: {v[0]} ({v[2]})' for who, v in r.hands.items()) or ('asks: ' + p.asks)))
        print(f'  graded  {mark(r.graded)}')
        print(f'  KEPT    {mark(r.kept)}')
        return 0

    if '--open' in args:
        i = args.index('--open')
        only = int(args[i + 1]) if i + 1 < len(args) and args[i + 1].isdigit() else None
        last = None
        n = 0
        for c in claims:
            if state[c.id] != 'open' or (only is not None and c.stage != only):
                continue
            here = f'{c.file} / {c.where}'
            if here != last:
                print(f'\n{here}   (stage {c.stage})')
                last = here
            print(f'  {c.id}  {c.text}')
            n += 1
        print(f'\n{n} claims with no promise that speaks for them')
        return 0

    if '--packet' in args:
        stage = int(args[args.index('--packet') + 1])
        out = os.path.join(BUILD, f'grade-stage-{stage}.md')
        b = [f'# Grading packet, stage {stage}', '', "You are grading a game against its own promises. You have not seen its code and you won't.",
             'For each promise below: read its words, its moment and its cheat; look at its frames and its numbers;',
             'then say whether this is the promise at full size, the cheat, or something between. Say what a person',
             'holding the handheld would feel, and name the weakest thing. Give one verdict: full, short (by how much,',
             'and why), or cheat. You are looking for shrink. Do not be kind.', '']
        for p in promises:
            if p.stage != stage:
                continue
            r = rungs[p.id]
            b += [f'## `{p.id}` {p.title}', '', 'The specification says:']
            b += [f'- {c.text}' for c in p.claims]
            b += ['', f'The moment: {p.moment}', '', f'A cheat would be: {p.cheat}', '', 'Its measures today:']
            b += [f'- [{"x" if ok else " "}] {text}' for ok, text in r.lines]
            frames = [spec for kind, spec, _ in p.measures if kind == 'frame']
            if frames:
                b += ['', 'Frames: ' + ', '.join(f'spec/promises/seen/{f}.png' for f in frames)]
            b += ['', f'It asks a person: {p.asks}', '']
        os.makedirs(BUILD, exist_ok=True)
        open(out, 'w', encoding='utf-8').write('\n'.join(b))
        print(out)
        return 0

    # the board
    n = len(claims)
    count_c = lambda s: sum(1 for c in claims if state[c.id] == s)
    count = lambda f: sum(1 for p in promises if f(rungs[p.id]))
    b = ['# The board', '',
         '_Where every claim and every promise stands today. `spec/tools/promises.py` writes this on every',
         'build. It reads each sentence of the specification as a claim, so nobody lists them, and it works',
         'out each rung from what the build proved, what the handhelds logged and what was looked at, so',
         'nobody types one in. What the words mean is in `../promises.md`. Every claim is in `CLAIMS.md`._', '',
         '## Claims: every sentence a player is promised', '',
         '| | sentences |', '|---|---|',
         f'| in the specification | {n} |',
         f'| a promise speaks for it | {n - count_c("open")} |',
         f'| **kept** | **{count_c("kept")}** |',
         f'| no promise speaks for it yet | {count_c("open")} |', '',
         '| stage | claims | spoken for | kept | open |', '|---|---|---|---|---|']
    for stage in sorted({c.stage for c in claims}):
        mine = [c for c in claims if c.stage == stage]
        b.append(f'| {stage} | {len(mine)} | {sum(1 for c in mine if state[c.id] != "open")} | '
                 f'{sum(1 for c in mine if state[c.id] == "kept")} | {sum(1 for c in mine if state[c.id] == "open")} |')
    b += ['', '| document | claims | spoken for | kept |', '|---|---|---|---|']
    for path, _, _ in CLAIM_FILES:
        mine = by_file.get(path, [])
        if mine:
            b.append(f'| `{path}` | {len(mine)} | {sum(1 for c in mine if state[c.id] != "open")} | {sum(1 for c in mine if state[c.id] == "kept")} |')
    b += ['', '## Promises: what speaks for the claims', '',
          '| rung | promises |', '|---|---|',
          f'| sized: its moment, its cheat, its full size and its question written | {count(lambda r: r.sized)} of {len(promises)} |',
          f'| proven: every measure passes today and nothing is owed | {count(lambda r: r.proven)} |',
          f'| reached: the scripted player met it by playing | {count(lambda r: r.reached)} |',
          f'| felt: Morgan, holding the handheld, answered yes | {count(lambda r: r.felt)} |',
          f'| graded full by a fresh reader | {count(lambda r: r.graded)} |',
          f'| **kept** | **{count(lambda r: r.kept)}** |', '']
    walk = [p for p in promises if p.scene and rungs[p.id].asked]
    b += ['## Waiting for hands', '',
          'On the handheld, in the room (Ports, GameguyRoom), the walk puts a person in each of these and',
          'asks its question.', '',
          '| promise | it asks | answers so far |', '|---|---|---|']
    for p in walk:
        r = rungs[p.id]
        said = '; '.join(f'{who}: {v[0]}' for who, v in sorted(r.hands.items())) or 'none'
        b.append(f'| `{p.id}` {p.title} | {p.asks} | {said} |')
    b += ['', '## Every promise', '',
          '| promise | stage | speaks for | proven | reached | felt | graded | kept | what stands in the way |', '|---|---|---|---|---|---|---|---|---|']
    for p in promises:
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
        b.append(f'| `{p.id}` {p.title} | {p.stage} | {len(p.claims)} | {mark(r.proven)} | {mark(r.reached)} | {mark(r.felt)} | {mark(r.graded)} | '
                 f'{"**yes**" if r.kept else "no"} | {"; ".join(way)} |')
    b.append('')
    text = '\n'.join(b)
    board = os.path.join(PROMISES, 'BOARD.md')
    if not os.path.exists(board) or open(board, encoding='utf-8').read() != text:
        open(board, 'w', encoding='utf-8').write(text)

    # every claim
    k = ['# Every claim', '',
         '_Every sentence of the specification that promises a player something, read by',
         '`spec/tools/promises.py`: nobody lists these. **kept**: every promise that quotes it is kept.',
         '**spoken for**: a promise quotes it. **open**: no promise speaks for it yet._']
    last = None
    for c in claims:
        here = f'`{c.file}` / {c.where}'
        if here != last:
            k += ['', f'## {here}', '']
            last = here
        word = {'kept': '**kept**', 'answered': 'spoken for', 'open': 'open'}[state[c.id]]
        who = (' by ' + ', '.join(f'`{p.id}`' for p in c.promises)) if c.promises else ''
        k.append(f'- {word}{who}: {c.text}')
    k.append('')
    text = '\n'.join(k)
    path = os.path.join(PROMISES, 'CLAIMS.md')
    if not os.path.exists(path) or open(path, encoding='utf-8').read() != text:
        open(path, 'w', encoding='utf-8').write(text)

    print(f'claims: {n} sentences, {n - count_c("open")} spoken for by a promise, {count_c("kept")} kept, {count_c("open")} open')
    print(f'promises: {len(promises)} sized, {count(lambda r: r.proven)} proven, {count(lambda r: r.reached)} reached, '
          f'{count(lambda r: r.felt)} felt, {count(lambda r: r.graded)} graded, {count(lambda r: r.kept)} kept')
    for line in notes:
        print('  note: ' + line)
    for line in refusals:
        print('  REFUSED: ' + line)
    return 1 if refusals else 0


if __name__ == '__main__':
    sys.exit(main())
