/* gameguy probe — GPU capability and performance tests (OpenGL ES 3.x). */
#include "probe.h"
#include <dlfcn.h>
#define EGL_NO_X11
#define MESA_EGL_NO_X11_HEADERS
#define EGL_EGL_PROTOTYPES 0
#include <EGL/egl.h>
#include <EGL/eglext.h>

#ifndef GL_COMPRESSED_RGBA_ASTC_4x4_KHR
#define GL_COMPRESSED_RGBA_ASTC_4x4_KHR 0x93B0
#endif
#ifndef GL_SHADER_PIXEL_LOCAL_STORAGE_EXT
#define GL_SHADER_PIXEL_LOCAL_STORAGE_EXT 0x8F64
#endif
#ifndef GL_MAX_SHADER_PIXEL_LOCAL_STORAGE_FAST_SIZE_EXT
#define GL_MAX_SHADER_PIXEL_LOCAL_STORAGE_FAST_SIZE_EXT 0x8F63
#endif
#ifndef GL_MAX_SHADER_PIXEL_LOCAL_STORAGE_SIZE_EXT
#define GL_MAX_SHADER_PIXEL_LOCAL_STORAGE_SIZE_EXT 0x8F67
#endif

static GLuint vao_full, vbo_full;
static int W, H;

typedef struct { GLuint fbo, tex; int w, h; } rt_t;

static bool rt_create(rt_t *r, int w, int h) {
    r->w = w; r->h = h;
    glGenTextures(1, &r->tex);
    glBindTexture(GL_TEXTURE_2D, r->tex);
    glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGBA8, w, h);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glGenFramebuffers(1, &r->fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, r->fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, r->tex, 0);
    GLenum st = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (st != GL_FRAMEBUFFER_COMPLETE) { plog("FBO incomplete: 0x%x\n", st); return false; }
    return true;
}

static void rt_destroy(rt_t *r) {
    glDeleteFramebuffers(1, &r->fbo);
    glDeleteTextures(1, &r->tex);
    memset(r, 0, sizeof *r);
}

static void bind_rt(const rt_t *r) {
    glBindFramebuffer(GL_FRAMEBUFFER, r->fbo);
    glViewport(0, 0, r->w, r->h);
}

static void draw_full(void) {
    glBindVertexArray(vao_full);
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

/* Time one "frame" function: warm up, calibrate, then repeat to fill ~target seconds.
 * glFinish after EVERY frame: the Mali driver silently discards queued, un-flushed draws when a later
 * glClear overwrites them, so batching frames before one glFinish measured only the last frame
 * (probe v1.0 bug: reported fill/ALU rates 10-30x above the hardware's theoretical peak). */
typedef void (*frame_fn)(void *);
static double g_frame_overhead;   /* clear + glFinish of an empty frame; subtracted for throughput */
static double time_frames(frame_fn f, void *ctx, double target_s) {
    f(ctx);
    glFinish();
    double t0 = now_s();
    f(ctx);
    glFinish();
    double one = now_s() - t0;
    int reps = one > 0 ? (int)(target_s / one) : 100;
    if (reps < 3) reps = 3;
    if (reps > 300) reps = 300;
    t0 = now_s();
    for (int i = 0; i < reps; i++) { f(ctx); glFinish(); }
    return (now_s() - t0) / reps;
}
static double net(double t) {
    double n = t - g_frame_overhead;
    return n > 1e-6 ? n : 1e-6;
}

static uint32_t rng_state = 0x12345678u;
static uint32_t rng(void) {
    rng_state ^= rng_state << 13; rng_state ^= rng_state >> 17; rng_state ^= rng_state << 5;
    return rng_state;
}

static void read_center(uint8_t px[4]) {
    glReadPixels(W / 2, H / 2, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, px);
}

static const char *VS_FULL =
    "#version 300 es\nlayout(location=0) in vec2 p;\nout vec2 uv;\n"
    "void main(){ uv=p*0.5+0.5; gl_Position=vec4(p,0.0,1.0); }\n";
static const char *FS_COLOR =
    "#version 300 es\nprecision mediump float;\nuniform vec4 col;\nout vec4 o;\nvoid main(){ o=col; }\n";
static const char *FS_TEX =
    "#version 300 es\nprecision mediump float;\nin vec2 uv;\nuniform sampler2D t;\nuniform vec2 sc;\n"
    "uniform float gain;\nout vec4 o;\nvoid main(){ o=texture(t, uv*sc)*gain; }\n";

/* ======================= capabilities ======================= */
static void caps_run(void) {
    test_begin("GPU capabilities (GLES/EGL)", 30);
    plog("--- GL_EXTENSIONS\n");
    {
        GLint n = 0;
        if (g_gles_major >= 3 && glGetStringi) {
            glGetIntegerv(GL_NUM_EXTENSIONS, &n);
            for (GLint i = 0; i < n; i++) plog("  %s\n", (const char *)glGetStringi(GL_EXTENSIONS, (GLuint)i));
        } else {
            plog("  %s\n", (const char *)glGetString(GL_EXTENSIONS));
        }
        kv("gl.num_extensions", "%d", n);
    }
    struct { GLenum e; const char *n; int cnt; } lim[] = {
        {GL_MAX_TEXTURE_SIZE, "max_texture_size", 1}, {GL_MAX_RENDERBUFFER_SIZE, "max_renderbuffer_size", 1},
        {GL_MAX_VIEWPORT_DIMS, "max_viewport_dims", 2}, {GL_MAX_TEXTURE_IMAGE_UNITS, "max_fs_texture_units", 1},
        {GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, "max_combined_texture_units", 1},
        {GL_MAX_VERTEX_ATTRIBS, "max_vertex_attribs", 1}, {GL_MAX_VERTEX_UNIFORM_VECTORS, "max_vs_uniform_vectors", 1},
        {GL_MAX_FRAGMENT_UNIFORM_VECTORS, "max_fs_uniform_vectors", 1}, {GL_MAX_VARYING_VECTORS, "max_varying_vectors", 1},
        {GL_MAX_DRAW_BUFFERS, "max_draw_buffers", 1}, {GL_MAX_COLOR_ATTACHMENTS, "max_color_attachments", 1},
        {GL_MAX_SAMPLES, "max_samples", 1}, {GL_MAX_ARRAY_TEXTURE_LAYERS, "max_array_texture_layers", 1},
        {GL_MAX_3D_TEXTURE_SIZE, "max_3d_texture_size", 1}, {GL_MAX_UNIFORM_BLOCK_SIZE, "max_uniform_block_size", 1},
        {GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS, "max_compute_invocations", 1},
        {GL_MAX_SHADER_STORAGE_BLOCK_SIZE, "max_ssbo_block_size", 1},
        {GL_MAX_SHADER_PIXEL_LOCAL_STORAGE_FAST_SIZE_EXT, "max_pls_fast_size", 1},
        {GL_MAX_SHADER_PIXEL_LOCAL_STORAGE_SIZE_EXT, "max_pls_size", 1},
    };
    for (size_t i = 0; i < sizeof lim / sizeof lim[0]; i++) {
        GLint v[2] = {-1, -1};
        glGetIntegerv(lim[i].e, v);
        glGetError();
        char key[96];
        snprintf(key, sizeof key, "gl.%s", lim[i].n);
        if (lim[i].cnt == 2) kv(key, "%d x %d", v[0], v[1]);
        else kv(key, "%d", v[0]);
    }
    const GLenum st[] = {GL_VERTEX_SHADER, GL_FRAGMENT_SHADER};
    const GLenum pt[] = {GL_LOW_FLOAT, GL_MEDIUM_FLOAT, GL_HIGH_FLOAT, GL_LOW_INT, GL_MEDIUM_INT, GL_HIGH_INT};
    const char *pn[] = {"lowp_float", "mediump_float", "highp_float", "lowp_int", "mediump_int", "highp_int"};
    for (int s = 0; s < 2; s++)
        for (int p = 0; p < 6; p++) {
            GLint range[2] = {0, 0}, prec = 0;
            glGetShaderPrecisionFormat(st[s], pt[p], range, &prec);
            char key[64];
            snprintf(key, sizeof key, "gl.precision.%s.%s", s ? "fs" : "vs", pn[p]);
            kv(key, "range [%d,%d] precision %d bits", range[0], range[1], prec);
        }
    GLint nfmt = 0;
    glGetIntegerv(GL_NUM_COMPRESSED_TEXTURE_FORMATS, &nfmt);
    if (nfmt > 0 && nfmt < 512) {
        GLint *f = calloc((size_t)nfmt, sizeof(GLint));
        glGetIntegerv(GL_COMPRESSED_TEXTURE_FORMATS, f);
        char buf[4096] = "";
        for (int i = 0; i < nfmt; i++) {
            char t[16];
            snprintf(t, sizeof t, "0x%04x ", f[i]);
            strncat(buf, t, sizeof buf - strlen(buf) - 1);
        }
        kv("gl.compressed_formats", "%d: %s", nfmt, buf);
        free(f);
    }
    gl_check("caps");

    /* EGL */
    void *egl = dlopen("libEGL.so.1", RTLD_NOW | RTLD_NOLOAD);
    if (!egl) egl = dlopen("libEGL.so", RTLD_NOW | RTLD_NOLOAD);
    if (!egl) egl = dlopen("libEGL.so.1", RTLD_NOW);
    if (egl) {
        PFNEGLGETCURRENTDISPLAYPROC getdpy = (PFNEGLGETCURRENTDISPLAYPROC)dlsym(egl, "eglGetCurrentDisplay");
        PFNEGLQUERYSTRINGPROC qs = (PFNEGLQUERYSTRINGPROC)dlsym(egl, "eglQueryString");
        Dl_info info;
        if (qs && dladdr((void *)qs, &info)) kv("egl.library", "%s", info.dli_fname);
        EGLDisplay d = getdpy ? getdpy() : EGL_NO_DISPLAY;
        if (qs && d != EGL_NO_DISPLAY) {
            kv("egl.vendor", "%s", qs(d, EGL_VENDOR));
            kv("egl.version", "%s", qs(d, EGL_VERSION));
            kv("egl.client_apis", "%s", qs(d, EGL_CLIENT_APIS));
            kv("egl.extensions", "%s", qs(d, EGL_EXTENSIONS));
        }
        if (qs) { const char *c = qs(EGL_NO_DISPLAY, EGL_EXTENSIONS); kv("egl.client_extensions", "%s", c ? c : "(none)"); }
    } else {
        kv("egl.library", "not found (%s)", dlerror());
    }

    bool pls = gl_has_ext("GL_EXT_shader_pixel_local_storage");
    bool fbf_arm = gl_has_ext("GL_ARM_shader_framebuffer_fetch");
    bool fbf_ext = gl_has_ext("GL_EXT_shader_framebuffer_fetch");
    bool astc = gl_has_ext("GL_KHR_texture_compression_astc_ldr");
    summary("GPU: %.80s", g_gl_renderer);
    summary("ext: PLS %s | fbfetch ARM %s EXT %s | ASTC %s | timer %s", pls ? "Y" : "n", fbf_arm ? "Y" : "n",
            fbf_ext ? "Y" : "n", astc ? "Y" : "n", gl_has_ext("GL_EXT_disjoint_timer_query") ? "Y" : "n");
    test_end();
}

/* ======================= fill rate ======================= */
typedef struct { rt_t *rt; GLuint prog; int layers; bool blend; int frame; } fill_ctx;
static void fill_frame(void *p) {
    fill_ctx *c = p;
    bind_rt(c->rt);
    float k = (c->frame++ & 1) ? 0.1f : 0.2f;   /* vary clear colour: defeats transaction elimination */
    glClearColor(k, k, k, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(c->prog);
    GLint u = glGetUniformLocation(c->prog, "col");
    if (c->blend) { glEnable(GL_BLEND); glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA); }
    for (int i = 0; i < c->layers; i++) {
        glUniform4f(u, 0.01f * i, 0.02f, 0.03f, 0.05f);
        draw_full();
    }
    glDisable(GL_BLEND);
}
typedef struct { rt_t *rt; int frame; } clear_ctx;
static void clear_frame(void *p) {
    clear_ctx *c = p;
    bind_rt(c->rt);
    float k = (c->frame++ % 7) / 7.0f;
    glClearColor(k, 1 - k, k * 0.5f, 1);
    glClear(GL_COLOR_BUFFER_BIT);
}

static void fill_run(rt_t *rt) {
    test_begin("GPU fill rate", 60);
    GLuint prog = gl_program(VS_FULL, FS_COLOR, "fill", false);
    if (!prog) { test_end(); return; }
    double px = (double)rt->w * rt->h;
    clear_ctx cc = {rt, 0};
    double tc = time_frames(clear_frame, &cc, 0.5);
    g_frame_overhead = tc;
    kv("gpu.empty_frame_ms (clear + finish; subtracted below)", "%.3f", tc * 1e3);
    double mpx_o = 0, mpx_b = 0;
    int layers[] = {4, 16, 32};
    for (int i = 0; i < 3; i++) {
        fill_ctx c = {rt, prog, layers[i], false, 0};
        double t = time_frames(fill_frame, &c, 0.6);
        double m = px * layers[i] / net(t) / 1e6;
        plog("fill.opaque.layers%d = %.3f ms/frame, %.0f Mpix/s\n", layers[i], t * 1e3, m);
        if (layers[i] == 16) mpx_o = m;
        fill_ctx b = {rt, prog, layers[i], true, 0};
        t = time_frames(fill_frame, &b, 0.6);
        m = px * layers[i] / net(t) / 1e6;
        plog("fill.blended.layers%d = %.3f ms/frame, %.0f Mpix/s\n", layers[i], t * 1e3, m);
        if (layers[i] == 16) mpx_b = m;
    }
    double screen_px = (double)W * H;
    summary("fill: opaque %.0f Mpix/s (hidden-pixel kill), blended %.0f Mpix/s", mpx_o, mpx_b);
    summary("  = %.1f blended full-screen layers per 60 Hz frame", mpx_b * 1e6 / 60.0 / screen_px);
    glDeleteProgram(prog);
    gl_check("fill");
    test_end();
}

/* ======================= texture sampling / formats ======================= */
typedef struct { rt_t *rt; GLuint prog, tex; float sx, sy; int layers; } tex_ctx;
static void tex_frame(void *p) {
    tex_ctx *c = p;
    bind_rt(c->rt);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(c->prog);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, c->tex);
    glUniform1i(glGetUniformLocation(c->prog, "t"), 0);
    glUniform2f(glGetUniformLocation(c->prog, "sc"), c->sx, c->sy);
    glUniform1f(glGetUniformLocation(c->prog, "gain"), 0.05f);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    for (int i = 0; i < c->layers; i++) draw_full();
    glDisable(GL_BLEND);
}

static GLuint make_tex(int w, int h, GLenum ifmt, int bytes_per_block, int blockdim, bool *ok) {
    GLuint t;
    glGenTextures(1, &t);
    glBindTexture(GL_TEXTURE_2D, t);
    glGetError();
    if (ifmt == GL_RGBA8) {
        size_t n = (size_t)w * h;
        uint32_t *d = malloc(n * 4);
        for (size_t i = 0; i < n; i++) d[i] = rng();
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, d);
        free(d);
    } else {
        size_t blocks = (size_t)(w / blockdim) * (h / blockdim);
        size_t sz = blocks * bytes_per_block;
        uint8_t *d = malloc(sz);
        if (ifmt == GL_COMPRESSED_RGBA_ASTC_4x4_KHR) {
            /* void-extent (constant colour) ASTC blocks with random colours: valid data, 1 byte/texel */
            for (size_t b = 0; b < blocks; b++) {
                uint64_t lo = 0xFFFFFFFFFFFFFDFCULL;
                uint64_t hi = (uint64_t)(rng() & 0xffff) | ((uint64_t)(rng() & 0xffff) << 16) |
                              ((uint64_t)(rng() & 0xffff) << 32) | (0xffffULL << 48);
                memcpy(d + b * 16, &lo, 8);
                memcpy(d + b * 16 + 8, &hi, 8);
            }
        } else {
            for (size_t i = 0; i < sz; i += 4) { uint32_t r = rng(); memcpy(d + i, &r, 4); }
        }
        glCompressedTexImage2D(GL_TEXTURE_2D, 0, ifmt, w, h, 0, (GLsizei)sz, d);
        free(d);
    }
    GLenum e = glGetError();
    *ok = (e == GL_NO_ERROR);
    if (!*ok) plog("texture format 0x%04x upload failed: GL error 0x%04x\n", ifmt, e);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    return t;
}

static void tex_run(rt_t *rt) {
    test_begin("GPU texture sampling", 90);
    GLuint prog = gl_program(VS_FULL, FS_TEX, "tex", false);
    if (!prog) { test_end(); return; }
    double px = (double)rt->w * rt->h;
    struct { const char *name; GLenum fmt; int bpb, bd; int size; float bytes_per_texel; bool cachefriendly; } cases[] = {
        {"rgba8_256_1to1", GL_RGBA8, 4, 1, 256, 4, true},
        {"rgba8_2048_minified", GL_RGBA8, 4, 1, 2048, 4, false},
        {"etc2_rgb8_2048_minified", GL_COMPRESSED_RGB8_ETC2, 8, 4, 2048, 0.5f, false},
        {"astc4x4_2048_minified", GL_COMPRESSED_RGBA_ASTC_4x4_KHR, 16, 4, 2048, 1, false},
    };
    double res[4] = {0};
    for (int i = 0; i < 4; i++) {
        if (cases[i].fmt == GL_COMPRESSED_RGBA_ASTC_4x4_KHR && !gl_has_ext("GL_KHR_texture_compression_astc_ldr")) {
            plog("tex.%s = skipped (no ASTC extension)\n", cases[i].name);
            continue;
        }
        bool ok;
        GLuint t = make_tex(cases[i].size, cases[i].size, cases[i].fmt, cases[i].bpb, cases[i].bd, &ok);
        if (ok) {
            float sx = cases[i].cachefriendly ? (float)rt->w / cases[i].size : 1.0f;
            float sy = cases[i].cachefriendly ? (float)rt->h / cases[i].size : 1.0f;
            tex_ctx c = {rt, prog, t, sx, sy, 8};
            double tt = time_frames(tex_frame, &c, 0.6);
            res[i] = px * 8 / net(tt) / 1e6;
            plog("tex.%s = %.3f ms/frame (8 layers), %.0f Mtexel/s\n", cases[i].name, tt * 1e3, res[i]);
        }
        glDeleteTextures(1, &t);
    }
    summary("tex Mtexel/s: 1:1 %.0f | 2048 minified rgba8 %.0f etc2 %.0f astc %.0f", res[0], res[1], res[2], res[3]);
    plog("note: ASTC test uses void-extent blocks (valid data, real 1 B/texel reads, simplest decode)\n");
    glDeleteProgram(prog);
    gl_check("tex");
    test_end();
}

/* ======================= ALU ======================= */
typedef struct { rt_t *rt; GLuint prog; } alu_ctx;
static void alu_frame(void *p) {
    alu_ctx *c = p;
    bind_rt(c->rt);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(c->prog);
    glUniform4f(glGetUniformLocation(c->prog, "k"), 0.5f, 0.25f, 0.125f, 0.0625f);
    draw_full();
}

static void alu_run(rt_t *rt) {
    test_begin("GPU shader arithmetic", 60);
    const int ITER = 64;
    double gf[2] = {0};
    const char *precs[] = {"highp", "mediump"};
    for (int i = 0; i < 2; i++) {
        char fs[1024];
        snprintf(fs, sizeof fs,
                 "#version 300 es\nprecision %s float;\nin vec2 uv;\nuniform vec4 k;\nout vec4 o;\n"
                 "void main(){ vec4 a=vec4(uv,uv.yx)*k; vec4 b=k.wzyx*0.5;\n"
                 "  for(int i=0;i<%d;i++){ a=a*b+k; b=b*a+k.yxwz; }\n  o=(a+b)*0.0001; }\n",
                 precs[i], ITER);
        GLuint prog = gl_program(VS_FULL, fs, precs[i], false);
        if (!prog) continue;
        alu_ctx c = {rt, prog};
        double t = time_frames(alu_frame, &c, 0.8);
        double flops = (double)rt->w * rt->h * ITER * 16;
        gf[i] = flops / net(t) / 1e9;
        plog("alu.%s = %.3f ms/frame (%d FMA vec4 pairs/pixel), %.2f GFLOPS\n", precs[i], t * 1e3, ITER, gf[i]);
        glDeleteProgram(prog);
    }
    double per_px = gf[0] * 1e9 / ((double)W * H * 60.0);
    summary("ALU: fp32 %.1f GFLOPS, fp16 %.1f GFLOPS (~%.0f fp32 flops/px @60Hz)", gf[0], gf[1], per_px);
    gl_check("alu");
    test_end();
}

/* ======================= draw call overhead ======================= */
static const char *VS_SMALL =
    "#version 300 es\nlayout(location=0) in vec2 p;\nuniform vec2 off;\n"
    "void main(){ gl_Position=vec4(p*0.01+off,0.0,1.0); }\n";
static const char *VS_INST =
    "#version 300 es\nlayout(location=0) in vec2 p;\n"
    "void main(){ float i=float(gl_InstanceID); vec2 off=vec2(mod(i,40.0)/20.0-1.0, floor(i/40.0)/25.0-1.0);\n"
    "  gl_Position=vec4(p*0.01+off,0.0,1.0); }\n";

typedef struct { rt_t *rt; GLuint prog, vao, vbo; int mode, n; GLint u_off, u_col; } dc_ctx;
static void dc_frame(void *p) {
    dc_ctx *c = p;
    bind_rt(c->rt);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(c->prog);
    glBindVertexArray(c->vao);
    glBindBuffer(GL_ARRAY_BUFFER, c->vbo);
    if (c->mode == 3) {
        glUniform4f(c->u_col, 1, 0.5f, 0.2f, 1);
        glDrawArraysInstanced(GL_TRIANGLES, 0, 3, c->n);
        return;
    }
    static const float tri[6] = {0, 0, 1, 0, 0, 1};
    for (int i = 0; i < c->n; i++) {
        if (c->mode == 1) {
            glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof tri, tri);
        } else if (c->mode == 2) {
            glBufferData(GL_ARRAY_BUFFER, sizeof tri, NULL, GL_STREAM_DRAW);   /* orphan */
            glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof tri, tri);
        }
        glUniform2f(c->u_off, (i % 40) / 20.0f - 1.0f, (i / 40) / 25.0f - 1.0f);
        glUniform4f(c->u_col, (i & 7) / 7.0f, 0.5f, 0.2f, 1);
        glDrawArrays(GL_TRIANGLES, 0, 3);
    }
}

static void drawcall_run(rt_t *rt) {
    test_begin("GPU draw-call overhead", 90);
    GLuint prog = gl_program(VS_SMALL, FS_COLOR, "small", false);
    GLuint pinst = gl_program(VS_INST, FS_COLOR, "inst", false);
    if (!prog || !pinst) { test_end(); return; }
    GLuint vao, vbo;
    glGenVertexArrays(1, &vao);
    glGenBuffers(1, &vbo);
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    static const float tri[6] = {0, 0, 1, 0, 0, 1};
    glBufferData(GL_ARRAY_BUFFER, sizeof tri, tri, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
    const int N = 1000;
    const char *names[] = {"uniform_change", "buffersubdata_same_vbo", "orphan_then_subdata", "instanced"};
    double us[4] = {0};
    for (int m = 0; m < 4; m++) {
        dc_ctx c = {rt, m == 3 ? pinst : prog, vao, vbo, m, N, 0, 0};
        c.u_off = glGetUniformLocation(c.prog, "off");
        c.u_col = glGetUniformLocation(c.prog, "col");
        double t = time_frames(dc_frame, &c, 0.6);
        us[m] = t * 1e6 / N;
        plog("drawcall.%s = %.3f ms per %d draws (%.2f us each)\n", names[m], t * 1e3, N, us[m]);
    }
    summary("draw call: %.1f us plain, %.1f us w/ BufferSubData, %.1f orphaned, %.3f us/instance", us[0], us[1],
            us[2], us[3]);
    summary("  = ~%.0f plain draws fit in a 16.7 ms frame (CPU side)", us[0] > 0 ? 16700.0 / us[0] : 0);
    glDeleteBuffers(1, &vbo);
    glDeleteVertexArrays(1, &vao);
    glDeleteProgram(prog);
    glDeleteProgram(pinst);
    glBindVertexArray(vao_full);
    gl_check("drawcall");
    test_end();
}

/* ======================= render pass breaks ======================= */
typedef struct { rt_t *a, *b; GLuint prog, small; int passes; bool pingpong; } rp_ctx;
static void rp_frame(void *p) {
    rp_ctx *c = p;
    glUseProgram(c->prog);
    glUniform1i(glGetUniformLocation(c->prog, "t"), 0);
    glUniform2f(glGetUniformLocation(c->prog, "sc"), 1, 1);
    glUniform1f(glGetUniformLocation(c->prog, "gain"), 0.9f);
    glActiveTexture(GL_TEXTURE0);
    if (!c->pingpong) {
        bind_rt(c->a);
        glClear(GL_COLOR_BUFFER_BIT);
        glBindTexture(GL_TEXTURE_2D, c->small);
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE);
        for (int i = 0; i < c->passes; i++) draw_full();
        glDisable(GL_BLEND);
    } else {
        for (int i = 0; i < c->passes; i++) {
            rt_t *dst = (i & 1) ? c->b : c->a, *src = (i & 1) ? c->a : c->b;
            bind_rt(dst);
            glClear(GL_COLOR_BUFFER_BIT);
            glBindTexture(GL_TEXTURE_2D, src->tex);
            draw_full();
        }
    }
}

static void renderpass_run(rt_t *rt) {
    test_begin("GPU render-pass cost (tile memory vs DRAM round trips)", 60);
    GLuint prog = gl_program(VS_FULL, FS_TEX, "rp", false);
    rt_t rb;
    if (!prog || !rt_create(&rb, rt->w, rt->h)) { test_end(); return; }
    bool ok;
    GLuint small = make_tex(64, 64, GL_RGBA8, 4, 1, &ok);
    rp_ctx a = {rt, &rb, prog, small, 16, false};
    double t1 = time_frames(rp_frame, &a, 0.6);
    rp_ctx b = {rt, &rb, prog, small, 16, true};
    double t2 = time_frames(rp_frame, &b, 0.6);
    kv("renderpass.16_layers_one_pass_ms", "%.3f", t1 * 1e3);
    kv("renderpass.16_pingpong_passes_ms", "%.3f", t2 * 1e3);
    summary("16 layers in 1 pass: %.2f ms | 16 passes via DRAM: %.2f ms (%.2f ms/pass)", t1 * 1e3, t2 * 1e3,
            (t2 - t1) / 15 * 1e3);
    glDeleteTextures(1, &small);
    rt_destroy(&rb);
    glDeleteProgram(prog);
    gl_check("renderpass");
    test_end();
}

/* ======================= framebuffer fetch ======================= */
typedef struct { rt_t *rt; GLuint prog; int layers; bool fixed_blend; } fbf_ctx;
static void fbf_frame(void *p) {
    fbf_ctx *c = p;
    bind_rt(c->rt);
    glClearColor(0.25f, 0.5f, 0.75f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(c->prog);
    GLint uk = glGetUniformLocation(c->prog, "k"), uc = glGetUniformLocation(c->prog, "col");
    if (c->fixed_blend) { glEnable(GL_BLEND); glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA); }
    for (int i = 0; i < c->layers; i++) {
        if (uk >= 0) glUniform4f(uk, 0.97f, 0.01f, 0, 0);
        if (uc >= 0) glUniform4f(uc, 0.01f, 0.01f, 0.01f, 0.03f);
        draw_full();
    }
    glDisable(GL_BLEND);
}

static void fbfetch_run(rt_t *rt) {
    test_begin("GPU framebuffer fetch", 60);
    const char *fs_arm =
        "#version 300 es\n#extension GL_ARM_shader_framebuffer_fetch : require\nprecision mediump float;\n"
        "uniform vec4 k;\nout vec4 o;\nvoid main(){ o = gl_LastFragColorARM*k.x + vec4(k.y); }\n";
    const char *fs_ext =
        "#version 300 es\n#extension GL_EXT_shader_framebuffer_fetch : require\nprecision mediump float;\n"
        "uniform vec4 k;\nlayout(location=0) inout vec4 o;\nvoid main(){ o = o*k.x + vec4(k.y); }\n";
    struct { const char *ext, *fs, *name; } v[2] = {{"GL_ARM_shader_framebuffer_fetch", fs_arm, "arm"},
                                                     {"GL_EXT_shader_framebuffer_fetch", fs_ext, "ext"}};
    GLuint pfixed = gl_program(VS_FULL, FS_COLOR, "fixedblend", false);
    fbf_ctx fc = {rt, pfixed, 16, true};
    double tfixed = pfixed ? time_frames(fbf_frame, &fc, 0.5) : 0;
    kv("fbfetch.fixed_function_blend_16_layers_ms", "%.3f", tfixed * 1e3);
    char result[2][48] = {"not exposed", "not exposed"};
    for (int i = 0; i < 2; i++) {
        if (!gl_has_ext(v[i].ext)) continue;
        GLuint p = gl_program(VS_FULL, v[i].fs, v[i].name, false);
        if (!p) { snprintf(result[i], 48, "compile failed"); continue; }
        /* correctness: clear (0.25,0.5,0.75,1) then o = last*2 - 0.1 */
        bind_rt(rt);
        glClearColor(0.25f, 0.5f, 0.75f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        glUseProgram(p);
        glUniform4f(glGetUniformLocation(p, "k"), 2.0f, -0.1f, 0, 0);
        draw_full();
        uint8_t px[4];
        read_center(px);
        int exp[4] = {102, 230, 255, 255};
        bool good = true;
        for (int c = 0; c < 4; c++) if (abs(px[c] - exp[c]) > 3) good = false;
        plog("fbfetch.%s readback = %d %d %d %d (expected %d %d %d %d) -> %s\n", v[i].name, px[0], px[1], px[2],
             px[3], exp[0], exp[1], exp[2], exp[3], good ? "CORRECT" : "WRONG");
        fbf_ctx c = {rt, p, 16, false};
        double t = time_frames(fbf_frame, &c, 0.5);
        kv(i ? "fbfetch.ext_16_layers_ms" : "fbfetch.arm_16_layers_ms", "%.3f", t * 1e3);
        snprintf(result[i], 48, "%s %.2fms", good ? "works" : "WRONG", t * 1e3);
        glDeleteProgram(p);
    }
    summary("fb fetch: ARM %s | EXT %s | fixed blend %.2fms (16 layers)", result[0], result[1], tfixed * 1e3);
    if (pfixed) glDeleteProgram(pfixed);
    gl_check("fbfetch");
    test_end();
}

/* ======================= deferred lighting: PLS vs MRT vs forward ======================= */
#define NLIGHTS 16
static float L_dir[NLIGHTS][3], L_col[NLIGHTS][3];

static void lights_init(void) {
    for (int i = 0; i < NLIGHTS; i++) {
        float a = (float)i * 6.2831853f / NLIGHTS;
        L_dir[i][0] = 0.6f * cosf(a); L_dir[i][1] = 0.6f * sinf(a); L_dir[i][2] = 0.8f;
        L_col[i][0] = 0.04f; L_col[i][1] = 0.035f; L_col[i][2] = 0.03f;
    }
}

#define PLS_BLOCK " FragData { layout(rgba8) mediump vec4 albedo; layout(rgba8) mediump vec4 normal; " \
                  "layout(r11f_g11f_b10f) mediump vec3 light; } pls;\n"
#define NORMAL_FN "vec3 surf_normal(vec2 uv){ return normalize(vec3(sin(uv.x*40.0)*0.4, cos(uv.y*30.0)*0.4, 1.0)); }\n"

static const char *FS_PLS_G =
    "#version 300 es\n#extension GL_EXT_shader_pixel_local_storage : require\nprecision mediump float;\n"
    "in vec2 uv;\n__pixel_local_outEXT" PLS_BLOCK "uniform vec4 alb; uniform vec3 nrm; uniform float proc;\n" NORMAL_FN
    "void main(){ vec3 n = mix(nrm, surf_normal(uv), proc); pls.albedo = alb;\n"
    "  pls.normal = vec4(n*0.5+0.5, 1.0); pls.light = vec3(0.0); }\n";
static const char *FS_PLS_L =
    "#version 300 es\n#extension GL_EXT_shader_pixel_local_storage : require\nprecision mediump float;\n"
    "__pixel_localEXT" PLS_BLOCK "uniform vec3 ldir; uniform vec3 lcol;\n"
    "void main(){ vec3 n = pls.normal.xyz*2.0-1.0; pls.light += max(dot(n, ldir), 0.0)*lcol; }\n";
static const char *FS_PLS_R =
    "#version 300 es\n#extension GL_EXT_shader_pixel_local_storage : require\nprecision mediump float;\n"
    "__pixel_local_inEXT" PLS_BLOCK "out vec4 o;\n"
    "void main(){ o = vec4(pls.albedo.rgb*pls.light, 1.0); }\n";

static const char *FS_MRT_G =
    "#version 300 es\nprecision mediump float;\nin vec2 uv;\nuniform vec4 alb; uniform vec3 nrm; uniform float proc;\n"
    NORMAL_FN "layout(location=0) out vec4 o0;\nlayout(location=1) out vec4 o1;\n"
    "void main(){ vec3 n = mix(nrm, surf_normal(uv), proc); o0 = alb; o1 = vec4(n*0.5+0.5, 1.0); }\n";
static const char *FS_MRT_L =
    "#version 300 es\nprecision mediump float;\nin vec2 uv;\nuniform sampler2D tn; uniform vec3 ldir; uniform vec3 lcol;\n"
    "out vec4 o;\nvoid main(){ vec3 n = texture(tn, uv).xyz*2.0-1.0; o = vec4(max(dot(n, ldir), 0.0)*lcol, 1.0); }\n";
static const char *FS_MRT_C =
    "#version 300 es\nprecision mediump float;\nin vec2 uv;\nuniform sampler2D ta; uniform sampler2D tl;\nout vec4 o;\n"
    "void main(){ o = vec4(texture(ta, uv).rgb*texture(tl, uv).rgb, 1.0); }\n";
static const char *FS_FWD =
    "#version 300 es\nprecision mediump float;\nin vec2 uv;\nuniform vec4 alb; uniform vec3 nrm; uniform float proc;\n"
    "uniform vec3 ldir[16]; uniform vec3 lcol[16];\n" NORMAL_FN "out vec4 o;\n"
    "void main(){ vec3 n = mix(nrm, surf_normal(uv), proc); vec3 l = vec3(0.0);\n"
    "  for(int i=0;i<16;i++) l += max(dot(n, ldir[i]), 0.0)*lcol[i];\n  o = vec4(alb.rgb*l, 1.0); }\n";

typedef struct {
    rt_t *out;
    GLuint pg, pl, pr;              /* PLS */
    GLuint mg, ml, mc;              /* MRT */
    GLuint gfbo, talb, tnrm, lfbo, tlight;
    GLuint fwd;
    float proc;
} lit_ctx;

static void set_surface_uniforms(GLuint p, float proc) {
    glUniform4f(glGetUniformLocation(p, "alb"), 0.8f, 0.6f, 1.0f, 1.0f);
    glUniform3f(glGetUniformLocation(p, "nrm"), 0, 0, 1);
    glUniform1f(glGetUniformLocation(p, "proc"), proc);
}

static void pls_frame(void *p) {
    lit_ctx *c = p;
    bind_rt(c->out);
    glClear(GL_COLOR_BUFFER_BIT);
    glEnable(GL_SHADER_PIXEL_LOCAL_STORAGE_EXT);
    glUseProgram(c->pg);
    set_surface_uniforms(c->pg, c->proc);
    draw_full();
    glUseProgram(c->pl);
    GLint ud = glGetUniformLocation(c->pl, "ldir"), uc = glGetUniformLocation(c->pl, "lcol");
    for (int i = 0; i < NLIGHTS; i++) {
        glUniform3fv(ud, 1, L_dir[i]);
        glUniform3fv(uc, 1, L_col[i]);
        draw_full();
    }
    glUseProgram(c->pr);
    draw_full();
    glDisable(GL_SHADER_PIXEL_LOCAL_STORAGE_EXT);
}

static void mrt_frame(void *p) {
    lit_ctx *c = p;
    glBindFramebuffer(GL_FRAMEBUFFER, c->gfbo);
    glViewport(0, 0, c->out->w, c->out->h);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(c->mg);
    set_surface_uniforms(c->mg, c->proc);
    draw_full();
    glBindFramebuffer(GL_FRAMEBUFFER, c->lfbo);
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(c->ml);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, c->tnrm);
    glUniform1i(glGetUniformLocation(c->ml, "tn"), 0);
    GLint ud = glGetUniformLocation(c->ml, "ldir"), uc = glGetUniformLocation(c->ml, "lcol");
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    for (int i = 0; i < NLIGHTS; i++) {
        glUniform3fv(ud, 1, L_dir[i]);
        glUniform3fv(uc, 1, L_col[i]);
        draw_full();
    }
    glDisable(GL_BLEND);
    bind_rt(c->out);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(c->mc);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, c->talb);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, c->tlight);
    glUniform1i(glGetUniformLocation(c->mc, "ta"), 0);
    glUniform1i(glGetUniformLocation(c->mc, "tl"), 1);
    draw_full();
    glActiveTexture(GL_TEXTURE0);
}

static void fwd_frame(void *p) {
    lit_ctx *c = p;
    bind_rt(c->out);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(c->fwd);
    set_surface_uniforms(c->fwd, c->proc);
    glUniform3fv(glGetUniformLocation(c->fwd, "ldir"), NLIGHTS, &L_dir[0][0]);
    glUniform3fv(glGetUniformLocation(c->fwd, "lcol"), NLIGHTS, &L_col[0][0]);
    draw_full();
}

static GLuint tex_rgba8(int w, int h) {
    GLuint t;
    glGenTextures(1, &t);
    glBindTexture(GL_TEXTURE_2D, t);
    glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGBA8, w, h);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    return t;
}

static bool check_lit(const char *name, int expect[3]) {
    uint8_t px[4];
    read_center(px);
    bool good = abs(px[0] - expect[0]) <= 10 && abs(px[1] - expect[1]) <= 10 && abs(px[2] - expect[2]) <= 10;
    plog("lighting.%s readback = %d %d %d (expected ~%d %d %d) -> %s\n", name, px[0], px[1], px[2], expect[0],
         expect[1], expect[2], good ? "CORRECT" : "WRONG");
    return good;
}

static void lighting_run(rt_t *rt) {
    test_begin("GPU deferred lighting: pixel local storage vs MRT vs forward", 90);
    lights_init();
    /* CPU expectation for the constant-normal case: n = (0,0,1) */
    float sum[3] = {0, 0, 0};
    for (int i = 0; i < NLIGHTS; i++)
        for (int c = 0; c < 3; c++) sum[c] += L_dir[i][2] * L_col[i][c];
    float alb[3] = {0.8f, 0.6f, 1.0f};
    int expect[3];
    for (int c = 0; c < 3; c++) expect[c] = (int)lroundf(fminf(alb[c] * sum[c], 1.0f) * 255.0f);

    lit_ctx c = {0};
    c.out = rt;
    double t_pls = 0, t_mrt = 0, t_fwd = 0;
    char pls_res[48] = "not exposed", mrt_res[48] = "failed", fwd_res[48] = "failed";

    if (gl_has_ext("GL_EXT_shader_pixel_local_storage")) {
        c.pg = gl_program(VS_FULL, FS_PLS_G, "pls_g", false);
        c.pl = gl_program(VS_FULL, FS_PLS_L, "pls_l", false);
        c.pr = gl_program(VS_FULL, FS_PLS_R, "pls_r", false);
        if (c.pg && c.pl && c.pr) {
            c.proc = 0;
            pls_frame(&c);
            gl_check("pls frame");
            bool good = check_lit("pls", expect);
            c.proc = 1;
            t_pls = time_frames(pls_frame, &c, 0.6);
            snprintf(pls_res, sizeof pls_res, "%.2f ms%s", t_pls * 1e3, good ? "" : " (WRONG)");
        } else {
            snprintf(pls_res, sizeof pls_res, "compile failed");
        }
    }

    c.mg = gl_program(VS_FULL, FS_MRT_G, "mrt_g", false);
    c.ml = gl_program(VS_FULL, FS_MRT_L, "mrt_l", false);
    c.mc = gl_program(VS_FULL, FS_MRT_C, "mrt_c", false);
    if (c.mg && c.ml && c.mc) {
        c.talb = tex_rgba8(rt->w, rt->h);
        c.tnrm = tex_rgba8(rt->w, rt->h);
        c.tlight = tex_rgba8(rt->w, rt->h);
        glGenFramebuffers(1, &c.gfbo);
        glBindFramebuffer(GL_FRAMEBUFFER, c.gfbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, c.talb, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, c.tnrm, 0);
        GLenum bufs[2] = {GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1};
        glDrawBuffers(2, bufs);
        GLenum s1 = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        glGenFramebuffers(1, &c.lfbo);
        glBindFramebuffer(GL_FRAMEBUFFER, c.lfbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, c.tlight, 0);
        GLenum s2 = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (s1 == GL_FRAMEBUFFER_COMPLETE && s2 == GL_FRAMEBUFFER_COMPLETE) {
            c.proc = 0;
            mrt_frame(&c);
            bool good = check_lit("mrt", expect);
            c.proc = 1;
            t_mrt = time_frames(mrt_frame, &c, 0.6);
            snprintf(mrt_res, sizeof mrt_res, "%.2f ms%s", t_mrt * 1e3, good ? "" : " (WRONG)");
        } else {
            plog("MRT framebuffers incomplete: 0x%x 0x%x\n", s1, s2);
        }
    }

    c.fwd = gl_program(VS_FULL, FS_FWD, "forward", false);
    if (c.fwd) {
        c.proc = 0;
        fwd_frame(&c);
        bool good = check_lit("forward", expect);
        c.proc = 1;
        t_fwd = time_frames(fwd_frame, &c, 0.6);
        snprintf(fwd_res, sizeof fwd_res, "%.2f ms%s", t_fwd * 1e3, good ? "" : " (WRONG)");
    }
    kv("lighting.pls_ms", "%.3f", t_pls * 1e3);
    kv("lighting.mrt_ms", "%.3f", t_mrt * 1e3);
    kv("lighting.forward_ms", "%.3f", t_fwd * 1e3);
    summary("16 lights @%dx%d: PLS %s | MRT %s | forward %s", rt->w, rt->h, pls_res, mrt_res, fwd_res);

    GLuint progs[] = {c.pg, c.pl, c.pr, c.mg, c.ml, c.mc, c.fwd};
    for (size_t i = 0; i < sizeof progs / sizeof progs[0]; i++) if (progs[i]) glDeleteProgram(progs[i]);
    GLuint texs[] = {c.talb, c.tnrm, c.tlight};
    glDeleteTextures(3, texs);
    if (c.gfbo) glDeleteFramebuffers(1, &c.gfbo);
    if (c.lfbo) glDeleteFramebuffers(1, &c.lfbo);
    gl_check("lighting");
    test_end();
}

/* ======================= texture upload ======================= */
static void upload_run(void) {
    test_begin("GPU texture upload", 60);
    const int S = 2048;
    uint32_t *d = malloc((size_t)S * S * 4);
    for (size_t i = 0; i < (size_t)S * S; i++) d[i] = rng();
    GLuint t;
    glGenTextures(1, &t);
    glBindTexture(GL_TEXTURE_2D, t);
    glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGBA8, S, S);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, S, S, GL_RGBA, GL_UNSIGNED_BYTE, d);
    glFinish();
    double t0 = now_s();
    for (int i = 0; i < 5; i++) glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, S, S, GL_RGBA, GL_UNSIGNED_BYTE, d);
    glFinish();
    double dt = (now_s() - t0) / 5;
    double mbs = (double)S * S * 4 / dt / 1e6;
    kv("upload.rgba8_2048_ms", "%.2f", dt * 1e3);
    summary("texture upload: %.0f MB/s (2048x2048 RGBA8 in %.1f ms)", mbs, dt * 1e3);
    glDeleteTextures(1, &t);
    free(d);
    gl_check("upload");
    test_end();
}

void gpu_tests_run(void) {
    W = gfx_w; H = gfx_h;
    caps_run();
    if (g_gles_major < 3 || !glGenVertexArrays || !glTexStorage2D) {
        summary("GPU benchmarks skipped: needs OpenGL ES 3.0 (got %d.%d)", g_gles_major, g_gles_minor);
        return;
    }
    glGenVertexArrays(1, &vao_full);
    glBindVertexArray(vao_full);
    glGenBuffers(1, &vbo_full);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_full);
    static const float tri[6] = {-1, -1, 3, -1, -1, 3};
    glBufferData(GL_ARRAY_BUFFER, sizeof tri, tri, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
    glBindVertexArray(0);
    rt_t rt;
    if (!rt_create(&rt, W, H)) { summary("GPU benchmarks skipped: FBO creation failed"); return; }
    if (!probe_aborted()) fill_run(&rt);
    if (!probe_aborted()) tex_run(&rt);
    if (!probe_aborted()) alu_run(&rt);
    if (!probe_aborted()) drawcall_run(&rt);
    if (!probe_aborted()) renderpass_run(&rt);
    if (!probe_aborted()) fbfetch_run(&rt);
    if (!probe_aborted()) lighting_run(&rt);
    if (!probe_aborted()) upload_run();
    rt_destroy(&rt);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

/* ======================= display / vsync ======================= */
static int cmp_d(const void *a, const void *b) {
    double x = *(const double *)a, y = *(const double *)b;
    return x < y ? -1 : x > y;
}

void display_test_run(void) {
    test_begin("Display refresh and present cost", 60);
    const int N = 240;
    double *dt = malloc(sizeof(double) * N), *sw = malloc(sizeof(double) * N);
    q_SDL_GL_SetSwapInterval(1);
    kv("display.swap_interval", "%d", q_SDL_GL_GetSwapInterval());
    for (int i = 0; i < 20; i++) { ui_begin_frame(0x000000ff); q_SDL_GL_SwapWindow(g_win); }
    double prev = now_s();
    for (int i = 0; i < N; i++) {
        ui_begin_frame((i & 1) ? 0x202020ff : 0x101010ff);
        ui_textf(FONT_L, 40, gfx_h / 2 - 18, 0xffffffff, "vsync test %d/%d", i + 1, N);
        ui_flush();
        double a = now_s();
        q_SDL_GL_SwapWindow(g_win);
        double b = now_s();
        sw[i] = b - a;
        dt[i] = b - prev;
        prev = b;
    }
    qsort(dt, N, sizeof(double), cmp_d);
    qsort(sw, N, sizeof(double), cmp_d);
    double med = dt[N / 2];
    kv("display.frame_interval_ms", "p5 %.3f | median %.3f | p95 %.3f | max %.3f", dt[N / 20] * 1e3, med * 1e3,
       dt[N - N / 20] * 1e3, dt[N - 1] * 1e3);
    kv("display.swap_call_ms", "median %.3f | p95 %.3f", sw[N / 2] * 1e3, sw[N - N / 20] * 1e3);
    double hz = med > 0 ? 1.0 / med : 0;
    /* unthrottled */
    int r = q_SDL_GL_SetSwapInterval(0);
    double t0 = now_s();
    int frames = 0;
    if (r == 0) {
        while (now_s() - t0 < 1.5) {
            ui_begin_frame((frames & 1) ? 0x202020ff : 0x101010ff);
            q_SDL_GL_SwapWindow(g_win);
            frames++;
        }
    }
    double fps0 = r == 0 ? frames / (now_s() - t0) : 0;
    kv("display.swap_interval0_supported", "%s", r == 0 ? "yes" : "no");
    kv("display.unthrottled_clear_fps", "%.1f", fps0);
    q_SDL_GL_SetSwapInterval(1);
    summary("display: %.2f Hz vsync (median %.2f ms), swap call %.2f ms, no-vsync %.0f fps", hz, med * 1e3,
            sw[N / 2] * 1e3, fps0);
    /* every other display mode the panel offers: switch to it (real fullscreen) and measure */
    int nm = q_SDL_GetNumDisplayModes(0);
    char modes_line[200] = "";
    for (int m = 0; m < nm && m < 8; m++) {
        SDL_DisplayMode dm;
        if (q_SDL_GetDisplayMode(0, m, &dm) != 0) continue;
        if (q_SDL_SetWindowDisplayMode(g_win, &dm) != 0 || q_SDL_SetWindowFullscreen(g_win, SDL_WINDOW_FULLSCREEN) != 0) {
            plog("display.mode%d %dx%d@%d: switch failed: %s\n", m, dm.w, dm.h, dm.refresh_rate, q_SDL_GetError());
            continue;
        }
        for (int i = 0; i < 30; i++) { ui_begin_frame(0x000000ff); ui_textf(FONT_L, 40, gfx_h / 2 - 18, 0xffffffff, "mode %d: %d Hz", m, dm.refresh_rate); ui_flush(); q_SDL_GL_SwapWindow(g_win); }
        double pv = now_s();
        for (int i = 0; i < 120; i++) {
            ui_begin_frame((i & 1) ? 0x202020ff : 0x101010ff);
            ui_textf(FONT_L, 40, gfx_h / 2 - 18, 0xffffffff, "mode %d: %d Hz", m, dm.refresh_rate);
            ui_flush();
            q_SDL_GL_SwapWindow(g_win);
            double t = now_s();
            dt[i] = t - pv;
            pv = t;
        }
        qsort(dt, 120, sizeof(double), cmp_d);
        double mhz = dt[60] > 0 ? 1.0 / dt[60] : 0;
        plog("display.mode%d %dx%d@%d measured = %.3f Hz (median frame %.3f ms)\n", m, dm.w, dm.h, dm.refresh_rate, mhz,
             dt[60] * 1e3);
        char t[40];
        snprintf(t, sizeof t, "%s%d->%.2f", modes_line[0] ? ", " : "", dm.refresh_rate, mhz);
        strncat(modes_line, t, sizeof modes_line - strlen(modes_line) - 1);
    }
    q_SDL_SetWindowFullscreen(g_win, SDL_WINDOW_FULLSCREEN_DESKTOP);
    if (modes_line[0]) summary("display modes (listed Hz -> measured): %s", modes_line);
    free(dt);
    free(sw);
    test_end();
}
