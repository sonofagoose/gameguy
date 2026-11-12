/* gameguy probe — controls: resting noise, stick directions, button map, event rate. */
#include "probe.h"

#define MAXB 32
#define MAXA 8

#define MAXTS 20000
typedef struct {
    double ts[MAXTS];
    int nts;
    double rest_mean[MAXA], rest_sd[MAXA];
    int amin[MAXA], amax[MAXA];
    int bcount[MAXB];
    long axis_events;
    double t_first_axis, t_last_axis;
} in_stats;

static const char *btn_name_for_raw(int pad, int raw) {
    if (!g_gc[pad]) return "";
    for (int b = 0; b < SDL_CONTROLLER_BUTTON_MAX; b++) {
        SDL_GameControllerButtonBind bind = q_SDL_GameControllerGetBindForButton(g_gc[pad], (SDL_GameControllerButton)b);
        if (bind.bindType == SDL_CONTROLLER_BINDTYPE_BUTTON && bind.value.button == raw)
            return q_SDL_GameControllerGetStringForButton((SDL_GameControllerButton)b);
    }
    return "";
}

static void draw_pad_state(int pad, in_stats *st, const char *title, const char *line2, double remain) {
    SDL_Joystick *js = g_js[pad];
    int na = q_SDL_JoystickNumAxes(js), nb = q_SDL_JoystickNumButtons(js);
    if (na > MAXA) na = MAXA;
    if (nb > MAXB) nb = MAXB;
    ui_begin_frame(0x10141aff);
    ui_text(FONT_L, 16, 8, 0xffffffff, "CONTROLS");
    ui_text(FONT_S, 16, 50, 0xffd36bff, title);
    ui_text(FONT_S, 16, 72, 0xdce6eeff, line2);
    if (remain >= 0) ui_textf(FONT_S, gfx_w - 9 * 10, 18, 0x8aa0b4ff, "%4.0f s", remain);
    /* buttons */
    for (int b = 0; b < nb; b++) {
        float x = 16 + (b % 8) * 76, y = 104 + (b / 8) * 40;
        bool down = q_SDL_JoystickGetButton(js, b);
        ui_rect(x, y, 70, 34, down ? 0x5fb3ffff : (st->bcount[b] ? 0x2f5a3cff : 0x23303bff));
        ui_textf(FONT_S, x + 4, y + 6, 0xffffffff, "%2d %.5s", b, btn_name_for_raw(pad, b));
    }
    /* axes */
    float ay = 104 + ((nb + 7) / 8) * 40 + 10;
    for (int a = 0; a < na; a++) {
        int v = q_SDL_JoystickGetAxis(js, a);
        float y = ay + a * 26, x0 = 120, w = (float)gfx_w - 136;
        ui_textf(FONT_S, 16, y, 0xdce6eeff, "axis %d", a);
        ui_rect(x0, y + 6, w, 10, 0x23303bff);
        float lo = x0 + (st->amin[a] + 32768) / 65535.0f * w, hi = x0 + (st->amax[a] + 32768) / 65535.0f * w;
        ui_rect(lo, y + 6, hi - lo + 1, 10, 0x2f5a3cff);
        ui_rect(x0 + (v + 32768) / 65535.0f * w - 2, y + 2, 4, 18, 0xffd36bff);
    }
    int nh = q_SDL_JoystickNumHats(js);
    for (int h = 0; h < nh; h++)
        ui_textf(FONT_S, 16, ay + na * 26 + h * 22, 0xdce6eeff, "hat %d = 0x%x", h, q_SDL_JoystickGetHat(js, h));
    ui_present();
}

static void update_stats(int pad, in_stats *st) {
    SDL_Joystick *js = g_js[pad];
    int na = q_SDL_JoystickNumAxes(js), nb = q_SDL_JoystickNumButtons(js);
    static int prevb[MAXB], preva[MAXA];
    for (int a = 0; a < na && a < MAXA; a++) {
        int v = q_SDL_JoystickGetAxis(js, a);
        if (v < st->amin[a]) st->amin[a] = v;
        if (v > st->amax[a]) st->amax[a] = v;
        if (v != preva[a]) {
            st->axis_events++;
            if (st->nts < MAXTS) st->ts[st->nts++] = now_s();
            double t = now_s();
            if (st->t_first_axis == 0) st->t_first_axis = t;
            st->t_last_axis = t;
        }
        preva[a] = v;
    }
    for (int b = 0; b < nb && b < MAXB; b++) {
        int d = q_SDL_JoystickGetButton(js, b);
        if (d && !prevb[b]) st->bcount[b]++;
        prevb[b] = d;
    }
}

/* One stick prompt: (1) wait until every axis is back near rest, (2) wait for a NEW axis (not one an
 * earlier prompt already claimed) to be pushed past 60% and held 0.4 s, (3) confirm and ask for release.
 * v1.1 bug: without step 1 and the claimed-axis rule, a still-held stick answered every later prompt. */
static unsigned claimed_axes;
static void direction_prompt(int pad, in_stats *st, const char *prompt, const char *key, const char *next) {
    SDL_Joystick *js = g_js[pad];
    int na = q_SDL_JoystickNumAxes(js);
    if (na > MAXA) na = MAXA;
    /* 1. release */
    double t0 = now_s(), centered = 0;
    while (now_s() - t0 < 10.0) {
        int maxd = 0;
        for (int a = 0; a < na; a++) {
            int d = abs(q_SDL_JoystickGetAxis(js, a) - (int)st->rest_mean[a]);
            if (d > maxd) maxd = d;
        }
        if (maxd < 6000) { if (!centered) centered = now_s(); if (now_s() - centered > 0.3) break; }
        else centered = 0;
        update_stats(pad, st);
        draw_pad_state(pad, st, "Let go of both sticks...", prompt, -1);
        usleep(8000);
    }
    /* 2. push */
    t0 = now_s();
    double held = 0;
    int best_a = -1, best_v = 0;
    while (now_s() - t0 < 15.0) {
        best_a = -1; best_v = 0;
        for (int a = 0; a < na; a++) {
            if (claimed_axes & (1u << a)) continue;
            int d = q_SDL_JoystickGetAxis(js, a) - (int)st->rest_mean[a];
            if (abs(d) > abs(best_v)) { best_v = d; best_a = a; }
        }
        if (abs(best_v) > 20000) { if (held == 0) held = now_s(); }
        else held = 0;
        if (held && now_s() - held > 0.4) break;
        update_stats(pad, st);
        draw_pad_state(pad, st, prompt, "Push it all the way and hold it.", 15.0 - (now_s() - t0));
        usleep(8000);
    }
    if (abs(best_v) > 20000) {
        claimed_axes |= 1u << best_a;
        kv(key, "axis %d %s (deflection %d) -> %s", best_a, best_v < 0 ? "negative" : "positive", best_v,
           strstr(key, "up") ? (best_v < 0 ? "SDL-normal (up = negative)" : "INVERTED (up = positive)")
                             : (best_v > 0 ? "SDL-normal (right = positive)" : "INVERTED (right = negative)"));
        /* 3. confirm */
        double tc = now_s();
        char msg[96];
        snprintf(msg, sizeof msg, "Got it (axis %d). Release the stick.", best_a);
        while (now_s() - tc < 1.2) {
            update_stats(pad, st);
            draw_pad_state(pad, st, msg, next, -1);
            usleep(8000);
        }
    } else {
        kv(key, "no deflection detected (timed out)");
    }
}

void input_test_run(int seconds) {
    test_begin("Controls (interactive)", seconds + 60);
    if (!g_npads || !g_gfx_ok) { summary("controls: no joystick found (%d)", g_npads); test_end(); return; }
    for (int p = 0; p < g_npads; p++) {
        SDL_Joystick *js = g_js[p];
        char guid[64];
        q_SDL_JoystickGetGUIDString(q_SDL_JoystickGetGUID(js), guid, sizeof guid);
        plog("pad[%d] name='%s' guid=%s axes=%d buttons=%d hats=%d gamecontroller=%s\n", p, q_SDL_JoystickName(js),
             guid, q_SDL_JoystickNumAxes(js), q_SDL_JoystickNumButtons(js), q_SDL_JoystickNumHats(js),
             g_gc[p] ? "yes" : "no");
        if (g_gc[p]) {
            char *m = q_SDL_GameControllerMapping(g_gc[p]);
            plog("pad[%d] mapping = %s\n", p, m ? m : "(none)");
        }
    }
    kv("env.SDL_GAMECONTROLLERCONFIG", "%.300s", getenv("SDL_GAMECONTROLLERCONFIG") ? getenv("SDL_GAMECONTROLLERCONFIG") : "(unset)");
    int pad = 0;   /* the built-in controls are the first device on these handhelds */
    ui_set_abort_enabled(false);
    static in_stats st;
    memset(&st, 0, sizeof st);
    for (int a = 0; a < MAXA; a++) { st.amin[a] = 32767; st.amax[a] = -32768; }

    /* 1. resting noise */
    int na = q_SDL_JoystickNumAxes(g_js[pad]);
    if (na > MAXA) na = MAXA;
    double sum[MAXA] = {0}, sq[MAXA] = {0};
    int ns = 0;
    double t0 = now_s();
    while (now_s() - t0 < 2.0) {
        q_SDL_PumpEvents();
        for (int a = 0; a < na; a++) { double v = q_SDL_JoystickGetAxis(g_js[pad], a); sum[a] += v; sq[a] += v * v; }
        ns++;
        draw_pad_state(pad, &st, "Hands off the controls for 2 seconds...", "Measuring stick resting noise.",
                       2.0 - (now_s() - t0));
        usleep(5000);
    }
    for (int a = 0; a < na; a++) {
        st.rest_mean[a] = sum[a] / ns;
        double var = sq[a] / ns - st.rest_mean[a] * st.rest_mean[a];
        st.rest_sd[a] = var > 0 ? sqrt(var) : 0;
        plog("axis%d.rest = mean %.0f, sd %.1f (of 32768)\n", a, st.rest_mean[a], st.rest_sd[a]);
    }
    /* 2. directions */
    t0 = now_s();
    while (now_s() - t0 < 3.0) {
        update_stats(pad, &st);
        draw_pad_state(pad, &st, "Get ready: four stick prompts are next.", "Each one waits for you; let go between prompts.",
                       3.0 - (now_s() - t0));
        usleep(8000);
    }
    claimed_axes = 0;
    direction_prompt(pad, &st, "Push the LEFT stick UP", "stick.left_up", "Next: LEFT stick RIGHT");
    direction_prompt(pad, &st, "Push the LEFT stick RIGHT", "stick.left_right", "Next: RIGHT stick UP");
    direction_prompt(pad, &st, "Push the RIGHT stick UP", "stick.right_up", "Next: RIGHT stick RIGHT");
    direction_prompt(pad, &st, "Push the RIGHT stick RIGHT", "stick.right_right", "Next: press every button");
    /* 3. free exploration */
    memset(st.bcount, 0, sizeof st.bcount);
    st.axis_events = 0;
    st.nts = 0;
    st.t_first_axis = st.t_last_axis = 0;
    for (int a = 0; a < MAXA; a++) { st.amin[a] = 32767; st.amax[a] = -32768; }
    t0 = now_s();
    double hold3 = 0;
    while (now_s() - t0 < seconds) {
        q_SDL_PumpEvents();
        update_stats(pad, &st);
        int down = 0;
        for (int b = 0; b < q_SDL_JoystickNumButtons(g_js[pad]); b++) down += q_SDL_JoystickGetButton(g_js[pad], b);
        if (down >= 3) { if (!hold3) hold3 = now_s(); if (now_s() - hold3 > 1.5) break; }
        else hold3 = 0;
        draw_pad_state(pad, &st, "Press EVERY button once (FN too), click both sticks, circle both sticks fast.",
                       "Done early? Hold any 3 buttons together for 2 s.", seconds - (now_s() - t0));
        usleep(4000);
    }
    int nb = q_SDL_JoystickNumButtons(g_js[pad]), seen = 0;
    for (int b = 0; b < nb && b < MAXB; b++) {
        plog("button%d = pressed %d times; mapped as '%s'\n", b, st.bcount[b], btn_name_for_raw(pad, b));
        if (st.bcount[b]) seen++;
    }
    for (int a = 0; a < na; a++) plog("axis%d.range = %d .. %d\n", a, st.amin[a], st.amax[a]);
    /* busiest 1-second window of axis value changes (any axis), polled every ~4 ms */
    int best = 0;
    for (int i = 0, j = 0; i < st.nts; i++) {
        while (st.ts[i] - st.ts[j] > 1.0) j++;
        if (i - j + 1 > best) best = i - j + 1;
    }
    double rate = best;
    kv("input.axis_changes_peak_per_s", "%d (busiest 1 s window, all axes; poll ~4 ms so caps near 250 per axis)", best);
    double maxsd = 0;
    for (int a = 0; a < na; a++) if (st.rest_sd[a] > maxsd) maxsd = st.rest_sd[a];
    ui_set_abort_enabled(true);
    summary("controls: %d axes, %d buttons (%d pressed), rest sd <= %.0f, peak axis changes %.0f/s", na, nb, seen,
            maxsd, rate);
    test_end();
}
