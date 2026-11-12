/* gameguy hardware probe — shared declarations.
 *
 * Everything external (SDL2, EGL, GLES, Vulkan) is loaded at runtime with
 * dlopen/GetProcAddress, so the binary links only against glibc and runs on
 * whatever SDL2 / libmali / Mesa the device firmware ships.
 */
#pragma once
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdbool.h>
#include <math.h>
#include <time.h>
#include <unistd.h>

#define GL_GLES_PROTOTYPES 0
#include <GLES3/gl32.h>
#include <GLES2/gl2ext.h>
#include <SDL2/SDL.h>

#define PROBE_VERSION "1.3"

/* ---------- main.c: logging, timing, test bookkeeping ---------- */
double now_s(void);
void plog(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
void kv(const char *key, const char *fmt, ...) __attribute__((format(printf, 2, 3)));
void section(const char *name);
void log_sync(void);
void summary(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
void test_begin(const char *name, int timeout_s);
void test_end(void);
bool probe_aborted(void);
void log_file_contents(const char *path, size_t max_bytes);
void log_cmd(const char *title, const char *cmd, size_t max_bytes);
extern const char *g_results_dir;
extern char g_unit_id[32];

/* telemetry (main.c) */
typedef struct {
    double max_temp_c;      /* hottest thermal zone seen */
    double min_cpu_mhz;     /* lowest cpu0 frequency seen */
    double max_cpu_mhz;
    double min_gpu_mhz;     /* lowest GPU devfreq seen (0 = unknown) */
    double max_gpu_mhz;
    double min_ddr_mhz;     /* lowest DMC devfreq seen (0 = unknown) */
    double max_ddr_mhz;
    double batt_start_pct, batt_end_pct;
    int samples;
} telem_stats_t;
void telem_reset(void);
telem_stats_t telem_get(void);
void telem_snapshot_line(char *buf, size_t n);  /* "cpu 1296 MHz | gpu 520 | ddr 666 | 47.2C" */

/* ---------- sdlgl.c: SDL2 + GLES loading, window, text UI ---------- */
#define SDL_FUNCS(X) \
    X(SDL_Init) X(SDL_InitSubSystem) X(SDL_QuitSubSystem) X(SDL_Quit) X(SDL_GetError) \
    X(SDL_GetVersion) X(SDL_GetPlatform) X(SDL_SetHint) X(SDL_GetCPUCount) X(SDL_HasNEON) \
    X(SDL_GetSystemRAM) X(SDL_GetCurrentVideoDriver) X(SDL_GetNumVideoDrivers) X(SDL_GetVideoDriver) \
    X(SDL_GL_SetAttribute) X(SDL_GL_GetAttribute) X(SDL_GL_ResetAttributes) X(SDL_CreateWindow) X(SDL_DestroyWindow) \
    X(SDL_GL_CreateContext) X(SDL_GL_DeleteContext) X(SDL_GL_MakeCurrent) X(SDL_GL_SetSwapInterval) \
    X(SDL_GL_GetSwapInterval) X(SDL_GL_SwapWindow) X(SDL_GL_GetProcAddress) X(SDL_GL_GetDrawableSize) \
    X(SDL_GetDesktopDisplayMode) X(SDL_GetNumDisplayModes) X(SDL_GetDisplayMode) X(SDL_ShowCursor) \
    X(SDL_SetWindowDisplayMode) X(SDL_GetWindowDisplayMode) X(SDL_SetWindowFullscreen) \
    X(SDL_PollEvent) X(SDL_PumpEvents) \
    X(SDL_GetNumAudioDrivers) X(SDL_GetAudioDriver) X(SDL_GetCurrentAudioDriver) X(SDL_GetNumAudioDevices) \
    X(SDL_GetAudioDeviceName) X(SDL_OpenAudioDevice) X(SDL_PauseAudioDevice) X(SDL_CloseAudioDevice) \
    X(SDL_NumJoysticks) X(SDL_JoystickOpen) X(SDL_JoystickClose) X(SDL_JoystickName) X(SDL_JoystickNumAxes) \
    X(SDL_JoystickNumButtons) X(SDL_JoystickNumHats) X(SDL_JoystickGetGUID) X(SDL_JoystickGetGUIDString) \
    X(SDL_JoystickGetAxis) X(SDL_JoystickGetButton) X(SDL_JoystickGetHat) X(SDL_JoystickInstanceID) \
    X(SDL_IsGameController) X(SDL_GameControllerOpen) X(SDL_GameControllerClose) X(SDL_GameControllerName) \
    X(SDL_GameControllerMapping) X(SDL_GameControllerGetButton) X(SDL_GameControllerGetStringForButton) \
    X(SDL_GameControllerGetBindForButton) X(SDL_GameControllerGetAxis) X(SDL_GameControllerGetStringForAxis) \
    X(SDL_GameControllerGetBindForAxis)

#define SDL_DECL(n) extern __typeof__(n) *q_##n;
SDL_FUNCS(SDL_DECL)

#define GL_FUNCS(X) \
    X(PFNGLGETSTRINGPROC, glGetString) X(PFNGLGETINTEGERVPROC, glGetIntegerv) X(PFNGLGETERRORPROC, glGetError) \
    X(PFNGLGETSHADERPRECISIONFORMATPROC, glGetShaderPrecisionFormat) X(PFNGLVIEWPORTPROC, glViewport) \
    X(PFNGLCLEARCOLORPROC, glClearColor) X(PFNGLCLEARPROC, glClear) X(PFNGLENABLEPROC, glEnable) \
    X(PFNGLDISABLEPROC, glDisable) X(PFNGLBLENDFUNCPROC, glBlendFunc) X(PFNGLBLENDEQUATIONPROC, glBlendEquation) \
    X(PFNGLCREATESHADERPROC, glCreateShader) X(PFNGLSHADERSOURCEPROC, glShaderSource) \
    X(PFNGLCOMPILESHADERPROC, glCompileShader) X(PFNGLGETSHADERIVPROC, glGetShaderiv) \
    X(PFNGLGETSHADERINFOLOGPROC, glGetShaderInfoLog) X(PFNGLCREATEPROGRAMPROC, glCreateProgram) \
    X(PFNGLATTACHSHADERPROC, glAttachShader) X(PFNGLLINKPROGRAMPROC, glLinkProgram) \
    X(PFNGLGETPROGRAMIVPROC, glGetProgramiv) X(PFNGLGETPROGRAMINFOLOGPROC, glGetProgramInfoLog) \
    X(PFNGLDELETESHADERPROC, glDeleteShader) X(PFNGLDELETEPROGRAMPROC, glDeleteProgram) \
    X(PFNGLUSEPROGRAMPROC, glUseProgram) X(PFNGLBINDATTRIBLOCATIONPROC, glBindAttribLocation) \
    X(PFNGLGETUNIFORMLOCATIONPROC, glGetUniformLocation) X(PFNGLUNIFORM1IPROC, glUniform1i) \
    X(PFNGLUNIFORM1FPROC, glUniform1f) X(PFNGLUNIFORM2FPROC, glUniform2f) X(PFNGLUNIFORM3FPROC, glUniform3f) \
    X(PFNGLUNIFORM4FPROC, glUniform4f) X(PFNGLUNIFORM3FVPROC, glUniform3fv) X(PFNGLUNIFORM4FVPROC, glUniform4fv) \
    X(PFNGLGENBUFFERSPROC, glGenBuffers) X(PFNGLBINDBUFFERPROC, glBindBuffer) X(PFNGLBUFFERDATAPROC, glBufferData) \
    X(PFNGLBUFFERSUBDATAPROC, glBufferSubData) X(PFNGLDELETEBUFFERSPROC, glDeleteBuffers) \
    X(PFNGLVERTEXATTRIBPOINTERPROC, glVertexAttribPointer) \
    X(PFNGLENABLEVERTEXATTRIBARRAYPROC, glEnableVertexAttribArray) \
    X(PFNGLDISABLEVERTEXATTRIBARRAYPROC, glDisableVertexAttribArray) X(PFNGLDRAWARRAYSPROC, glDrawArrays) \
    X(PFNGLGENTEXTURESPROC, glGenTextures) X(PFNGLBINDTEXTUREPROC, glBindTexture) \
    X(PFNGLTEXIMAGE2DPROC, glTexImage2D) X(PFNGLTEXSUBIMAGE2DPROC, glTexSubImage2D) \
    X(PFNGLTEXPARAMETERIPROC, glTexParameteri) X(PFNGLCOMPRESSEDTEXIMAGE2DPROC, glCompressedTexImage2D) \
    X(PFNGLDELETETEXTURESPROC, glDeleteTextures) X(PFNGLACTIVETEXTUREPROC, glActiveTexture) \
    X(PFNGLGENFRAMEBUFFERSPROC, glGenFramebuffers) X(PFNGLBINDFRAMEBUFFERPROC, glBindFramebuffer) \
    X(PFNGLFRAMEBUFFERTEXTURE2DPROC, glFramebufferTexture2D) \
    X(PFNGLCHECKFRAMEBUFFERSTATUSPROC, glCheckFramebufferStatus) \
    X(PFNGLDELETEFRAMEBUFFERSPROC, glDeleteFramebuffers) X(PFNGLREADPIXELSPROC, glReadPixels) \
    X(PFNGLFINISHPROC, glFinish) X(PFNGLFLUSHPROC, glFlush) X(PFNGLPIXELSTOREIPROC, glPixelStorei) \
    X(PFNGLCOLORMASKPROC, glColorMask)

/* ES 3.0+ entry points (NULL on an ES2-only context) */
#define GL3_FUNCS(X) \
    X(PFNGLGETSTRINGIPROC, glGetStringi) X(PFNGLGENVERTEXARRAYSPROC, glGenVertexArrays) \
    X(PFNGLBINDVERTEXARRAYPROC, glBindVertexArray) X(PFNGLDELETEVERTEXARRAYSPROC, glDeleteVertexArrays) \
    X(PFNGLDRAWARRAYSINSTANCEDPROC, glDrawArraysInstanced) X(PFNGLDRAWBUFFERSPROC, glDrawBuffers) \
    X(PFNGLINVALIDATEFRAMEBUFFERPROC, glInvalidateFramebuffer) X(PFNGLTEXSTORAGE2DPROC, glTexStorage2D)

#define GL_DECL(T, n) extern T n;
GL_FUNCS(GL_DECL)
GL3_FUNCS(GL_DECL)

extern SDL_Window *g_win;
extern int gfx_w, gfx_h;          /* drawable size in pixels */
extern int g_gles_major, g_gles_minor;
extern bool g_gfx_ok;             /* window + context exist */
extern char g_gl_renderer[128];

bool sdl_load(void);              /* dlopen SDL2; false = fatal */
bool gfx_init(bool windowed);     /* window + GLES context + UI; logs details */
void gfx_shutdown(void);
bool gl_has_ext(const char *name);
GLuint gl_program(const char *vs, const char *fs, const char *name, bool quiet);
void gl_check(const char *where); /* logs and clears GL errors */

/* text UI */
enum { FONT_S = 0, FONT_L = 1 };
void ui_text(int font, float x, float y, uint32_t rgba, const char *s);
void ui_textf(int font, float x, float y, uint32_t rgba, const char *fmt, ...) __attribute__((format(printf, 5, 6)));
void ui_rect(float x, float y, float w, float h, uint32_t rgba);
void ui_flush(void);              /* draw queued text/rects (default framebuffer) */
void ui_begin_frame(uint32_t clear_rgba);
void ui_present(void);            /* swap + poll input */
void ui_status(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
void ui_progress(int step, int steps);
void ui_add_line(const char *s);
void ui_frame(void);              /* standard status screen */
void ui_poll(void);
bool ui_abort_combo(void);        /* SELECT+START (or 3+ buttons) held */
void ui_set_abort_enabled(bool on); /* off during the interactive controls test */
bool ui_any_button_pressed(void);

/* joysticks are opened by gfx_init (SDL_INIT_JOYSTICK) */
#define MAX_PADS 4
extern SDL_Joystick *g_js[MAX_PADS];
extern SDL_GameController *g_gc[MAX_PADS];
extern int g_npads;

/* ---------- test modules ---------- */
void sysinfo_run(void);
void gpu_tests_run(void);
void display_test_run(void);
void cpu_tests_run(void);
void storage_test_run(void);
void audio_tests_run(void);
void input_test_run(int seconds);
void vulkan_probe_run(void);
void stress_run(int seconds);

/* shared helpers */
uint64_t fnv1a(const void *data, size_t n, uint64_t h);
double cpu_neon_gflops_1thread(double seconds);  /* used by stress for reference */
