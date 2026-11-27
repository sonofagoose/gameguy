#!/usr/bin/env python3
"""Turn a land's score into its tables, plus inspect budgets and export top-down maps
(spec/engine.md, "Places and scores"; ROADMAP.md, "The Workbench & Cohesion Guard").

    python3 -I tools/score.py scores/garden.txt src/world/land.zig
    python3 -I tools/score.py scores/garden.txt --inspect [--map out.png]
    python3 -I tools/score.py scores/garden.txt src/world/land.zig --inspect --map out.png

A score is a text file, one thing to a line: a word saying what it is, then its numbers and named
numbers. A note is written as a ratio over the land's own note (4/3). The tables are a Zig file the
world reads when it begins, every number written as the score gives it, so the same score always
makes the same world on every machine. Nothing in the output is computed here: a ratio is written
as its numerator and denominator, or as the division the code always made, so its rounding is
exactly what it was.
"""
import math
import os
import struct
import sys
import zlib


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
        elif what in ('pool', 'rim'):
            n = named(rest[2:], line_no)
            land[what] = (number(rest[0], line_no), number(rest[1], line_no), number(n['radius'][0], line_no), number(n['reeds'][0], line_no) if 'reeds' in n else '0.0')
        elif what == 'bowl':
            n = named(rest, line_no)
            land['bowl'] = (number(n['depth'][0], line_no), number(n['beds'][0], line_no))
        elif what == 'rise':
            n = named(rest[2:], line_no)
            land['rise'] = (number(rest[0], line_no), number(rest[1], line_no), number(n['height'][0], line_no), number(n['across'][0], line_no))
        elif what == 'spigot':
            land['spigot'] = (number(rest[0], line_no), number(rest[1], line_no), number(named(rest[2:], line_no)['tall'][0], line_no))
        elif what == 'hose' and rest and rest[0][0].isalpha():
            n = named(rest, line_no)
            land['hose_bore'] = number(n['bore'][0], line_no)
            land['hose_knot'] = number(n['knot'][0], line_no)
        elif what == 'hose':
            pts = []
            for part in ' '.join(rest).split('/'):
                xz = part.split()
                if len(xz) != 2:
                    fail(line_no, f'a point of the hose is two numbers, not {part.strip()}')
                pts.append((number(xz[0], line_no), number(xz[1], line_no)))
            land['hose'] = pts
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
    for need in ('note', 'wake', 'great', 'clear', 'lake', 'asters', 'knot_root', 'pool', 'rim', 'spigot', 'hose', 'hose_bore', 'bowl', 'rise'):
        if need not in land:
            sys.exit(f'score: {path} says nothing of its {need}')
    for need in ('wake', 'great', 'clear', 'puddle', 'pool', 'hose', 'spigot'):
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
        f'pub const keep_pool: f32 = {k["pool"]};',
        f'pub const keep_hose: f32 = {k["hose"]};',
        f'pub const keep_spigot: f32 = {k["spigot"]};',
        '/// The Mirror Pool: its middle, its radius, and the band of reeds round it.',
        f'pub const pool = [4]f32{{ {", ".join(land["pool"])} }};',
        '/// The bowl\'s rim: its middle and radius.',
        f'pub const rim = [3]f32{{ {", ".join(land["rim"][:3])} }};',
        '/// The bowl\'s ground: how far it rises from the pool to the rim, and the beds above that.',
        f'pub const bowl_depth: f32 = {land["bowl"][0]};',
        f'pub const bowl_beds: f32 = {land["bowl"][1]};',
        '/// The spigot\'s rise: where, how high above the rim, how far across.',
        f'pub const rise = [4]f32{{ {", ".join(land["rise"])} }};',
        '/// The spigot: where, and how tall.',
        f'pub const spigot = [3]f32{{ {", ".join(land["spigot"])} }};',
        '/// The hose: the points its curve passes through, from the spigot to its end; its bore; how far',
        '/// back from its end it is knotted.',
        'pub const hose = [_][2]f32{',
        *[f'    .{{ {x}, {z} }},' for x, z in land['hose']],
        '};',
        f'pub const hose_bore: f32 = {land["hose_bore"]};',
        f'pub const hose_knot: f32 = {land["hose_knot"]};',
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


# ------------------------------------------------------------ Place Inspector & Top-Down Map


def _hose_length(pts):
    total = 0.0
    for i in range(1, len(pts)):
        dx = float(pts[i][0]) - float(pts[i - 1][0])
        dz = float(pts[i][1]) - float(pts[i - 1][1])
        total += math.hypot(dx, dz)
    return total


def _hose_dist(pts, x, z):
    best = 1e18
    for i in range(1, len(pts)):
        ax, az = float(pts[i - 1][0]), float(pts[i - 1][1])
        bx, bz = float(pts[i][0]), float(pts[i][1])
        dx, dz = bx - ax, bz - az
        l2 = dx * dx + dz * dz
        t = max(0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / l2)) if l2 > 0 else 0.0
        d = math.hypot(x - (ax + dx * t), z - (az + dz * t))
        if d < best:
            best = d
    return best


def _hose_back_from_end(pts, dist_back):
    rem = dist_back
    for i in range(len(pts) - 1, 0, -1):
        ax, az = float(pts[i - 1][0]), float(pts[i - 1][1])
        bx, bz = float(pts[i][0]), float(pts[i][1])
        seg = math.hypot(bx - ax, bz - az)
        if rem <= seg and seg > 1e-6:
            t = rem / seg
            return bx + (ax - bx) * t, bz + (az - bz) * t
        rem -= seg
    return float(pts[0][0]), float(pts[0][1])


def _aster_positions(land):
    """Mirror world/asters.zig `field()` layout from the score's AsterRule and keep-outs."""
    a = land['asters']
    cells = int(a['cells'])
    across = float(a['across'])
    from_z = float(a['from'])
    jitter = float(a['jitter'])
    skip = int(a['skip'])
    seed = int(a['seed'], 0)
    rim_x, rim_z, rim_r = float(land['rim'][0]), float(land['rim'][1]), float(land['rim'][2])
    pool_x, pool_z, pool_r, reeds_w = [float(v) for v in land['pool']]
    wake_x, wake_z = float(land['wake'][0]), float(land['wake'][1])
    great_x, great_z = float(land['great'][0]), float(land['great'][1])
    clear_x, clear_z = float(land['clear'][0]), float(land['clear'][1])
    spig_x, spig_z = float(land['spigot'][0]), float(land['spigot'][1])
    k = {key: float(val) for key, val in land['keep'].items()}
    puddles = [(float(p[0]), float(p[1])) for p in land['puddles']]

    def rng_u32(s):
        s = (s ^ ((s << 13) & 0xFFFFFFFF)) & 0xFFFFFFFF
        s = (s ^ (s >> 17)) & 0xFFFFFFFF
        s = (s ^ ((s << 5) & 0xFFFFFFFF)) & 0xFFFFFFFF
        return s

    pts = [(great_x, great_z)]
    s = seed
    cell = across / max(cells, 1)
    pool_keep = pool_r + reeds_w + k['pool']
    for iz in range(cells):
        for ix in range(cells):
            cx = -across * 0.5 + (ix + 0.5) * cell
            cz = from_z - (iz + 0.5) * cell
            s = rng_u32(s)
            ux = (s >> 8) / 16777216.0
            s = rng_u32(s)
            uz = (s >> 8) / 16777216.0
            s = rng_u32(s)  # tall
            s = rng_u32(s)  # skip
            if skip > 0 and (s % skip) == 0:
                continue
            x = cx + (ux - 0.5) * jitter
            z = cz + (uz - 0.5) * jitter
            if math.hypot(x - rim_x, z - rim_z) > rim_r:
                continue
            if math.hypot(x - pool_x, z - pool_z) < pool_keep:
                continue
            if math.hypot(x - wake_x, z - wake_z) < k['wake']:
                continue
            if math.hypot(x - great_x, z - great_z) < k['great']:
                continue
            if math.hypot(x - clear_x, z - clear_z) < k['clear']:
                continue
            if math.hypot(x - spig_x, z - spig_z) < k['spigot']:
                continue
            if _hose_dist(land['hose'], x, z) < k['hose']:
                continue
            if any(math.hypot(x - px, z - pz) < (50.0 + k['puddle']) for px, pz in puddles):
                continue
            pts.append((x, z))
    return pts


def inspect(land, src):
    rim_r = float(land['rim'][2])
    pool_r = float(land['pool'][2])
    reeds_band = float(land['pool'][3])
    bowl_depth = float(land['bowl'][0])
    rise_h = float(land['rise'][2])
    hose_len = _hose_length(land['hose'])
    asters = _aster_positions(land)
    diam = rim_r * 2.0
    run_cross = diam / 12.0
    sprint_cross = diam / 20.0
    wake_to_great = math.hypot(float(land['great'][0]) - float(land['wake'][0]), float(land['great'][1]) - float(land['wake'][1]))
    wake_to_clear = math.hypot(float(land['clear'][0]) - float(land['wake'][0]), float(land['clear'][1]) - float(land['wake'][1]))

    # Conservative Mali-G31 peak estimate from measured Garden ratios (docs/engine.md)
    est_lines = 14500 + len(asters) * 95 + len(land['puddles']) * 220 + int(hose_len * 2.2)
    est_black = 3200 + len(asters) * 38 + int(hose_len * 2.0)

    print(f'=== PLACE INSPECTOR: {src} ===')
    print(f'  Note:        {float(land["note"]):.2f} Hz')
    print(f'  Bowl:        diameter {diam:.0f} m (rim r={rim_r:.0f} m), pool r={pool_r:.0f} m (+{reeds_band:.0f} m reeds)')
    print(f'  Elevation:   bowl {bowl_depth:.0f} m + spigot rise {rise_h:.0f} m = {bowl_depth + rise_h:.0f} m span')
    print(f'  Travel time: across bowl {run_cross:.0f} s @ 12 m/s run ({sprint_cross:.0f} s @ 20 m/s sprint)')
    print(f'  Key sights:  wake->Drip {wake_to_clear:.0f} m ({wake_to_clear/12.0:.1f} s), wake->great {wake_to_great:.0f} m ({wake_to_great/12.0:.1f} s), hose ~{hose_len:.0f} m')
    print(f'  Entities:    ~{len(asters)} asters, {len(land["puddles"])} puddles, {len(land["knots"])} knots, {len(land["hose"])} hose pts')
    line_flag = 'OK' if est_lines <= 24000 else 'WATCH (over 24k target)'
    tri_flag = 'OK' if est_black <= 12000 else 'WATCH (over 12k target)'
    print(f'  Mali-G31 est: ~{est_lines:,} lines / 24,000 [{line_flag}]  |  ~{est_black:,} black tris / 12,000 [{tri_flag}]')


def _write_png(path, width, height, rgb_bytes):
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF)

    raw = bytearray()
    stride = width * 3
    for y in range(height):
        raw.append(0)
        raw.extend(rgb_bytes[y * stride:(y + 1) * stride])
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(bytes(raw), 6)) + chunk(b'IEND', b'')
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(path, 'wb') as f:
        f.write(png)


def render_map(land, out_path, size=512):
    """Render a crisp top-down PNG layout preview using Python stdlib only."""
    buf = bytearray([10, 12, 16] * (size * size))
    rim_x, rim_z, rim_r = float(land['rim'][0]), float(land['rim'][1]), float(land['rim'][2])
    span = rim_r * 2.25
    scale = (size - 32) / span
    cx0, cz0 = rim_x, rim_z

    def to_px(wx, wz):
        return int(round(size * 0.5 + (wx - cx0) * scale)), int(round(size * 0.5 + (wz - cz0) * scale))

    def put(x, y, col, alpha=1.0):
        if 0 <= x < size and 0 <= y < size:
            i = (y * size + x) * 3
            if alpha >= 0.999:
                buf[i], buf[i + 1], buf[i + 2] = col
            else:
                inv = 1.0 - alpha
                buf[i] = int(buf[i] * inv + col[0] * alpha)
                buf[i + 1] = int(buf[i + 1] * inv + col[1] * alpha)
                buf[i + 2] = int(buf[i + 2] * inv + col[2] * alpha)

    def circle_fill(wx, wz, wr, col, alpha=1.0):
        px, py = to_px(wx, wz)
        pr = max(1, int(round(wr * scale)))
        r2 = pr * pr
        for dy in range(-pr, pr + 1):
            for dx in range(-pr, pr + 1):
                if dx * dx + dy * dy <= r2:
                    put(px + dx, py + dy, col, alpha)

    def circle_ring(wx, wz, wr, col, thick=1.5):
        px, py = to_px(wx, wz)
        pr = max(2, int(round(wr * scale)))
        steps = max(48, int(pr * 6.5))
        for i in range(steps):
            a = 2.0 * math.pi * i / steps
            x = int(round(px + pr * math.cos(a)))
            y = int(round(py + pr * math.sin(a)))
            r_t = int(thick)
            for oy in range(-r_t, r_t + 1):
                for ox in range(-r_t, r_t + 1):
                    if ox * ox + oy * oy <= thick * thick:
                        put(x + ox, y + oy, col)

    def line(x0, y0, x1, y1, col, thick=1):
        steps = max(1, int(math.hypot(x1 - x0, y1 - y0) * 1.5))
        for i in range(steps + 1):
            t = i / steps
            x = int(round(x0 + (x1 - x0) * t))
            y = int(round(y0 + (y1 - y0) * t))
            for oy in range(-thick, thick + 1):
                for ox in range(-thick, thick + 1):
                    put(x + ox, y + oy, col)

    # 100 m subtle grid
    for g in range(-800, 900, 100):
        gx, _ = to_px(g, 0)
        _, gz = to_px(0, g)
        for p in range(16, size - 16):
            put(gx, p, (28, 34, 42), 0.35)
            put(p, gz, (28, 34, 42), 0.35)

    # Bowl interior, rim, reed band, Mirror Pool, spigot rise
    circle_fill(rim_x, rim_z, rim_r, (18, 24, 22), 0.85)
    circle_ring(rim_x, rim_z, rim_r, (150, 140, 120), 1.6)
    px, pz, pr, reeds_w = [float(v) for v in land['pool']]
    circle_fill(px, pz, pr + reeds_w, (38, 72, 56), 0.55)
    circle_fill(px, pz, pr, (22, 68, 92), 0.95)
    circle_ring(px, pz, pr, (64, 210, 200), 1.4)

    rx, rz, _, ra = [float(v) for v in land['rise']]
    circle_fill(rx, rz, ra * 0.5, (90, 68, 42), 0.35)

    # Asters
    for ax, az in _aster_positions(land)[1:]:
        circle_fill(ax, az, 9.0, (92, 185, 115), 0.78)

    # Puddles (cyan/teal)
    for pud in land['puddles']:
        circle_fill(float(pud[0]), float(pud[1]), 14.0, (55, 205, 225), 0.9)

    # Hose polyline (bright green)
    hpts = [to_px(float(x), float(z)) for x, z in land['hose']]
    for i in range(1, len(hpts)):
        line(hpts[i - 1][0], hpts[i - 1][1], hpts[i][0], hpts[i][1], (115, 245, 130), 1)

    # Knots (amber), placed relative to the hose's knot point
    hkx, hkz = _hose_back_from_end(land['hose'], float(land['hose_knot']))
    for kx, kz in land['knots']:
        circle_fill(hkx + float(kx), hkz + float(kz), 11.0, (255, 175, 65), 0.95)

    # Key landmarks: Great Aster (gold ring), Spigot (orange), Drip clearing (teal), Wake (bone)
    gx, gz = float(land['great'][0]), float(land['great'][1])
    circle_fill(gx, gz, 16.0, (255, 235, 130), 0.95)
    circle_ring(gx, gz, 26.0, (255, 235, 130), 1.4)

    sx, sz = float(land['spigot'][0]), float(land['spigot'][1])
    circle_fill(sx, sz, 15.0, (255, 145, 70), 0.95)

    cx, cz = float(land['clear'][0]), float(land['clear'][1])
    circle_fill(cx, cz, 12.0, (65, 225, 210), 0.95)

    wx, wz = float(land['wake'][0]), float(land['wake'][1])
    circle_fill(wx, wz, 11.0, (245, 238, 224), 1.0)
    circle_ring(wx, wz, 20.0, (245, 238, 224), 1.2)

    # 100 m scale bar at bottom-left + North arrow at top-left
    bar_px = int(round(100.0 * scale))
    line(20, size - 22, 20 + bar_px, size - 22, (235, 225, 205), 2)
    line(20, size - 27, 20, size - 17, (235, 225, 205), 1)
    line(20 + bar_px, size - 27, 20 + bar_px, size - 17, (235, 225, 205), 1)
    # North arrow
    line(28, 42, 28, 18, (235, 225, 205), 1)
    line(28, 18, 22, 26, (235, 225, 205), 1)
    line(28, 18, 34, 26, (235, 225, 205), 1)

    _write_png(out_path, size, size, buf)
    print(f'  Map written: {out_path} ({size}x{size}, 100 m bar = {bar_px} px)')


if __name__ == '__main__':
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    src = args[0]
    out_zig = None
    do_inspect = False
    map_out = None
    i = 1
    while i < len(args):
        if args[i] == '--inspect':
            do_inspect = True
            i += 1
        elif args[i] == '--map' and i + 1 < len(args):
            map_out = args[i + 1]
            i += 2
        elif out_zig is None and not args[i].startswith('--'):
            out_zig = args[i]
            i += 1
        else:
            sys.exit(__doc__)

    land_data = read(src)
    if out_zig is not None:
        write(land_data, src, out_zig)
    if do_inspect:
        inspect(land_data, src)
    if map_out is not None:
        render_map(land_data, map_out)
    if out_zig is None and not do_inspect and map_out is None:
        sys.exit(__doc__)
