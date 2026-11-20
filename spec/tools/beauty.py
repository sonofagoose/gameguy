#!/usr/bin/env python3
"""The rules of a beautiful frame, summed over the frames a build kept (spec/texture.md).

    python3 -I spec/tools/beauty.py game/build/facts.txt

The game measures each frame it keeps for a promise as it dumps it: how much of the screen is
black and how much is brighter than half. This prints the least black of the frames on the page,
the least black of the frames in the place, and the most bright of all of them, as facts.
"""
import re
import sys

PAGE = ('black', 'page', 'drip', 'figure', 'locked')
seen = {}
for line in open(sys.argv[1], encoding='utf-8'):
    m = re.match(r'^fact beauty\.(\S+)\.(black|bright) ([0-9.]+)$', line.strip())
    if m:
        seen.setdefault(m.group(1), {})[m.group(2)] = float(m.group(3))
page = [v['black'] for k, v in seen.items() if 'black' in v and k.split('-', 1)[-1] in PAGE]
place = [v['black'] for k, v in seen.items() if 'black' in v and k.split('-', 1)[-1] not in PAGE]
bright = [v['bright'] for v in seen.values() if 'bright' in v]
if page:
    print(f"fact beauty.page_black_least {min(page):.4f}")
if place:
    print(f"fact beauty.place_black_least {min(place):.4f}")
if bright:
    print(f"fact beauty.bright_most {max(bright):.4f}")
