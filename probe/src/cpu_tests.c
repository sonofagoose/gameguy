/* gameguy probe — CPU, memory, audio-synthesis throughput and storage tests. */
#include "probe.h"
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <sys/statvfs.h>
#include <sys/vfs.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#if defined(__aarch64__)
#include <arm_neon.h>
#endif

static volatile double g_sink;

/* ---------- peak FP32 FMA throughput ---------- */
static double fma_block(long iters, float seed) {
#if defined(__aarch64__)
    float32x4_t m = vdupq_n_f32(0.999f), c = vdupq_n_f32(seed * 0.001f);
    float32x4_t a0 = vdupq_n_f32(seed), a1 = vaddq_f32(a0, c), a2 = vaddq_f32(a1, c), a3 = vaddq_f32(a2, c);
    float32x4_t a4 = vaddq_f32(a3, c), a5 = vaddq_f32(a4, c), a6 = vaddq_f32(a5, c), a7 = vaddq_f32(a6, c);
    for (long i = 0; i < iters; i++) {
        a0 = vfmaq_f32(c, a0, m); a1 = vfmaq_f32(c, a1, m); a2 = vfmaq_f32(c, a2, m); a3 = vfmaq_f32(c, a3, m);
        a4 = vfmaq_f32(c, a4, m); a5 = vfmaq_f32(c, a5, m); a6 = vfmaq_f32(c, a6, m); a7 = vfmaq_f32(c, a7, m);
    }
    float32x4_t s = vaddq_f32(vaddq_f32(vaddq_f32(a0, a1), vaddq_f32(a2, a3)), vaddq_f32(vaddq_f32(a4, a5), vaddq_f32(a6, a7)));
    return vgetq_lane_f32(s, 0) + vgetq_lane_f32(s, 3);
#else
    float a[32], m = 0.999f, c = seed * 0.001f;
    for (int j = 0; j < 32; j++) a[j] = seed + j * c;
    for (long i = 0; i < iters; i++)
        for (int j = 0; j < 32; j++) a[j] = a[j] * m + c;
    double s = 0;
    for (int j = 0; j < 32; j++) s += a[j];
    return s;
#endif
}
#define FMA_FLOPS_PER_ITER 64.0   /* 8 vectors x 4 lanes x 2 flops */

double cpu_neon_gflops_1thread(double seconds) {
    long it = 1 << 20;
    double t0 = now_s();
    g_sink += fma_block(it, 1.0f);
    double one = now_s() - t0;
    long total = (long)(it * (seconds / (one > 0 ? one : 1e-3)));
    if (total < it) total = it;
    t0 = now_s();
    g_sink += fma_block(total, 1.0f);
    double dt = now_s() - t0;
    return total * FMA_FLOPS_PER_ITER / dt / 1e9;
}

typedef struct { long iters; double result; pthread_barrier_t *bar; } mt_arg;
static void *mt_worker(void *p) {
    mt_arg *a = p;
    pthread_barrier_wait(a->bar);
    a->result = fma_block(a->iters, 1.0f);
    return NULL;
}

static double neon_mt(int threads, double seconds, double single_gflops) {
    long iters = (long)(single_gflops * 1e9 * seconds / FMA_FLOPS_PER_ITER);
    pthread_t th[8];
    mt_arg args[8];
    pthread_barrier_t bar;
    pthread_barrier_init(&bar, NULL, (unsigned)threads + 1);
    for (int i = 0; i < threads; i++) {
        args[i] = (mt_arg){iters, 0, &bar};
        pthread_create(&th[i], NULL, mt_worker, &args[i]);
    }
    pthread_barrier_wait(&bar);
    double t0 = now_s();
    for (int i = 0; i < threads; i++) { pthread_join(th[i], NULL); g_sink += args[i].result; }
    double dt = now_s() - t0;
    pthread_barrier_destroy(&bar);
    return (double)threads * iters * FMA_FLOPS_PER_ITER / dt / 1e9;
}

/* ---------- memory ---------- */
static double bw_test(const char *what, size_t sz) {
    uint8_t *a = malloc(sz), *b = malloc(sz);
    if (!a || !b) { free(a); free(b); return 0; }
    memset(a, 1, sz);
    memset(b, 2, sz);
    double best = 0;
    for (int r = 0; r < 5; r++) {
        double t0 = now_s();
        if (!strcmp(what, "memcpy")) memcpy(b, a, sz);
        else if (!strcmp(what, "memset")) memset(b, r, sz);
        else {
            const uint64_t *p = (const uint64_t *)a;
            uint64_t s0 = 0, s1 = 0, s2 = 0, s3 = 0;
            for (size_t i = 0; i < sz / 8; i += 4) { s0 += p[i]; s1 += p[i + 1]; s2 += p[i + 2]; s3 += p[i + 3]; }
            g_sink += (double)(s0 + s1 + s2 + s3);
        }
        double dt = now_s() - t0;
        double gbs = sz / dt / 1e9;
        if (gbs > best) best = gbs;
    }
    g_sink += b[sz / 2];
    free(a);
    free(b);
    return best;
}

typedef struct { const uint64_t *p; size_t n; uint64_t s; pthread_barrier_t *bar; } rd_arg;
static void *rd_worker(void *v) {
    rd_arg *a = v;
    pthread_barrier_wait(a->bar);
    uint64_t s0 = 0, s1 = 0, s2 = 0, s3 = 0;
    for (int r = 0; r < 3; r++)
        for (size_t i = 0; i < a->n; i += 4) { s0 += a->p[i]; s1 += a->p[i + 1]; s2 += a->p[i + 2]; s3 += a->p[i + 3]; }
    a->s = s0 + s1 + s2 + s3;
    return NULL;
}
/* aggregate DRAM read bandwidth with N threads, 16 MB private buffer each, 3 passes */
static double read_mt(int threads) {
    const size_t SZ = 16u << 20;
    pthread_t th[8];
    rd_arg a[8];
    pthread_barrier_t bar;
    pthread_barrier_init(&bar, NULL, (unsigned)threads + 1);
    for (int i = 0; i < threads; i++) {
        uint64_t *b = malloc(SZ);
        memset(b, i + 1, SZ);
        a[i] = (rd_arg){b, SZ / 8, 0, &bar};
        pthread_create(&th[i], NULL, rd_worker, &a[i]);
    }
    pthread_barrier_wait(&bar);
    double t0 = now_s();
    for (int i = 0; i < threads; i++) { pthread_join(th[i], NULL); g_sink += (double)a[i].s; free((void *)a[i].p); }
    double dt = now_s() - t0;
    pthread_barrier_destroy(&bar);
    return (double)threads * SZ * 3 / dt / 1e9;
}

static double latency_ns(size_t sz) {
    size_t n = sz / 64;
    if (n < 16) n = 16;
    size_t *idx = malloc(n * sizeof(size_t));
    char *buf = aligned_alloc(64, n * 64);
    if (!idx || !buf) { free(idx); free(buf); return 0; }
    for (size_t i = 0; i < n; i++) idx[i] = i;
    uint32_t s = 2463534242u;
    for (size_t i = n - 1; i > 0; i--) {
        s ^= s << 13; s ^= s >> 17; s ^= s << 5;
        size_t j = s % (i + 1), t = idx[i]; idx[i] = idx[j]; idx[j] = t;
    }
    for (size_t i = 0; i < n; i++) *(void **)(buf + idx[i] * 64) = buf + idx[(i + 1) % n] * 64;
    void *p = buf + idx[0] * 64;
    long loads = 4000000;
    for (size_t i = 0; i < n; i++) p = *(void **)p;   /* warm */
    double t0 = now_s();
    for (long i = 0; i < loads; i++) p = *(void **)p;
    double dt = now_s() - t0;
    g_sink += (double)(uintptr_t)p;
    free(idx);
    free(buf);
    return dt / loads * 1e9;
}

/* ---------- synthesis throughput (voices per core in real time @ 48 kHz) ---------- */
#define SR 48000
static float sine_tab[2049];

static double synth_sine(int voices, int samples, float *out) {
    float ph[256], inc[256], amp[256], dec[256];
    for (int v = 0; v < voices; v++) {
        ph[v] = 0; inc[v] = (110.0f * (1 + v % 12) * 1.0004f) / SR * 2048.0f; amp[v] = 0.01f; dec[v] = 0.99999f;
    }
    double t0 = now_s();
    for (int i = 0; i < samples; i++) {
        float acc = 0;
        for (int v = 0; v < voices; v++) {
            float p = ph[v];
            int k = (int)p;
            float f = p - k;
            acc += (sine_tab[k] + (sine_tab[k + 1] - sine_tab[k]) * f) * amp[v];
            amp[v] *= dec[v];
            p += inc[v];
            if (p >= 2048.0f) p -= 2048.0f;
            ph[v] = p;
        }
        out[i] = acc;
    }
    return now_s() - t0;
}

static double synth_ks(int voices, int samples, float *out) {
    /* Karplus-Strong plucked strings */
    static float lines[64][1024];
    int len[64], pos[64];
    uint32_t s = 1;
    for (int v = 0; v < voices; v++) {
        len[v] = 120 + v * 13;
        pos[v] = 0;
        for (int i = 0; i < len[v]; i++) { s = s * 1664525u + 1013904223u; lines[v][i] = (s >> 9) * (1.0f / 8388608.0f) - 1.0f; }
    }
    double t0 = now_s();
    for (int i = 0; i < samples; i++) {
        float acc = 0;
        for (int v = 0; v < voices; v++) {
            int p = pos[v], q = p + 1 == len[v] ? 0 : p + 1;
            float y = 0.4985f * (lines[v][p] + lines[v][q]);
            lines[v][p] = y;
            pos[v] = q;
            acc += y;
        }
        out[i] = acc * 0.01f;
    }
    return now_s() - t0;
}

static inline float polyblep(float t, float dt) {
    if (t < dt) { t /= dt; return t + t - t * t - 1.0f; }
    if (t > 1.0f - dt) { t = (t - 1.0f) / dt; return t * t + t + t + 1.0f; }
    return 0.0f;
}

static double synth_saw_svf(int voices, int samples, float *out) {
    /* band-limited saw (polyBLEP) through a Chamberlin state-variable low-pass */
    float ph[64], dt[64], lp[64], bp[64];
    for (int v = 0; v < voices; v++) { ph[v] = 0; dt[v] = (55.0f * (1 + v % 8)) / SR; lp[v] = bp[v] = 0; }
    const float f = 0.15f, q = 0.5f;
    double t0 = now_s();
    for (int i = 0; i < samples; i++) {
        float acc = 0;
        for (int v = 0; v < voices; v++) {
            float t = ph[v];
            float x = 2.0f * t - 1.0f - polyblep(t, dt[v]);
            t += dt[v];
            if (t >= 1.0f) t -= 1.0f;
            ph[v] = t;
            lp[v] += f * bp[v];
            float hp = x - lp[v] - q * bp[v];
            bp[v] += f * hp;
            acc += lp[v];
        }
        out[i] = acc * 0.01f;
    }
    return now_s() - t0;
}

void cpu_tests_run(void) {
    test_begin("CPU and memory", 120);
    int ncpu = (int)sysconf(_SC_NPROCESSORS_ONLN);
    kv("cpu.online", "%d", ncpu);
    double g1 = cpu_neon_gflops_1thread(0.8);
    kv("cpu.fma_gflops_1thread", "%.2f", g1);
    double gmt[8] = {0};
    for (int t = 2; t <= ncpu && t <= 8; t++) {
        gmt[t] = neon_mt(t, 0.8, g1);
        plog("cpu.fma_gflops_%dthreads = %.2f\n", t, gmt[t]);
    }
    summary("CPU: %.1f GFLOPS/core fp32 FMA, %.1f with %d cores", g1, ncpu > 1 ? gmt[ncpu > 8 ? 8 : ncpu] : g1, ncpu);
    ui_frame();

    /* scalar dependent chain = FMA latency */
    double x = 1.0, m = 0.9999999, c = 1e-7;
    long n = 20000000;
    double t0 = now_s();
    for (long i = 0; i < n; i++) x = x * m + c;
    double dt = now_s() - t0;
    g_sink += x;
    kv("cpu.dependent_fma_ns", "%.3f", dt / n * 1e9);

    size_t S = 32u << 20;
    double cpy = bw_test("memcpy", S), set = bw_test("memset", S), rd = bw_test("read", S);
    kv("mem.memcpy_gbps", "%.2f", cpy);
    kv("mem.memset_gbps", "%.2f", set);
    kv("mem.read_gbps", "%.2f", rd);
    double rd4 = read_mt(ncpu > 4 ? 4 : ncpu);
    kv("mem.read_gbps_all_cores", "%.2f", rd4);
    summary("RAM: read %.2f GB/s (1 core) %.2f (all), write %.2f, memcpy %.2f GB/s copied", rd, rd4, set, cpy);
    ui_frame();
    size_t sizes[] = {16u << 10, 128u << 10, 1u << 20, 8u << 20, 64u << 20};
    double lat[5];
    for (int i = 0; i < 5; i++) {
        lat[i] = latency_ns(sizes[i]);
        plog("mem.latency_%zuKB_ns = %.1f\n", sizes[i] >> 10, lat[i]);
    }
    summary("latency ns: L1 %.1f | 128K %.1f | 1M %.1f | 8M %.1f | 64M %.1f", lat[0], lat[1], lat[2], lat[3], lat[4]);
    ui_frame();

    /* synthesis */
    for (int i = 0; i <= 2048; i++) sine_tab[i] = sinf(i * 6.28318530718f / 2048.0f);
    float *out = malloc(sizeof(float) * SR);
    int V = 64;
    double ts = synth_sine(V, SR, out), tk = synth_ks(V, SR, out), tv = synth_saw_svf(V, SR, out);
    g_sink += out[SR / 2];
    free(out);
    double vs = V / ts, vk = V / tk, vv = V / tv;
    kv("synth.sine_voices_per_core", "%.0f", vs);
    kv("synth.karplus_strong_voices_per_core", "%.0f", vk);
    kv("synth.saw_svf_voices_per_core", "%.0f", vv);
    summary("synth voices/core @48k (100%% of a core): sine %.0f, KS string %.0f, saw+SVF %.0f", vs, vk, vv);
    test_end();
}

/* ---------- storage ---------- */
void storage_test_run(void) {
    test_begin("Storage read/write (where the probe lives)", 120);
    struct statvfs sv;
    char path[512];
    snprintf(path, sizeof path, "%s/.iotest.tmp", g_results_dir);
    if (statvfs(g_results_dir, &sv) == 0) {
        double free_mb = (double)sv.f_bavail * sv.f_frsize / 1e6;
        kv("storage.free_mb", "%.0f", free_mb);
        if (free_mb < 300) { summary("storage test skipped: only %.0f MB free", free_mb); test_end(); return; }
    }
    struct statfs sf;
    if (statfs(g_results_dir, &sf) == 0) kv("storage.fs_magic", "0x%lx", (unsigned long)sf.f_type);
    /* Guard: some vendor card images declare a filesystem larger than the card itself; writes into the
     * missing tail fail and the kernel flips the card read-only. Compare fs size with partition size. */
    struct stat st;
    if (stat(g_results_dir, &st) == 0) {
        char sp[128];
        snprintf(sp, sizeof sp, "/sys/dev/block/%u:%u/size", major(st.st_dev), minor(st.st_dev));
        FILE *f = fopen(sp, "r");
        unsigned long long sectors = 0;
        if (f) { if (fscanf(f, "%llu", &sectors) != 1) sectors = 0; fclose(f); }
        double part_mb = sectors * 512.0 / 1e6, fs_mb = (double)sv.f_blocks * sv.f_frsize / 1e6;
        if (sectors) kv("storage.partition_vs_fs_mb", "%.0f vs %.0f", part_mb, fs_mb);
        if (sectors && fs_mb > part_mb + 1) {
            summary("storage test SKIPPED: filesystem (%.0f MB) is larger than its partition (%.0f MB)", fs_mb, part_mb);
            test_end();
            return;
        }
    }
    char cwd[512] = "";
    if (getcwd(cwd, sizeof cwd)) kv("storage.cwd", "%s", cwd);
    const size_t MB = 1u << 20, total = 32 * MB;
    uint8_t *buf = malloc(4 * MB);
    for (size_t i = 0; i < 4 * MB; i++) buf[i] = (uint8_t)(i * 2654435761u >> 24);
    int fd = open(path, O_CREAT | O_TRUNC | O_WRONLY, 0644);
    if (fd < 0) { summary("storage test failed: %s", strerror(errno)); free(buf); test_end(); return; }
    double t0 = now_s();
    for (size_t w = 0; w < total; w += 4 * MB) {
        if (write(fd, buf, 4 * MB) != (ssize_t)(4 * MB)) { plog("write error: %s\n", strerror(errno)); break; }
    }
    fsync(fd);
    double tw = now_s() - t0;
    posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
    close(fd);
    fd = open(path, O_RDONLY);
    posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
    t0 = now_s();
    size_t got = 0;
    ssize_t r;
    while ((r = read(fd, buf, 4 * MB)) > 0) got += (size_t)r;
    double tr = now_s() - t0;
    close(fd);
    unlink(path);
    free(buf);
    double wmb = total / tw / 1e6, rmb = got / tr / 1e6;
    kv("storage.write_mbps", "%.1f", wmb);
    kv("storage.read_mbps", "%.1f", rmb);
    summary("storage: write %.1f MB/s, read %.1f MB/s (32 MB, cache dropped)", wmb, rmb);
    test_end();
}
