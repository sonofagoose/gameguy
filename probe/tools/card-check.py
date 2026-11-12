#!/usr/bin/env python3
"""Full-surface capacity check for SD cards (catches fake-capacity cards).

Every 512-byte sector gets a header (magic, sector number, run id) followed by a fill derived from
the sector number. Fake cards that wrap addresses or drop writes fail the read-back.

  card-check.py gen BYTES RUNID          > writes the pattern to stdout (pipe into: sudo dd of=DEV ...)
  card-check.py verify BYTES RUNID       < reads the card from stdin (pipe from: sudo dd if=DEV ...)
"""
import struct
import sys

SECTOR = 512
CHUNK = 4 << 20
SPC = CHUNK // SECTOR
MAGIC = 0x47414D4547555931  # "GAMEGUY1"


def chunk_bytes(first_sector, nsect, runid):
    buf = bytearray(nsect * SECTOR)
    fill = (struct.pack("<Q", 0x9E3779B97F4A7C15) * (SECTOR // 8))[16:]
    for i in range(nsect):
        s = first_sector + i
        off = i * SECTOR
        struct.pack_into("<QQ", buf, off, MAGIC ^ runid, s)
        buf[off + 16:off + SECTOR] = fill
        struct.pack_into("<Q", buf, off + SECTOR - 8, s ^ runid)
    return buf


def main():
    mode, total, runid = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    nsect_total = total // SECTOR
    if mode == "gen":
        out = sys.stdout.buffer
        s = 0
        while s < nsect_total:
            n = min(SPC, nsect_total - s)
            out.write(chunk_bytes(s, n, runid))
            s += n
        out.flush()
        return 0
    inp = sys.stdin.buffer
    s, bad, first_bad = 0, 0, None
    hdr = struct.Struct("<QQ")
    tail = struct.Struct("<Q")
    while s < nsect_total:
        want = min(SPC, nsect_total - s) * SECTOR
        data = inp.read(want)
        if len(data) < want:
            print(f"SHORT READ at sector {s + len(data) // SECTOR}", file=sys.stderr)
            bad += (want - len(data)) // SECTOR
            if first_bad is None:
                first_bad = s + len(data) // SECTOR
            break
        mv = memoryview(data)
        for i in range(want // SECTOR):
            off = i * SECTOR
            m, sec = hdr.unpack_from(mv, off)
            (t,) = tail.unpack_from(mv, off + SECTOR - 8)
            if m != MAGIC ^ runid or sec != s + i or t != (s + i) ^ runid:
                bad += 1
                if first_bad is None:
                    first_bad = s + i
        s += want // SECTOR
        if (s * SECTOR) % (1 << 30) < CHUNK:
            print(f"  verified {s * SECTOR / 1e9:.1f} GB, bad sectors so far: {bad}", file=sys.stderr)
    if bad:
        print(f"CARD CHECK FAILED: {bad} bad sectors, first at sector {first_bad} "
              f"({first_bad * SECTOR / 1e9:.2f} GB) -> real capacity is at most that", file=sys.stderr)
        return 1
    print(f"CARD CHECK OK: all {nsect_total} sectors ({total / 1e9:.2f} GB) hold their own data", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
