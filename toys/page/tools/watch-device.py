#!/usr/bin/env python3
# Sample what the device is doing, 20 times a second, to a file in memory.
import time, sys, json
out = open(sys.argv[2], 'w')
def rd(p):
    try: return open(p).read().strip()
    except Exception: return '?'
def disk():
    for line in open('/proc/diskstats'):
        f = line.split()
        if f[2] == 'mmcblk2': return [int(f[5]), int(f[9]), int(f[11])]
    return []
def stat():
    r = {}
    for line in open('/proc/stat'):
        if line.startswith('cpu '): r['cpu'] = [int(x) for x in line.split()[1:8]]
        elif line.startswith('ctxt'): r['ctxt'] = int(line.split()[1])
        elif line.startswith('procs_running'): r['run'] = int(line.split()[1])
    return r
def softirqs():
    r = {}
    for line in open('/proc/softirqs').read().split('\n')[1:]:
        f = line.split()
        if f: r[f[0].rstrip(':')] = sum(int(x) for x in f[1:])
    return r
def irqs():
    r = {}
    for line in open('/proc/interrupts', errors='replace').read().split('\n')[1:]:
        f = line.split()
        if not f: continue
        n = 0
        for x in f[1:5]:
            if x.isdigit(): n += int(x)
        r[f[0].rstrip(':') + ' ' + ' '.join(f[-2:])] = n
    return r
end = time.time() + float(sys.argv[1])
while time.time() < end:
    t = time.time()
    row = {'t': t, 'pid': int(open('/proc/loadavg').read().split()[4]), 'disk': disk(),
           'dmc': rd('/sys/class/devfreq/dmc/cur_freq'), 'gpu': rd('/sys/class/devfreq/ff400000.gpu/cur_freq'),
           'cpuf': rd('/sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq'),
           'soft': softirqs(), 'irq': irqs()}
    row.update(stat())
    out.write(json.dumps(row) + '\n')
    out.flush()
    time.sleep(0.05)
