/* gameguy probe — sustained load and stability check (use this to validate overclock settings).
 *
 * CPU workers recompute a fixed block of FMA work and compare against a reference result;
 * a memory worker writes and verifies address-derived patterns; the GPU renders a fixed heavy
 * frame and its read-back hash must never change. Any mismatch = the current clocks are unstable.
 */
#include "probe.h"
#include <pthread.h>
#include <stdatomic.h>
#if defined(__aarch64__)
#include <arm_neon.h>
#endif

static atomic_int st_run;
static atomic_long cpu_err, cpu_blocks, mem_err, mem_passes;

static uint64_t cpu_block(void) {
    /* deterministic mixed int/float work; result must be bit-identical every time */
    float acc[16];
    for (int i = 0; i < 16; i++) acc[i] = 1.0f + i * 0.001f;
    uint64_t h = 1469598103934665603ULL;
    for (int it = 0; it < 200000; it++) {
        for (int i = 0; i < 16; i++) acc[i] = acc[i] * 0.99991f + 0.0001f * (float)(i + 1);
        if ((it & 1023) == 0) h = fnv1a(acc, sizeof acc, h);
    }
    return fnv1a(acc, sizeof acc, h);
}

static uint64_t cpu_ref;
static void *cpu_worker(void *p) {
    (void)p;
    while (atomic_load(&st_run)) {
        if (cpu_block() != cpu_ref) atomic_fetch_add(&cpu_err, 1);
        atomic_fetch_add(&cpu_blocks, 1);
    }
    return NULL;
}

static size_t mem_words;
static uint64_t *mem_buf;
static void *mem_worker(void *p) {
    (void)p;
    uint64_t pass = 0;
    while (atomic_load(&st_run)) {
        uint64_t k = 0x9E3779B97F4A7C15ULL * (pass + 1);
        for (size_t i = 0; i < mem_words && atomic_load(&st_run); i++) mem_buf[i] = (i * 0xD6E8FEB86659FD93ULL) ^ k;
        for (size_t i = 0; i < mem_words && atomic_load(&st_run); i++)
            if (mem_buf[i] != ((i * 0xD6E8FEB86659FD93ULL) ^ k)) atomic_fetch_add(&mem_err, 1);
        if (atomic_load(&st_run)) atomic_fetch_add(&mem_passes, 1);
        pass++;
    }
    return NULL;
}

static const char *VS =
    "#version 300 es\nlayout(location=0) in vec2 p;\nout vec2 uv;\nvoid main(){ uv=p*0.5+0.5; gl_Position=vec4(p,0.0,1.0); }\n";
static const char *FS =
    "#version 300 es\nprecision highp float;\nin vec2 uv;\nuniform sampler2D t;\nout vec4 o;\n"
    "void main(){ vec4 a = texture(t, uv*3.0); vec4 b = vec4(uv, 1.0-uv.x, 0.5);\n"
    "  for(int i=0;i<48;i++){ a = fract(a*1.0013 + b*0.37); b = b*0.999 + a.wzyx*0.001; }\n"
    "  o = a*0.5 + b*0.5; }\n";

void stress_run(int seconds) {
    test_begin("Stability under sustained load", seconds + 60);
    int ncpu = (int)sysconf(_SC_NPROCESSORS_ONLN);
    int nworkers = ncpu > 2 ? ncpu - 2 : 1;   /* leave one core for the GPU driver, one for memory */
    cpu_ref = cpu_block();
    long avail_kb = 0;
    FILE *f = fopen("/proc/meminfo", "r");
    if (f) {
        char line[128];
        while (fgets(line, sizeof line, f)) if (sscanf(line, "MemAvailable: %ld kB", &avail_kb) == 1) break;
        fclose(f);
    }
    size_t mem_mb = avail_kb ? (size_t)(avail_kb / 1024 / 3) : 128;
    if (mem_mb > 256) mem_mb = 256;
    if (mem_mb < 16) mem_mb = 16;
    mem_words = mem_mb * 1024 * 1024 / 8;
    mem_buf = malloc(mem_words * 8);
    kv("stress.duration_s", "%d", seconds);
    kv("stress.cpu_workers", "%d", nworkers);
    kv("stress.mem_test_mb", "%zu", mem_buf ? mem_mb : 0);

    /* GPU setup */
    GLuint prog = 0, vao = 0, vbo = 0, tex = 0, fbo = 0, rtex = 0;
    uint64_t gpu_ref = 0;
    long gpu_frames = 0, gpu_err = 0, gpu_checks = 0;
    int RW = gfx_w, RH = gfx_h;
    uint8_t *px = NULL;
    if (g_gfx_ok && g_gles_major >= 3) {
        prog = gl_program(VS, FS, "stress", false);
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);
        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        static const float tri[6] = {-1, -1, 3, -1, -1, 3};
        glBufferData(GL_ARRAY_BUFFER, sizeof tri, tri, GL_STATIC_DRAW);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
        glBindVertexArray(0);
        uint32_t *d = malloc(256 * 256 * 4);
        uint32_t s = 7;
        for (int i = 0; i < 256 * 256; i++) { s ^= s << 13; s ^= s >> 17; s ^= s << 5; d[i] = s; }
        glGenTextures(1, &tex);
        glBindTexture(GL_TEXTURE_2D, tex);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 256, 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, d);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        free(d);
        glGenTextures(1, &rtex);
        glBindTexture(GL_TEXTURE_2D, rtex);
        glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGBA8, RW, RH);
        glGenFramebuffers(1, &fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, rtex, 0);
        px = malloc((size_t)RW * RH * 4);
    }

    telem_reset();
    atomic_store(&st_run, 1);
    pthread_t th[8], mt;
    for (int i = 0; i < nworkers && i < 8; i++) pthread_create(&th[i], NULL, cpu_worker, NULL);
    if (mem_buf) pthread_create(&mt, NULL, mem_worker, NULL);

    double t0 = now_s(), last_ui = 0;
    while (now_s() - t0 < seconds) {
        if (prog && px) {
            glBindFramebuffer(GL_FRAMEBUFFER, fbo);
            glViewport(0, 0, RW, RH);
            glClearColor(0, 0, 0, 1);
            glClear(GL_COLOR_BUFFER_BIT);
            glUseProgram(prog);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, tex);
            glUniform1i(glGetUniformLocation(prog, "t"), 0);
            glBindVertexArray(vao);
            for (int k = 0; k < 4; k++) glDrawArrays(GL_TRIANGLES, 0, 3);
            gpu_frames++;
            if (gpu_frames % 20 == 1) {
                glReadPixels(0, 0, RW, RH, GL_RGBA, GL_UNSIGNED_BYTE, px);
                uint64_t h = fnv1a(px, (size_t)RW * RH * 4, 0);
                if (!gpu_ref) gpu_ref = h;
                else if (h != gpu_ref) gpu_err++;
                gpu_checks++;
            }
            glBindVertexArray(0);
        } else {
            usleep(20000);
        }
        double t = now_s();
        if (t - last_ui > 0.25) {
            last_ui = t;
            char snap[160];
            telem_snapshot_line(snap, sizeof snap);
            ui_begin_frame(0x140f10ff);
            ui_text(FONT_L, 16, 8, 0xffffffff, "STABILITY TEST");
            ui_textf(FONT_S, 16, 56, 0xffd36bff, "%.0f / %d s   (all cores + RAM + GPU at full load)", t - t0, seconds);
            ui_textf(FONT_S, 16, 96, 0xdce6eeff, "CPU blocks %ld   errors %ld", atomic_load(&cpu_blocks), atomic_load(&cpu_err));
            ui_textf(FONT_S, 16, 120, 0xdce6eeff, "RAM passes %ld (%zu MB)   errors %ld", atomic_load(&mem_passes), mem_mb,
                     atomic_load(&mem_err));
            ui_textf(FONT_S, 16, 144, 0xdce6eeff, "GPU frames %ld   checks %ld   errors %ld", gpu_frames, gpu_checks, gpu_err);
            ui_textf(FONT_S, 16, 184, 0x8aa0b4ff, "%.68s", snap);
            telem_stats_t s = telem_get();
            ui_textf(FONT_S, 16, 208, 0x8aa0b4ff, "max %.1f C | cpu min %.0f MHz | gpu min %.0f | ddr min %.0f",
                     s.max_temp_c, s.min_cpu_mhz, s.min_gpu_mhz, s.min_ddr_mhz);
            long errs = atomic_load(&cpu_err) + atomic_load(&mem_err) + gpu_err;
            ui_text(FONT_L, 16, 260, errs ? 0xff6b6bff : 0x7dff9aff, errs ? "ERRORS DETECTED" : "no errors so far");
            ui_text(FONT_S, 16, gfx_h - 24, 0x5d6d7aff, "Hold SELECT+START to stop early");
            ui_present();
            if (probe_aborted()) break;
        }
    }
    atomic_store(&st_run, 0);
    for (int i = 0; i < nworkers && i < 8; i++) pthread_join(th[i], NULL);
    if (mem_buf) pthread_join(mt, NULL);
    double dur = now_s() - t0;
    telem_stats_t s = telem_get();
    kv("stress.actual_s", "%.1f", dur);
    kv("stress.cpu_blocks", "%ld", atomic_load(&cpu_blocks));
    kv("stress.cpu_errors", "%ld", atomic_load(&cpu_err));
    kv("stress.mem_passes", "%ld", atomic_load(&mem_passes));
    kv("stress.mem_errors", "%ld", atomic_load(&mem_err));
    kv("stress.gpu_frames", "%ld", gpu_frames);
    kv("stress.gpu_checks", "%ld", gpu_checks);
    kv("stress.gpu_errors", "%ld", gpu_err);
    kv("stress.gpu_fps", "%.1f", gpu_frames / dur);
    kv("stress.max_temp_c", "%.1f", s.max_temp_c);
    kv("stress.cpu_mhz_range", "%.0f .. %.0f", s.min_cpu_mhz, s.max_cpu_mhz);
    kv("stress.gpu_mhz_range", "%.0f .. %.0f", s.min_gpu_mhz, s.max_gpu_mhz);
    kv("stress.ddr_mhz_range", "%.0f .. %.0f", s.min_ddr_mhz, s.max_ddr_mhz);
    kv("stress.battery_pct", "%.0f -> %.0f", s.batt_start_pct, s.batt_end_pct);
    long errs = atomic_load(&cpu_err) + atomic_load(&mem_err) + gpu_err;
    summary("stability %.0fs: %s (cpu %ld, ram %ld, gpu %ld err) max %.1fC", dur, errs ? "FAILED" : "PASS",
            atomic_load(&cpu_err), atomic_load(&mem_err), gpu_err, s.max_temp_c);
    summary("  under load: cpu %.0f-%.0f MHz, gpu %.0f-%.0f, ddr %.0f-%.0f", s.min_cpu_mhz, s.max_cpu_mhz, s.min_gpu_mhz,
            s.max_gpu_mhz, s.min_ddr_mhz, s.max_ddr_mhz);
    if (prog) {
        glDeleteProgram(prog);
        glDeleteVertexArrays(1, &vao);
        glDeleteBuffers(1, &vbo);
        glDeleteTextures(1, &tex);
        glDeleteTextures(1, &rtex);
        glDeleteFramebuffers(1, &fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
    free(px);
    free(mem_buf);
    mem_buf = NULL;
    test_end();
}
