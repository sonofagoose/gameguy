/* gameguy hardware probe — entry point, logging, telemetry, watchdog, system info. */
#include "probe.h"
#include <errno.h>
#include <fcntl.h>
#include <glob.h>
#include <pthread.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/utsname.h>
#include <libgen.h>

const char *g_results_dir = "results";
char g_unit_id[32] = "unknown";

static FILE *g_log;
static int g_log_fd = -1;
static FILE *g_csv;
static char g_log_path[512];
static pthread_mutex_t g_log_mx = PTHREAD_MUTEX_INITIALIZER;
static volatile const char *g_cur_test = "startup";
static volatile double g_test_deadline;   /* 0 = none */
static volatile int g_abort;
static char g_summary[96][112];
static int g_nsummary;

double now_s(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

void plog(const char *fmt, ...) {
    va_list ap;
    pthread_mutex_lock(&g_log_mx);
    va_start(ap, fmt);
    if (g_log) { vfprintf(g_log, fmt, ap); fflush(g_log); }
    va_end(ap);
    va_start(ap, fmt);
    vfprintf(stdout, fmt, ap);
    fflush(stdout);
    va_end(ap);
    pthread_mutex_unlock(&g_log_mx);
}

void kv(const char *key, const char *fmt, ...) {
    char buf[4096];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    plog("%s = %s\n", key, buf);
}

void section(const char *name) { plog("\n## %s\n", name); }

void log_sync(void) {
    pthread_mutex_lock(&g_log_mx);
    if (g_log) fflush(g_log);
    if (g_log_fd >= 0) fsync(g_log_fd);
    if (g_csv) { fflush(g_csv); fsync(fileno(g_csv)); }
    pthread_mutex_unlock(&g_log_mx);
}

void summary(const char *fmt, ...) {
    char buf[112];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    plog("SUMMARY: %s\n", buf);
    if (g_nsummary < (int)(sizeof g_summary / sizeof g_summary[0]))
        snprintf(g_summary[g_nsummary++], sizeof g_summary[0], "%s", buf);
    ui_add_line(buf);
}

bool probe_aborted(void) {
    if (!g_abort && ui_abort_combo()) {
        g_abort = 1;
        plog("!! user requested skip (SELECT+START)\n");
    }
    return g_abort;
}

void test_begin(const char *name, int timeout_s) {
    g_cur_test = name;
    g_test_deadline = timeout_s > 0 ? now_s() + timeout_s : 0;
    section(name);
    char snap[160];
    telem_snapshot_line(snap, sizeof snap);
    plog("# begin %s | %s\n", name, snap);
    ui_status("%s", name);
    ui_frame();
}

void test_end(void) {
    char snap[160];
    telem_snapshot_line(snap, sizeof snap);
    plog("# end %s | %s\n", (const char *)g_cur_test, snap);
    g_test_deadline = 0;
    log_sync();
}

/* ---------- crash handler and watchdog ---------- */
static void write_all(int fd, const char *s) {
    size_t n = strlen(s);
    while (n) { ssize_t w = write(fd, s, n); if (w <= 0) return; s += w; n -= (size_t)w; }
}

static void on_fatal(int sig) {
    char buf[256];
    snprintf(buf, sizeof buf, "\n!!! FATAL: signal %d (%s) during test: %s\n", sig, strsignal(sig),
             (const char *)g_cur_test);
    if (g_log_fd >= 0) { write_all(g_log_fd, buf); fsync(g_log_fd); }
    write_all(2, buf);
    _exit(128 + sig);
}

static void *watchdog_thread(void *arg) {
    (void)arg;
    for (;;) {
        sleep(1);
        double d = g_test_deadline;
        if (d > 0 && now_s() > d) {
            char buf[256];
            snprintf(buf, sizeof buf, "\n!!! WATCHDOG: test '%s' exceeded its time limit; exiting\n",
                     (const char *)g_cur_test);
            if (g_log_fd >= 0) { write_all(g_log_fd, buf); fsync(g_log_fd); }
            write_all(2, buf);
            _exit(3);
        }
    }
    return NULL;
}

/* ---------- small file helpers ---------- */
static bool read_small(const char *path, char *buf, size_t n) {
    FILE *f = fopen(path, "r");
    if (!f) return false;
    size_t r = fread(buf, 1, n - 1, f);
    fclose(f);
    buf[r] = 0;
    while (r && (buf[r - 1] == '\n' || buf[r - 1] == ' ')) buf[--r] = 0;
    return true;
}

static double read_num(const char *path, double fallback) {
    char b[64];
    if (!read_small(path, b, sizeof b)) return fallback;
    return atof(b);
}

void log_file_contents(const char *path, size_t max_bytes) {
    FILE *f = fopen(path, "r");
    if (!f) { plog("--- %s: (not readable: %s)\n", path, strerror(errno)); return; }
    plog("--- %s\n", path);
    char *buf = malloc(max_bytes + 1);
    size_t r = fread(buf, 1, max_bytes, f);
    buf[r] = 0;
    fclose(f);
    plog("%s%s", buf, (r && buf[r - 1] != '\n') ? "\n" : "");
    if (r == max_bytes) plog("[... truncated at %zu bytes]\n", max_bytes);
    free(buf);
}

void log_cmd(const char *title, const char *cmd, size_t max_bytes) {
    plog("--- $ %s%s%s\n", cmd, title ? "   # " : "", title ? title : "");
    char full[1024];
    snprintf(full, sizeof full, "( %s ) 2>&1", cmd);
    FILE *p = popen(full, "r");
    if (!p) { plog("(popen failed)\n"); return; }
    char *buf = malloc(max_bytes + 1);
    size_t r = fread(buf, 1, max_bytes, p);
    buf[r] = 0;
    pclose(p);
    plog("%s%s", buf, (r && buf[r - 1] != '\n') ? "\n" : "");
    if (r == max_bytes) plog("[... truncated at %zu bytes]\n", max_bytes);
    free(buf);
}

uint64_t fnv1a(const void *data, size_t n, uint64_t h) {
    const uint8_t *p = data;
    if (!h) h = 1469598103934665603ULL;
    for (size_t i = 0; i < n; i++) { h ^= p[i]; h *= 1099511628211ULL; }
    return h;
}

/* ---------- telemetry ---------- */
#define MAX_DEVFREQ 6
#define MAX_THERMAL 6
static char t_cpu_path[256];
static int t_ndev, t_nth, t_gpu_idx = -1, t_ddr_idx = -1;
static char t_dev_path[MAX_DEVFREQ][256], t_dev_name[MAX_DEVFREQ][64];
static char t_th_path[MAX_THERMAL][256], t_th_name[MAX_THERMAL][64];
static char t_bat_dir[256];
static telem_stats_t t_stats;
static pthread_mutex_t t_mx = PTHREAD_MUTEX_INITIALIZER;
static double t_last[3 + MAX_DEVFREQ + MAX_THERMAL];
static double t0_global;

static void telem_discover(void) {
    snprintf(t_cpu_path, sizeof t_cpu_path, "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq");
    glob_t g;
    if (glob("/sys/class/devfreq/*", 0, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc && t_ndev < MAX_DEVFREQ; i++) {
            snprintf(t_dev_path[t_ndev], 256, "%s/cur_freq", g.gl_pathv[i]);
            char *b = strrchr(g.gl_pathv[i], '/');
            snprintf(t_dev_name[t_ndev], 64, "%s", b ? b + 1 : g.gl_pathv[i]);
            if (strstr(t_dev_name[t_ndev], "gpu") || strstr(t_dev_name[t_ndev], "ff400000")) t_gpu_idx = t_ndev;
            if (strstr(t_dev_name[t_ndev], "dmc")) t_ddr_idx = t_ndev;
            t_ndev++;
        }
        globfree(&g);
    }
    if (glob("/sys/class/thermal/thermal_zone*", 0, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc && t_nth < MAX_THERMAL; i++) {
            snprintf(t_th_path[t_nth], 256, "%s/temp", g.gl_pathv[i]);
            char tp[300], name[64] = "zone";
            snprintf(tp, sizeof tp, "%s/type", g.gl_pathv[i]);
            read_small(tp, name, sizeof name);
            snprintf(t_th_name[t_nth], 64, "%s", name);
            t_nth++;
        }
        globfree(&g);
    }
    if (glob("/sys/class/power_supply/*", 0, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++) {
            char tp[300], type[32] = "";
            snprintf(tp, sizeof tp, "%s/type", g.gl_pathv[i]);
            if (read_small(tp, type, sizeof type) && strcmp(type, "Battery") == 0) {
                snprintf(t_bat_dir, sizeof t_bat_dir, "%s", g.gl_pathv[i]);
                break;
            }
        }
        globfree(&g);
    }
}

static double bat_read(const char *leaf) {
    if (!t_bat_dir[0]) return NAN;
    char p[320];
    snprintf(p, sizeof p, "%s/%s", t_bat_dir, leaf);
    return read_num(p, NAN);
}

void telem_reset(void) {
    pthread_mutex_lock(&t_mx);
    memset(&t_stats, 0, sizeof t_stats);
    t_stats.min_cpu_mhz = t_stats.min_gpu_mhz = t_stats.min_ddr_mhz = 1e9;
    t_stats.batt_start_pct = bat_read("capacity");
    pthread_mutex_unlock(&t_mx);
}

telem_stats_t telem_get(void) {
    pthread_mutex_lock(&t_mx);
    telem_stats_t s = t_stats;
    pthread_mutex_unlock(&t_mx);
    if (s.min_gpu_mhz > 1e8) s.min_gpu_mhz = 0;
    if (s.min_ddr_mhz > 1e8) s.min_ddr_mhz = 0;
    if (s.min_cpu_mhz > 1e8) s.min_cpu_mhz = 0;
    s.batt_end_pct = bat_read("capacity");
    return s;
}

void telem_snapshot_line(char *buf, size_t n) {
    pthread_mutex_lock(&t_mx);
    double cpu = t_last[0];
    double gpu = t_gpu_idx >= 0 ? t_last[3 + t_gpu_idx] : NAN;
    double ddr = t_ddr_idx >= 0 ? t_last[3 + t_ddr_idx] : NAN;
    double tmax = -1;
    for (int i = 0; i < t_nth; i++) if (t_last[3 + MAX_DEVFREQ + i] > tmax) tmax = t_last[3 + MAX_DEVFREQ + i];
    pthread_mutex_unlock(&t_mx);
    snprintf(buf, n, "cpu %.0f MHz | gpu %.0f MHz | ddr %.0f MHz | %.1f C", cpu, gpu, ddr, tmax);
}

static void *telemetry_thread(void *arg) {
    (void)arg;
    for (;;) {
        double v[3 + MAX_DEVFREQ + MAX_THERMAL];
        v[0] = read_num(t_cpu_path, NAN) / 1000.0;               /* kHz -> MHz */
        v[1] = bat_read("capacity");
        v[2] = bat_read("voltage_now") / 1e6;                     /* uV -> V */
        for (int i = 0; i < t_ndev; i++) v[3 + i] = read_num(t_dev_path[i], NAN) / 1e6;   /* Hz -> MHz */
        for (int i = 0; i < t_nth; i++) v[3 + MAX_DEVFREQ + i] = read_num(t_th_path[i], NAN) / 1000.0;
        double cur_ma = bat_read("current_now") / 1000.0;
        pthread_mutex_lock(&t_mx);
        memcpy(t_last, v, sizeof v);
        t_stats.samples++;
        if (v[0] == v[0]) {
            if (v[0] < t_stats.min_cpu_mhz) t_stats.min_cpu_mhz = v[0];
            if (v[0] > t_stats.max_cpu_mhz) t_stats.max_cpu_mhz = v[0];
        }
        if (t_gpu_idx >= 0) {
            double g = v[3 + t_gpu_idx];
            if (g < t_stats.min_gpu_mhz) t_stats.min_gpu_mhz = g;
            if (g > t_stats.max_gpu_mhz) t_stats.max_gpu_mhz = g;
        }
        if (t_ddr_idx >= 0) {
            double d = v[3 + t_ddr_idx];
            if (d < t_stats.min_ddr_mhz) t_stats.min_ddr_mhz = d;
            if (d > t_stats.max_ddr_mhz) t_stats.max_ddr_mhz = d;
        }
        for (int i = 0; i < t_nth; i++)
            if (v[3 + MAX_DEVFREQ + i] > t_stats.max_temp_c) t_stats.max_temp_c = v[3 + MAX_DEVFREQ + i];
        pthread_mutex_unlock(&t_mx);
        if (g_csv) {
            pthread_mutex_lock(&g_log_mx);
            fprintf(g_csv, "%.2f,%s,%.0f", now_s() - t0_global, (const char *)g_cur_test, v[0]);
            for (int i = 0; i < t_ndev; i++) fprintf(g_csv, ",%.0f", v[3 + i]);
            for (int i = 0; i < t_nth; i++) fprintf(g_csv, ",%.1f", v[3 + MAX_DEVFREQ + i]);
            fprintf(g_csv, ",%.0f,%.3f,%.0f\n", v[1], v[2], cur_ma);
            fflush(g_csv);
            pthread_mutex_unlock(&g_log_mx);
        }
        usleep(250000);
    }
    return NULL;
}

/* ---------- unit identity ---------- */
static void compute_unit_id(void) {
    glob_t g;
    char cid[128] = "";
    if (glob("/sys/block/mmcblk*/device/type", 0, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++) {
            char type[16] = "";
            if (read_small(g.gl_pathv[i], type, sizeof type) && strcmp(type, "MMC") == 0) {
                char p[300];
                snprintf(p, sizeof p, "%s", g.gl_pathv[i]);
                char *slash = strrchr(p, '/');
                if (slash) strcpy(slash, "/cid");
                read_small(p, cid, sizeof cid);
                break;
            }
        }
        globfree(&g);
    }
    if (!cid[0]) {
        FILE *f = fopen("/proc/cpuinfo", "r");
        if (f) {
            char line[256];
            while (fgets(line, sizeof line, f))
                if (strncmp(line, "Serial", 6) == 0) { snprintf(cid, sizeof cid, "%s", line); break; }
            fclose(f);
        }
    }
    if (cid[0]) snprintf(g_unit_id, sizeof g_unit_id, "%06llx", (unsigned long long)(fnv1a(cid, strlen(cid), 0) & 0xffffff));
    else {
        char host[64] = "host";
        gethostname(host, sizeof host);
        snprintf(g_unit_id, sizeof g_unit_id, "%s", host);
    }
}

/* ---------- system information ---------- */
void sysinfo_run(void) {
    test_begin("System information", 60);
    struct utsname u;
    if (uname(&u) == 0) kv("uname", "%s %s %s %s", u.sysname, u.release, u.version, u.machine);
    log_file_contents("/etc/os-release", 4096);
    log_file_contents("/proc/device-tree/model", 256);
    log_cmd("dt compatible", "tr '\\0' ' ' < /proc/device-tree/compatible; echo", 512);
    log_file_contents("/proc/cmdline", 2048);
    log_file_contents("/proc/cpuinfo", 16384);
    log_file_contents("/proc/meminfo", 8192);
    log_cmd(NULL, "free -m", 2048);
    log_cmd("cpufreq", "for p in /sys/devices/system/cpu/cpufreq/policy*; do echo \"$p\"; for f in "
                       "scaling_governor scaling_available_governors scaling_available_frequencies cpuinfo_min_freq "
                       "cpuinfo_max_freq scaling_min_freq scaling_max_freq scaling_cur_freq related_cpus; do "
                       "printf '  %s: ' $f; cat $p/$f 2>/dev/null || echo '-'; done; done", 8192);
    log_cmd("devfreq (GPU, DDR)", "for d in /sys/class/devfreq/*; do echo \"$d\"; for f in name governor "
                                  "available_frequencies available_governors min_freq max_freq cur_freq "
                                  "trans_stat; do printf '  %s: ' $f; cat $d/$f 2>/dev/null | head -20 || echo '-'; "
                                  "done; done", 16384);
    log_cmd("thermal", "for z in /sys/class/thermal/thermal_zone*; do printf '%s %s %s\\n' \"$z\" "
                       "\"$(cat $z/type)\" \"$(cat $z/temp)\"; for t in $z/trip_point_*_temp; do "
                       "printf '   %s %s\\n' \"${t##*/}\" \"$(cat $t)\"; done; done", 8192);
    log_cmd("power supply", "for d in /sys/class/power_supply/*; do echo \"$d\"; cat $d/uevent 2>/dev/null; "
                            "done", 8192);
    log_cmd("mali", "cat /sys/class/misc/mali0/device/gpuinfo 2>/dev/null; "
                    "for n in core_mask core_availability_policy power_policy dvfs_period utilisation model clock; do "
                    "f=/sys/class/misc/mali0/device/$n; [ -e $f ] && printf '%s: %s\\n' $f \"$(cat $f "
                    "2>/dev/null | head -c 400)\"; done; cat /sys/module/mali_kbase/version 2>/dev/null; "
                    "ls /sys/module | grep -i -E 'mali|bifrost|panfrost'", 4096);
    log_cmd("GL/Vulkan userspace", "ls -l /usr/lib/aarch64-linux-gnu/ 2>/dev/null | grep -i -E "
                                   "'mali|libEGL|libGLES|libvulkan|libgbm|librga|rockchip_mpp|libSDL2|libasound' ; "
                                   "ls -l /usr/lib/aarch64-linux-gnu/mali/ 2>/dev/null; "
                                   "ls -l /usr/local/lib/aarch64-linux-gnu/ 2>/dev/null | head -40; "
                                   "for d in /etc/vulkan/icd.d /usr/share/vulkan/icd.d; do [ -d $d ] && "
                                   "{ echo $d; cat $d/*.json; }; done", 16384);
    log_cmd("DRM", "for c in /sys/class/drm/card*-*; do printf '%s status=%s\\n' \"$c\" \"$(cat $c/status "
                   "2>/dev/null)\"; cat $c/modes 2>/dev/null; done", 4096);
    log_cmd("storage", "for b in /sys/block/mmcblk*; do printf '%s size_sectors=%s ' \"$b\" \"$(cat $b/size)\"; "
                       "printf 'type=%s name=%s manfid=%s date=%s\\n' \"$(cat $b/device/type 2>/dev/null)\" "
                       "\"$(cat $b/device/name 2>/dev/null)\" \"$(cat $b/device/manfid 2>/dev/null)\" "
                       "\"$(cat $b/device/date 2>/dev/null)\"; done; cat /proc/partitions; "
                       "grep -E 'mmcblk|/roms' /proc/mounts; df -h 2>/dev/null | grep -v -E 'tmpfs|udev'", 8192);
    log_cmd("input devices", "cat /proc/bus/input/devices", 16384);
    log_cmd("audio", "cat /proc/asound/cards /proc/asound/pcm 2>/dev/null; ls /proc/asound/; "
                     "cat /etc/asound.conf 2>/dev/null; cat ~/.asoundrc 2>/dev/null", 8192);
    log_cmd("boot config", "for f in /boot/boot.ini /boot/extlinux/extlinux.conf /flash/boot.ini; do [ -f $f ] && "
                           "{ echo \"== $f\"; grep -v '^#' $f | grep -v '^$'; }; done", 8192);
    log_cmd("firmware identity", "cat /usr/share/plymouth/themes/text.plymouth 2>/dev/null | grep -i title; "
                                 "cat /home/ark/.config/.VERSION 2>/dev/null; ls /home/ark/.update/ 2>/dev/null; "
                                 "cat /opt/system/Tools/PortMaster/version /roms/tools/PortMaster/version "
                                 "/roms2/tools/PortMaster/version 2>/dev/null", 4096);
    log_cmd("modules", "cat /proc/modules | cut -d' ' -f1 | sort | tr '\\n' ' '; echo", 8192);
    log_cmd("usb", "for f in /sys/bus/platform/devices/ff300000.usb/dr_mode /sys/bus/platform/devices/ff300000.usb/otg_mode; do [ -e $f ] && "
                   "printf '%s: %s\\n' $f \"$(cat $f)\"; done; ls /sys/class/udc 2>/dev/null; "
                   "ls /sys/kernel/config/usb_gadget 2>/dev/null; cat /sys/kernel/debug/usb/devices 2>/dev/null | "
                   "head -40; ls /sys/bus/usb/devices", 4096);
    log_cmd("process environment", "id; echo \"SHELL=$SHELL HOME=$HOME\"; env | grep -E '^(SDL_|LD_|XDG_|DISPLAY|"
                                   "WAYLAND|ESUDO|controlfolder|directory)' | sort", 4096);
    log_cmd("clock summary (root only)", "cat /sys/kernel/debug/clk/clk_summary 2>/dev/null | grep -E -i "
                                         "'pll|aclk_gpu|clk_gpu|ddr|dmc|armclk|cpu|sclk' | head -60", 8192);
    test_end();
}

/* ---------- main ---------- */
static void usage(void) {
    printf("gameguy probe %s\n"
           "  --quick          skip the stress test and interactive input test\n"
           "  --stress N       stability phase length in seconds (default 60, 0 = skip)\n"
           "  --input N        interactive input test length in seconds (default 30, 0 = skip)\n"
           "  --windowed       640x480 window instead of fullscreen (desktop testing)\n"
           "  --out DIR        results directory (default ./results)\n",
           PROBE_VERSION);
}

int main(int argc, char **argv) {
    int stress_s = 60, input_s = 30;
    bool windowed = false;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--quick")) { stress_s = 0; input_s = 0; }
        else if (!strcmp(argv[i], "--stress") && i + 1 < argc) stress_s = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--input") && i + 1 < argc) input_s = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--windowed")) windowed = true;
        else if (!strcmp(argv[i], "--out") && i + 1 < argc) g_results_dir = argv[++i];
        else { usage(); return 2; }
    }

    signal(SIGSEGV, on_fatal); signal(SIGBUS, on_fatal); signal(SIGILL, on_fatal);
    signal(SIGFPE, on_fatal); signal(SIGABRT, on_fatal);
    signal(SIGPIPE, SIG_IGN);

    mkdir(g_results_dir, 0755);
    compute_unit_id();
    time_t tt = time(NULL);
    struct tm tmv;
    localtime_r(&tt, &tmv);
    char stamp[32];
    strftime(stamp, sizeof stamp, "%Y%m%d-%H%M%S", &tmv);
    snprintf(g_log_path, sizeof g_log_path, "%s/probe-%s-%s.txt", g_results_dir, g_unit_id, stamp);
    g_log = fopen(g_log_path, "w");
    if (!g_log) { fprintf(stderr, "cannot open %s: %s\n", g_log_path, strerror(errno)); return 1; }
    g_log_fd = fileno(g_log);
    char csv_path[512];
    snprintf(csv_path, sizeof csv_path, "%s/telemetry-%s-%s.csv", g_results_dir, g_unit_id, stamp);
    g_csv = fopen(csv_path, "w");

    t0_global = now_s();
    plog("# gameguy hardware probe %s\n", PROBE_VERSION);
    kv("unit_id", "%s", g_unit_id);
    kv("started", "%s", stamp);
    kv("args", "stress=%d input=%d windowed=%d", stress_s, input_s, windowed);
    kv("log", "%s", g_log_path);
    kv("telemetry_csv", "%s", csv_path);

    telem_discover();
    if (g_csv) {
        fprintf(g_csv, "t_s,test,cpu0_mhz");
        for (int i = 0; i < t_ndev; i++) fprintf(g_csv, ",%s_mhz", t_dev_name[i]);
        for (int i = 0; i < t_nth; i++) fprintf(g_csv, ",%s_c", t_th_name[i]);
        fprintf(g_csv, ",batt_pct,batt_v,batt_ma\n");
    }
    telem_reset();
    pthread_t th;
    pthread_create(&th, NULL, telemetry_thread, NULL);
    pthread_detach(th);
    pthread_create(&th, NULL, watchdog_thread, NULL);
    pthread_detach(th);
    usleep(300000);   /* first telemetry sample */

    if (!sdl_load()) {
        plog("!! SDL2 could not be loaded; running non-graphical tests only\n");
    } else if (!gfx_init(windowed)) {
        plog("!! graphics init failed; running non-graphical tests only\n");
    }

    int steps = 9 + (input_s > 0) + (stress_s > 0), step = 0;
    ui_progress(++step, steps); sysinfo_run();
    if (!probe_aborted()) { ui_progress(++step, steps); cpu_tests_run(); }
    if (!probe_aborted()) { ui_progress(++step, steps); storage_test_run(); }
    if (!probe_aborted() && g_gfx_ok) { ui_progress(++step, steps); gpu_tests_run(); }
    if (!probe_aborted() && g_gfx_ok) { ui_progress(++step, steps); display_test_run(); }
    if (!probe_aborted()) { ui_progress(++step, steps); audio_tests_run(); }
    if (!probe_aborted() && input_s > 0) { ui_progress(++step, steps); input_test_run(input_s); }
    if (!probe_aborted() && stress_s > 0) { ui_progress(++step, steps); stress_run(stress_s); }
    ui_progress(++step, steps); vulkan_probe_run();

    test_begin("Kernel log tail", 30);
    log_cmd("dmesg (last 150 lines; may need root)", "dmesg 2>&1 | tail -n 150", 65536);
    test_end();

    section("SUMMARY");
    for (int i = 0; i < g_nsummary; i++) plog("  %s\n", g_summary[i]);
    kv("total_runtime_s", "%.1f", now_s() - t0_global);
    plog("# done\n");
    log_sync();

    /* final screen: wait for a button (or 120 s) */
    if (g_gfx_ok) {
        double t_end = now_s() + 120;
        bool released = !ui_any_button_pressed();
        while (now_s() < t_end) {
            ui_begin_frame(0x0b1a10ff);
            ui_text(FONT_L, 16, 10, 0x7dff9aff, "PROBE COMPLETE");
            ui_textf(FONT_S, 16, 52, 0xb0c4b8ff, "unit %s  |  %.0f s  |  %s", g_unit_id, now_s() - t0_global,
                     g_gl_renderer);
            int first = g_nsummary > 15 ? g_nsummary - 15 : 0;
            for (int i = first; i < g_nsummary; i++)
                ui_text(FONT_S, 16, 84 + (i - first) * 22, 0xe8f0eaff, g_summary[i]);
            char *b = strrchr(g_log_path, '/');
            ui_textf(FONT_S, 16, gfx_h - 52, 0xffd36bff, "saved: %.60s", b ? b + 1 : g_log_path);
            ui_text(FONT_S, 16, gfx_h - 28, 0xb0c4b8ff, "Press any button to exit.");
            ui_present();
            bool pressed = ui_any_button_pressed();
            if (released && pressed) break;
            if (!pressed) released = true;
            usleep(16000);
        }
    }
    gfx_shutdown();
    log_sync();
    if (g_csv) fclose(g_csv);
    fclose(g_log);
    sync();
    return 0;
}
