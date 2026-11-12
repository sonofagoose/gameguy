/* gameguy probe — SDL2/GLES runtime loading, window/context creation, text UI. */
#include "probe.h"
#include <dlfcn.h>
#include "font_atlas.h"

#define SDL_DEF(n) __typeof__(n) *q_##n;
SDL_FUNCS(SDL_DEF)
#define GL_DEF(T, n) T n;
GL_FUNCS(GL_DEF)
GL3_FUNCS(GL_DEF)

SDL_Window *g_win;
static SDL_GLContext g_ctx;
int gfx_w = 640, gfx_h = 480;
int g_gles_major, g_gles_minor;
bool g_gfx_ok;
char g_gl_renderer[128] = "no GPU context";
SDL_Joystick *g_js[MAX_PADS];
SDL_GameController *g_gc[MAX_PADS];
int g_npads;

static void *sdl_lib;
static bool sdl_ok;

bool sdl_load(void) {
    section("SDL2 runtime");
    const char *names[] = {"libSDL2-2.0.so.0", "libSDL2.so", NULL};
    for (int i = 0; names[i] && !sdl_lib; i++) sdl_lib = dlopen(names[i], RTLD_NOW | RTLD_GLOBAL);
    if (!sdl_lib) { plog("dlopen SDL2 failed: %s\n", dlerror()); return false; }
    int missing = 0;
#define SDL_LOAD(n) q_##n = (__typeof__(q_##n))dlsym(sdl_lib, #n); if (!q_##n) { plog("missing SDL symbol: %s\n", #n); missing++; }
    SDL_FUNCS(SDL_LOAD)
    Dl_info info;
    if (q_SDL_Init && dladdr((void *)q_SDL_Init, &info)) kv("sdl.library", "%s", info.dli_fname);
    if (q_SDL_GetVersion) {
        SDL_version v;
        q_SDL_GetVersion(&v);
        kv("sdl.version", "%d.%d.%d", v.major, v.minor, v.patch);
    }
    if (missing) { plog("SDL2 is missing %d required symbols\n", missing); return false; }
    kv("sdl.platform", "%s", q_SDL_GetPlatform());
    kv("sdl.cpu_count", "%d", q_SDL_GetCPUCount());
    kv("sdl.has_neon", "%d", (int)q_SDL_HasNEON());
    kv("sdl.system_ram_mb", "%d", q_SDL_GetSystemRAM());
    sdl_ok = true;
    return true;
}

static void *gles_lib;
static void *gl_proc(const char *name) {
    void *p = q_SDL_GL_GetProcAddress(name);
    if (!p) {
        if (!gles_lib) gles_lib = dlopen("libGLESv2.so.2", RTLD_NOW | RTLD_NOLOAD);
        if (!gles_lib) gles_lib = dlopen("libGLESv2.so.2", RTLD_NOW);
        if (!gles_lib) gles_lib = dlopen("libGLESv2.so", RTLD_NOW);
        if (gles_lib) p = dlsym(gles_lib, name);
    }
    return p;
}

void gl_check(const char *where) {
    if (!glGetError) return;
    for (int i = 0; i < 8; i++) {
        GLenum e = glGetError();
        if (e == GL_NO_ERROR) break;
        plog("GL error 0x%04x at %s\n", e, where);
    }
}

static char *g_ext_cache;
bool gl_has_ext(const char *name) {
    if (!g_ext_cache) return false;
    size_t n = strlen(name);
    for (const char *p = g_ext_cache; (p = strstr(p, name)); p += n)
        if ((p == g_ext_cache || p[-1] == ' ') && (p[n] == ' ' || p[n] == 0)) return true;
    return false;
}

static GLuint compile(GLenum type, const char *src, const char *name, bool quiet) {
    GLuint s = glCreateShader(type);
    glShaderSource(s, 1, &src, NULL);
    glCompileShader(s);
    GLint ok = 0;
    glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char log[2048] = "";
        glGetShaderInfoLog(s, sizeof log, NULL, log);
        if (!quiet) plog("shader compile FAILED (%s, %s): %s\n", name, type == GL_VERTEX_SHADER ? "vs" : "fs", log);
        glDeleteShader(s);
        return 0;
    }
    return s;
}

GLuint gl_program(const char *vs, const char *fs, const char *name, bool quiet) {
    GLuint v = compile(GL_VERTEX_SHADER, vs, name, quiet);
    GLuint f = compile(GL_FRAGMENT_SHADER, fs, name, quiet);
    if (!v || !f) { if (v) glDeleteShader(v); if (f) glDeleteShader(f); return 0; }
    GLuint p = glCreateProgram();
    glAttachShader(p, v);
    glAttachShader(p, f);
    glBindAttribLocation(p, 0, "a_pos");
    glBindAttribLocation(p, 1, "a_uv");
    glBindAttribLocation(p, 2, "a_col");
    glLinkProgram(p);
    glDeleteShader(v);
    glDeleteShader(f);
    GLint ok = 0;
    glGetProgramiv(p, GL_LINK_STATUS, &ok);
    if (!ok) {
        char log[2048] = "";
        glGetProgramInfoLog(p, sizeof log, NULL, log);
        if (!quiet) plog("program link FAILED (%s): %s\n", name, log);
        glDeleteProgram(p);
        return 0;
    }
    return p;
}

/* ---------- text UI ---------- */
typedef struct { float *v; int n, cap; GLuint tex; int tw, th, cw, ch; } batch_t;
static batch_t ui_b[2];
static GLuint ui_prog, ui_vbo;
static GLint ui_u_scr, ui_u_tex;
static char ui_lines[64][112];
static int ui_nlines, ui_step, ui_steps;
static char ui_stat[128];
static double ui_t0;

static const char *UI_VS =
    "attribute vec2 a_pos; attribute vec2 a_uv; attribute vec4 a_col;\n"
    "uniform vec2 u_scr; varying vec2 v_uv; varying vec4 v_col;\n"
    "void main(){ v_uv=a_uv; v_col=a_col; vec2 p=a_pos/u_scr*2.0-1.0; gl_Position=vec4(p.x,-p.y,0.0,1.0); }\n";
static const char *UI_FS =
    "precision mediump float; varying vec2 v_uv; varying vec4 v_col; uniform sampler2D u_tex;\n"
    "void main(){ gl_FragColor = vec4(v_col.rgb, v_col.a*texture2D(u_tex, v_uv).a); }\n";

static GLuint make_font_tex(const uint8_t *px, int w, int h, int cw, int ch) {
    uint8_t *copy = malloc((size_t)w * h);
    memcpy(copy, px, (size_t)w * h);
    /* cell of char 127 (index 95) becomes solid: used for rectangles */
    int cx = (95 % 16) * cw, cy = (95 / 16) * ch;
    for (int y = cy; y < cy + ch && y < h; y++)
        for (int x = cx; x < cx + cw && x < w; x++) copy[y * w + x] = 255;
    GLuint t;
    glGenTextures(1, &t);
    glBindTexture(GL_TEXTURE_2D, t);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, w, h, 0, GL_ALPHA, GL_UNSIGNED_BYTE, copy);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
    free(copy);
    return t;
}

static void ui_init(void) {
    ui_prog = gl_program(UI_VS, UI_FS, "ui", false);
    ui_u_scr = glGetUniformLocation(ui_prog, "u_scr");
    ui_u_tex = glGetUniformLocation(ui_prog, "u_tex");
    glGenBuffers(1, &ui_vbo);
    ui_b[0] = (batch_t){0};
    ui_b[0].tex = make_font_tex(font_small_pixels, FONT_SMALL_W, FONT_SMALL_H, FONT_SMALL_CW, FONT_SMALL_CH);
    ui_b[0].tw = FONT_SMALL_W; ui_b[0].th = FONT_SMALL_H; ui_b[0].cw = FONT_SMALL_CW; ui_b[0].ch = FONT_SMALL_CH;
    ui_b[1] = (batch_t){0};
    ui_b[1].tex = make_font_tex(font_large_pixels, FONT_LARGE_W, FONT_LARGE_H, FONT_LARGE_CW, FONT_LARGE_CH);
    ui_b[1].tw = FONT_LARGE_W; ui_b[1].th = FONT_LARGE_H; ui_b[1].cw = FONT_LARGE_CW; ui_b[1].ch = FONT_LARGE_CH;
    ui_t0 = now_s();
    gl_check("ui_init");
}

static void push_quad(batch_t *b, float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1,
                      uint32_t c) {
    if (b->n + 6 > b->cap) {
        b->cap = b->cap ? b->cap * 2 : 6 * 512;
        b->v = realloc(b->v, sizeof(float) * 8 * b->cap);
    }
    float r = ((c >> 24) & 255) / 255.f, g = ((c >> 16) & 255) / 255.f, bl = ((c >> 8) & 255) / 255.f,
          a = (c & 255) / 255.f;
    float q[6][4] = {{x0, y0, u0, v0}, {x1, y0, u1, v0}, {x1, y1, u1, v1},
                     {x0, y0, u0, v0}, {x1, y1, u1, v1}, {x0, y1, u0, v1}};
    for (int i = 0; i < 6; i++) {
        float *o = b->v + 8 * (b->n++);
        o[0] = q[i][0]; o[1] = q[i][1]; o[2] = q[i][2]; o[3] = q[i][3];
        o[4] = r; o[5] = g; o[6] = bl; o[7] = a;
    }
}

void ui_text(int font, float x, float y, uint32_t rgba, const char *s) {
    if (!g_gfx_ok || !ui_prog) return;
    batch_t *b = &ui_b[font ? 1 : 0];
    for (; *s; s++) {
        unsigned char c = (unsigned char)*s;
        if (c == '\n') continue;
        if (c >= 32 && c < 127 && c != ' ') {
            int i = c - 32, cx = (i % 16) * b->cw, cy = (i / 16) * b->ch;
            push_quad(b, x, y, x + b->cw, y + b->ch, (float)cx / b->tw, (float)cy / b->th,
                      (float)(cx + b->cw) / b->tw, (float)(cy + b->ch) / b->th, rgba);
        }
        x += b->cw;
    }
}

void ui_textf(int font, float x, float y, uint32_t rgba, const char *fmt, ...) {
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    ui_text(font, x, y, rgba, buf);
}

void ui_rect(float x, float y, float w, float h, uint32_t rgba) {
    if (!g_gfx_ok || !ui_prog) return;
    batch_t *b = &ui_b[0];
    int cx = (95 % 16) * b->cw + b->cw / 2, cy = (95 / 16) * b->ch + b->ch / 2;
    float u = (cx + 0.5f) / b->tw, v = (cy + 0.5f) / b->th;
    push_quad(b, x, y, x + w, y + h, u, v, u, v, rgba);
}

void ui_flush(void) {
    if (!g_gfx_ok || !ui_prog) return;
    if (glBindVertexArray) glBindVertexArray(0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glViewport(0, 0, gfx_w, gfx_h);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glUseProgram(ui_prog);
    glUniform2f(ui_u_scr, (float)gfx_w, (float)gfx_h);
    glUniform1i(ui_u_tex, 0);
    glActiveTexture(GL_TEXTURE0);
    glBindBuffer(GL_ARRAY_BUFFER, ui_vbo);
    for (int k = 0; k < 2; k++) {
        batch_t *b = &ui_b[k];
        if (!b->n) continue;
        glBindTexture(GL_TEXTURE_2D, b->tex);
        glBufferData(GL_ARRAY_BUFFER, sizeof(float) * 8 * b->n, b->v, GL_STREAM_DRAW);
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 32, (void *)0);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 32, (void *)8);
        glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, 32, (void *)16);
        glDrawArrays(GL_TRIANGLES, 0, b->n);
        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);
        glDisableVertexAttribArray(2);
        b->n = 0;
    }
    glDisable(GL_BLEND);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void ui_begin_frame(uint32_t c) {
    if (!g_gfx_ok) return;
    if (glBindVertexArray) glBindVertexArray(0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glViewport(0, 0, gfx_w, gfx_h);
    glClearColor(((c >> 24) & 255) / 255.f, ((c >> 16) & 255) / 255.f, ((c >> 8) & 255) / 255.f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT);
}

void ui_present(void) {
    if (!g_gfx_ok) { ui_poll(); return; }
    ui_flush();
    q_SDL_GL_SwapWindow(g_win);
    ui_poll();
}

void ui_status(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(ui_stat, sizeof ui_stat, fmt, ap);
    va_end(ap);
}

void ui_progress(int step, int steps) { ui_step = step; ui_steps = steps; }

void ui_add_line(const char *s) {
    if (ui_nlines == 64) { memmove(ui_lines[0], ui_lines[1], sizeof ui_lines[0] * 63); ui_nlines = 63; }
    snprintf(ui_lines[ui_nlines++], sizeof ui_lines[0], "%s", s);
}

void ui_frame(void) {
    if (!g_gfx_ok) { ui_poll(); return; }
    ui_begin_frame(0x10141aff);
    ui_text(FONT_L, 16, 8, 0xffffffff, "GAMEGUY PROBE");
    ui_textf(FONT_S, gfx_w - 9 * 12, 18, 0x8aa0b4ff, "step %2d/%-2d", ui_step, ui_steps);
    ui_textf(FONT_S, 16, 48, 0x8aa0b4ff, "unit %s  |  %.62s", g_unit_id, g_gl_renderer);
    ui_rect(16, 74, (float)gfx_w - 32, 1, 0x34404cff);
    int rows = (gfx_h - 84 - 92) / 22;
    if (rows < 1) rows = 1;
    int first = ui_nlines > rows ? ui_nlines - rows : 0;
    for (int i = first; i < ui_nlines; i++)
        ui_text(FONT_S, 16, 82 + (i - first) * 22, 0xdce6eeff, ui_lines[i]);
    float bar = ui_steps ? (float)(ui_step - 1) / ui_steps : 0;
    ui_rect(16, gfx_h - 84, (float)gfx_w - 32, 6, 0x23303bff);
    ui_rect(16, gfx_h - 84, ((float)gfx_w - 32) * bar, 6, 0x5fb3ffff);
    static const char *spin = "|/-\\";
    int si = (int)((now_s() - ui_t0) * 8) & 3;
    ui_textf(FONT_S, 16, gfx_h - 70, 0xffd36bff, "%c %.66s", spin[si], ui_stat);
    char snap[160];
    telem_snapshot_line(snap, sizeof snap);
    ui_textf(FONT_S, 16, gfx_h - 46, 0x8aa0b4ff, "%.68s", snap);
    ui_text(FONT_S, 16, gfx_h - 24, 0x5d6d7aff, "Hold SELECT+START to skip remaining tests");
    ui_present();
}

/* ---------- input state for skip/exit ---------- */
static double combo_since, any_since;
static bool combo_now, any_now, abort_enabled = true;

void ui_set_abort_enabled(bool on) { abort_enabled = on; combo_since = 0; }

void ui_poll(void) {
    if (!sdl_ok) return;
    SDL_Event e;
    while (q_SDL_PollEvent(&e)) {
        if (e.type == SDL_QUIT) { combo_now = true; combo_since = 0; }
        if (e.type == SDL_KEYDOWN && e.key.keysym.sym == SDLK_ESCAPE) { combo_now = true; combo_since = 0; }
        if (e.type == SDL_KEYDOWN) any_now = true;
    }
    bool combo = false;
    int maxpressed = 0;
    for (int i = 0; i < g_npads; i++) {
        if (g_gc[i] && q_SDL_GameControllerGetButton(g_gc[i], SDL_CONTROLLER_BUTTON_START) &&
            q_SDL_GameControllerGetButton(g_gc[i], SDL_CONTROLLER_BUTTON_BACK))
            combo = true;
        if (g_js[i]) {
            int n = q_SDL_JoystickNumButtons(g_js[i]), c = 0;
            for (int b = 0; b < n; b++) c += q_SDL_JoystickGetButton(g_js[i], b) ? 1 : 0;
            if (c > maxpressed) maxpressed = c;
        }
    }
    if (!g_gc[0] && maxpressed >= 3) combo = true;   /* no mapping: any 3 buttons */
    if (!abort_enabled) combo = false;
    double t = now_s();
    if (combo) { if (combo_since == 0) combo_since = t; }
    else combo_since = 0;
    if (combo_since > 0 && t - combo_since > 1.0) combo_now = true;
    any_now = maxpressed > 0;
    (void)any_since;
}

bool ui_abort_combo(void) { ui_poll(); return combo_now; }
bool ui_any_button_pressed(void) { ui_poll(); return any_now; }

/* ---------- window + context ---------- */
bool gfx_init(bool windowed) {
    section("Graphics init");
    if (q_SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
        plog("SDL_Init(VIDEO) failed: %s\n", q_SDL_GetError());
        return false;
    }
    if (q_SDL_InitSubSystem(SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER) != 0)
        plog("SDL joystick init failed: %s\n", q_SDL_GetError());
    char drivers[256] = "";
    for (int i = 0; i < q_SDL_GetNumVideoDrivers(); i++) {
        strncat(drivers, q_SDL_GetVideoDriver(i), sizeof drivers - strlen(drivers) - 2);
        strncat(drivers, " ", sizeof drivers - strlen(drivers) - 1);
    }
    kv("sdl.video_drivers_compiled", "%s", drivers);
    kv("sdl.video_driver", "%s", q_SDL_GetCurrentVideoDriver());
    SDL_DisplayMode dm = {0};
    if (q_SDL_GetDesktopDisplayMode(0, &dm) == 0)
        kv("display.desktop_mode", "%dx%d @ %d Hz, format 0x%08x", dm.w, dm.h, dm.refresh_rate, dm.format);
    int nmodes = q_SDL_GetNumDisplayModes(0);
    for (int i = 0; i < nmodes && i < 16; i++) {
        SDL_DisplayMode m;
        if (q_SDL_GetDisplayMode(0, i, &m) == 0) plog("display.mode[%d] = %dx%d @ %d Hz\n", i, m.w, m.h, m.refresh_rate);
    }

    static const int vers[][2] = {{3, 2}, {3, 1}, {3, 0}, {2, 0}};
    for (int i = 0; i < 4 && !g_ctx; i++) {
        q_SDL_GL_ResetAttributes();
        q_SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
        q_SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, vers[i][0]);
        q_SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, vers[i][1]);
        q_SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
        q_SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
        q_SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
        q_SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 0);
        q_SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 0);
        q_SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        Uint32 flags = SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN | (windowed ? 0 : SDL_WINDOW_FULLSCREEN_DESKTOP);
        int w = windowed ? 640 : (dm.w ? dm.w : 640), h = windowed ? 480 : (dm.h ? dm.h : 480);
        g_win = q_SDL_CreateWindow("gameguy probe", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, w, h, flags);
        if (!g_win) { plog("SDL_CreateWindow (ES %d.%d) failed: %s\n", vers[i][0], vers[i][1], q_SDL_GetError()); continue; }
        g_ctx = q_SDL_GL_CreateContext(g_win);
        if (!g_ctx) {
            plog("GLES %d.%d context failed: %s\n", vers[i][0], vers[i][1], q_SDL_GetError());
            q_SDL_DestroyWindow(g_win);
            g_win = NULL;
        } else {
            kv("gl.context_requested", "OpenGL ES %d.%d", vers[i][0], vers[i][1]);
        }
    }
    if (!g_ctx) return false;
    q_SDL_GL_MakeCurrent(g_win, g_ctx);
    q_SDL_ShowCursor(SDL_DISABLE);
    q_SDL_GL_GetDrawableSize(g_win, &gfx_w, &gfx_h);
    kv("gl.drawable", "%dx%d", gfx_w, gfx_h);

    int missing = 0;
#define GL_LOAD(T, n) n = (T)gl_proc(#n); if (!n) { plog("missing GL entry point: %s\n", #n); missing++; }
    GL_FUNCS(GL_LOAD)
#define GL3_LOAD(T, n) n = (T)gl_proc(#n);
    GL3_FUNCS(GL3_LOAD)
    if (missing) return false;

    const char *ver = (const char *)glGetString(GL_VERSION);
    if (ver && sscanf(ver, "OpenGL ES %d.%d", &g_gles_major, &g_gles_minor) != 2) { g_gles_major = 2; g_gles_minor = 0; }
    snprintf(g_gl_renderer, sizeof g_gl_renderer, "%s / %s", (const char *)glGetString(GL_RENDERER),
             ver ? ver : "?");
    kv("gl.vendor", "%s", (const char *)glGetString(GL_VENDOR));
    kv("gl.renderer", "%s", (const char *)glGetString(GL_RENDERER));
    kv("gl.version", "%s", ver ? ver : "?");
    kv("gl.glsl_version", "%s", (const char *)glGetString(GL_SHADING_LANGUAGE_VERSION));

    /* extension string (space separated) */
    size_t cap = 1 << 16, len = 0;
    g_ext_cache = calloc(1, cap);
    if (g_gles_major >= 3 && glGetStringi) {
        GLint n = 0;
        glGetIntegerv(GL_NUM_EXTENSIONS, &n);
        for (GLint i = 0; i < n; i++) {
            const char *e = (const char *)glGetStringi(GL_EXTENSIONS, (GLuint)i);
            if (!e) continue;
            size_t l = strlen(e);
            if (len + l + 2 >= cap) break;
            memcpy(g_ext_cache + len, e, l);
            len += l;
            g_ext_cache[len++] = ' ';
        }
        if (len) g_ext_cache[len - 1] = 0;
    } else {
        const char *e = (const char *)glGetString(GL_EXTENSIONS);
        if (e) snprintf(g_ext_cache, cap, "%s", e);
    }
    q_SDL_GL_SetSwapInterval(1);
    glViewport(0, 0, gfx_w, gfx_h);
    g_gfx_ok = true;
    ui_init();

    /* controllers */
    int nj = q_SDL_NumJoysticks();
    kv("input.num_joysticks", "%d", nj);
    for (int i = 0; i < nj && g_npads < MAX_PADS; i++) {
        g_js[g_npads] = q_SDL_JoystickOpen(i);
        if (q_SDL_IsGameController(i)) g_gc[g_npads] = q_SDL_GameControllerOpen(i);
        if (g_js[g_npads]) g_npads++;
    }
    gl_check("gfx_init");
    return true;
}

void gfx_shutdown(void) {
    if (!sdl_ok) return;
    for (int i = 0; i < g_npads; i++) {
        if (g_gc[i]) q_SDL_GameControllerClose(g_gc[i]);
        else if (g_js[i]) q_SDL_JoystickClose(g_js[i]);
    }
    if (g_ctx) q_SDL_GL_DeleteContext(g_ctx);
    if (g_win) q_SDL_DestroyWindow(g_win);
    g_gfx_ok = false;
    q_SDL_Quit();
}
