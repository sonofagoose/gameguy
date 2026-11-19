#!/usr/bin/env python3
"""Wrap markdown prose to 100 columns. Usage: wrapmd.py SRC DEST
Each paragraph or list item is one long line in SRC. Tables, headings, images, code blocks and
blank lines pass through. List items wrap with a hanging indent."""
import re, sys, textwrap
src, dest = sys.argv[1], sys.argv[2]
out, code = [], False
for line in open(src, encoding='utf-8').read().split('\n'):
    if line.strip().startswith('```'):
        code = not code
        out.append(line)
        continue
    if code or not line.strip() or line.lstrip().startswith(('|', '#', '![')):
        out.append(line)
        continue
    if line.startswith('>'):
        if line.strip() == '>':
            out.append('>')
            continue
        body = line[2:] if line.startswith('> ') else line[1:]
        out.extend(textwrap.wrap(body, width=100, initial_indent='> ', subsequent_indent='> ',
                                 break_long_words=False, break_on_hyphens=False))
        continue
    m = re.match(r'^(\s*)([-*]|\d+\.)\s+', line)
    if m:
        first = m.group(0)
        rest = ' ' * len(first)
        body = line[len(first):]
    else:
        ind = re.match(r'^\s*', line).group(0)
        first = rest = ind
        body = line.strip()
    out.extend(textwrap.wrap(body, width=100, initial_indent=first, subsequent_indent=rest,
                             break_long_words=False, break_on_hyphens=False) or [first.rstrip()])
open(dest, 'w', encoding='utf-8').write('\n'.join(out))
