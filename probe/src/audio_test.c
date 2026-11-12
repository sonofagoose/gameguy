/* gameguy probe — audio output: drivers, achievable buffer sizes, callback timing.
 * Plays short, quiet just-intonation chords (4:5:6) so you can hear that each configuration works.
 */
#include "probe.h"

#define MAX_CB 4096
typedef struct {
    SDL_AudioSpec have;
    double ts[MAX_CB];
    int ncb;
    double phase[3];
    double freqs[3];
    long frame;
    long total_frames;
} audio_state;

static void audio_cb(void *ud, Uint8 *stream, int len) {
    audio_state *s = ud;
    if (s->ncb < MAX_CB) s->ts[s->ncb++] = now_s();
    int ch = s->have.channels;
    int bytes = SDL_AUDIO_BITSIZE(s->have.format) / 8;
    int frames = len / (ch * bytes);
    double sr = s->have.freq;
    for (int i = 0; i < frames; i++) {
        long f = s->frame++;
        double env = 1.0;
        double fade = 0.05 * sr;
        if (f < fade) env = f / fade;
        if (f > s->total_frames - fade) env = (s->total_frames - f) / fade;
        if (env < 0) env = 0;
        double v = 0;
        for (int k = 0; k < 3; k++) {
            v += sin(s->phase[k]) * 0.07;
            s->phase[k] += 2 * M_PI * s->freqs[k] / sr;
            if (s->phase[k] > 2 * M_PI) s->phase[k] -= 2 * M_PI;
        }
        v *= env;
        for (int c = 0; c < ch; c++) {
            int idx = i * ch + c;
            if (s->have.format == AUDIO_F32SYS) ((float *)stream)[idx] = (float)v;
            else if (s->have.format == AUDIO_S16SYS) ((int16_t *)stream)[idx] = (int16_t)(v * 32767);
            else if (s->have.format == AUDIO_S32SYS) ((int32_t *)stream)[idx] = (int32_t)(v * 2147483647.0);
            else memset(stream + (size_t)idx * bytes, 0, (size_t)bytes);
        }
    }
}

static const char *fmt_name(SDL_AudioFormat f) {
    switch (f) {
    case AUDIO_F32SYS: return "F32";
    case AUDIO_S16SYS: return "S16";
    case AUDIO_S32SYS: return "S32";
    case AUDIO_U8: return "U8";
    default: return "other";
    }
}

static bool run_config(const char *label, const char *audiodev, int samples, double root, double *lat_ms,
                       double *jitter_ms) {
    if (audiodev) setenv("AUDIODEV", audiodev, 1);
    else unsetenv("AUDIODEV");
    SDL_AudioSpec want = {0};
    audio_state *s = calloc(1, sizeof *s);
    want.freq = 48000;
    want.format = AUDIO_F32SYS;
    want.channels = 2;
    want.samples = (Uint16)samples;
    want.callback = audio_cb;
    want.userdata = s;
    SDL_AudioDeviceID dev = q_SDL_OpenAudioDevice(NULL, 0, &want, &s->have, SDL_AUDIO_ALLOW_ANY_CHANGE);
    if (!dev) {
        plog("audio.%s.samples%d = OPEN FAILED: %s\n", label, samples, q_SDL_GetError());
        free(s);
        return false;
    }
    s->freqs[0] = root; s->freqs[1] = root * 5 / 4; s->freqs[2] = root * 3 / 2;
    s->total_frames = (long)(s->have.freq * 0.9);
    q_SDL_PauseAudioDevice(dev, 0);
    double t0 = now_s();
    bool dumped = false;
    while (now_s() - t0 < 1.0) {
        ui_frame();
        usleep(20000);
        if (!dumped && now_s() - t0 > 0.4) {   /* what the kernel sees while we are playing */
            dumped = true;
            char t[96];
            snprintf(t, sizeof t, "ALSA stream state during '%s' %d-frame playback", label, samples);
            log_cmd(t, "for f in /proc/asound/card*/pcm*p/sub*/hw_params /proc/asound/card*/pcm*p/sub*/status; do "
                       "echo \"== $f\"; cat $f; done 2>/dev/null | head -60", 4096);
        }
    }
    q_SDL_PauseAudioDevice(dev, 1);
    q_SDL_CloseAudioDevice(dev);
    double expect = (double)s->have.samples / s->have.freq;
    double sum = 0, mx = 0;
    int n = 0;
    for (int i = 6; i < s->ncb; i++) {   /* skip start-up burst */
        double d = s->ts[i] - s->ts[i - 1];
        sum += d;
        if (d > mx) mx = d;
        n++;
    }
    double mean = n ? sum / n : 0;
    plog("audio.%s.samples%d = got %d Hz %s %dch %d-frame buffer (%.2f ms); callbacks %d, mean interval %.2f ms, "
         "max %.2f ms\n",
         label, samples, s->have.freq, fmt_name(s->have.format), s->have.channels, s->have.samples, expect * 1e3,
         s->ncb, mean * 1e3, mx * 1e3);
    *lat_ms = expect * 1e3;
    *jitter_ms = (mx - expect) * 1e3;
    free(s);
    return true;
}

void audio_tests_run(void) {
    test_begin("Audio output", 90);
    if (!q_SDL_InitSubSystem) { summary("audio: SDL not available"); test_end(); return; }
    if (q_SDL_InitSubSystem(SDL_INIT_AUDIO) != 0) {
        summary("audio: SDL audio init failed: %s", q_SDL_GetError());
        test_end();
        return;
    }
    char drv[256] = "";
    for (int i = 0; i < q_SDL_GetNumAudioDrivers(); i++) {
        strncat(drv, q_SDL_GetAudioDriver(i), sizeof drv - strlen(drv) - 2);
        strncat(drv, " ", sizeof drv - strlen(drv) - 1);
    }
    kv("audio.drivers_compiled", "%s", drv);
    kv("audio.current_driver", "%s", q_SDL_GetCurrentAudioDriver() ? q_SDL_GetCurrentAudioDriver() : "(none)");
    int nd = q_SDL_GetNumAudioDevices(0);
    for (int i = 0; i < nd; i++) plog("audio.device[%d] = %s\n", i, q_SDL_GetAudioDeviceName(i, 0));
    log_cmd("mixer (all controls)", "amixer contents 2>&1 | head -200; echo; amixer 2>&1 | head -80", 16384);
    log_cmd("headphone / jack state", "grep -l -i -E 'headphone|jack' /sys/class/input/input*/name 2>/dev/null; "
                                      "cat /sys/class/switch/h2w/state 2>/dev/null; "
                                      "cat /sys/class/extcon/*/state 2>/dev/null; "
                                      "amixer 2>/dev/null | grep -A3 -i -E 'playback path|headphone|speaker' | head -30",
            4096);
    int sizes[] = {128, 256, 512, 1024};
    double roots[] = {220.0, 247.5, 264.0, 293.33};   /* just-ratio roots: 1, 9/8, 6/5, 4/3 */
    double best_default = 0, best_hw = 0, lat, jit;
    for (int i = 0; i < 4 && !probe_aborted(); i++) {
        ui_status("Audio: default device, %d-frame buffer (listen for a soft chord)", sizes[i]);
        if (run_config("default", NULL, sizes[i], roots[i], &lat, &jit) && jit < lat && (best_default == 0 || lat < best_default))
            best_default = lat;
    }
    if (strcmp(q_SDL_GetCurrentAudioDriver() ? q_SDL_GetCurrentAudioDriver() : "", "alsa") == 0) {
        for (int i = 0; i < 2 && !probe_aborted(); i++) {
            ui_status("Audio: direct ALSA hw:0,0, %d-frame buffer", sizes[i]);
            if (run_config("hw00", "hw:0,0", sizes[i], roots[i] * 2, &lat, &jit) && jit < lat &&
                (best_hw == 0 || lat < best_hw))
                best_hw = lat;
        }
    }
    unsetenv("AUDIODEV");
    summary("audio: driver %s; smallest steady buffer %.1f ms (default), %.1f ms (hw:0,0)",
            q_SDL_GetCurrentAudioDriver() ? q_SDL_GetCurrentAudioDriver() : "?", best_default, best_hw);
    plog("note: 'steady' = worst callback gap shorter than two buffer periods; real output latency also\n"
         "      includes the ALSA/dmix period queue (see /etc/asound.conf above)\n");
    q_SDL_QuitSubSystem(SDL_INIT_AUDIO);
    test_end();
}
