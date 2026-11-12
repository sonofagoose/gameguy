/* gameguy probe — Vulkan availability and device properties (no rendering). */
#include "probe.h"
#include <dlfcn.h>
#define VK_NO_PROTOTYPES
#include <vulkan/vulkan_core.h>

static void ver_str(uint32_t v, char *b, size_t n) {
    snprintf(b, n, "%u.%u.%u", VK_API_VERSION_MAJOR(v), VK_API_VERSION_MINOR(v), VK_API_VERSION_PATCH(v));
}

void vulkan_probe_run(void) {
    test_begin("Vulkan", 60);
    log_cmd("ICD manifests", "ls -l /etc/vulkan/icd.d /usr/share/vulkan/icd.d 2>&1; "
                             "cat /etc/vulkan/icd.d/*.json /usr/share/vulkan/icd.d/*.json 2>/dev/null", 8192);
    PFN_vkGetInstanceProcAddr gipa = NULL;
    const char *how = NULL;
    void *lib = dlopen("libvulkan.so.1", RTLD_NOW | RTLD_LOCAL);
    if (lib) { gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr"); how = "loader libvulkan.so.1"; }
    if (!gipa) {
        const char *icds[] = {"libMaliVulkan.so.1", "libmali.so", "libMali.so", NULL};
        for (int i = 0; icds[i] && !gipa; i++) {
            void *l = dlopen(icds[i], RTLD_NOW | RTLD_LOCAL);
            if (!l) continue;
            gipa = (PFN_vkGetInstanceProcAddr)dlsym(l, "vk_icdGetInstanceProcAddr");
            if (gipa) how = icds[i];
        }
    }
    if (!gipa) { summary("Vulkan: not available (no loader or Mali ICD)"); test_end(); return; }
    kv("vk.entry", "%s", how);
    PFN_vkEnumerateInstanceVersion eiv = (PFN_vkEnumerateInstanceVersion)gipa(NULL, "vkEnumerateInstanceVersion");
    uint32_t iver = VK_API_VERSION_1_0;
    if (eiv) eiv(&iver);
    char vb[32];
    ver_str(iver, vb, sizeof vb);
    kv("vk.instance_version", "%s", vb);
    PFN_vkCreateInstance ci = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
    if (!ci) { summary("Vulkan: vkCreateInstance missing (%s)", how); test_end(); return; }
    VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "gameguy-probe", 1, "none", 1,
                             iver >= VK_API_VERSION_1_1 ? VK_API_VERSION_1_1 : VK_API_VERSION_1_0};
    VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, NULL, 0, &app, 0, NULL, 0, NULL};
    VkInstance inst = VK_NULL_HANDLE;
    VkResult r = ci(&ici, NULL, &inst);
    if (r != VK_SUCCESS) { summary("Vulkan: vkCreateInstance failed (%d) via %s", r, how); test_end(); return; }
    PFN_vkEnumeratePhysicalDevices epd = (PFN_vkEnumeratePhysicalDevices)gipa(inst, "vkEnumeratePhysicalDevices");
    PFN_vkGetPhysicalDeviceProperties gpp = (PFN_vkGetPhysicalDeviceProperties)gipa(inst, "vkGetPhysicalDeviceProperties");
    PFN_vkGetPhysicalDeviceFeatures gpf = (PFN_vkGetPhysicalDeviceFeatures)gipa(inst, "vkGetPhysicalDeviceFeatures");
    PFN_vkGetPhysicalDeviceMemoryProperties gpm =
        (PFN_vkGetPhysicalDeviceMemoryProperties)gipa(inst, "vkGetPhysicalDeviceMemoryProperties");
    PFN_vkEnumerateDeviceExtensionProperties ede =
        (PFN_vkEnumerateDeviceExtensionProperties)gipa(inst, "vkEnumerateDeviceExtensionProperties");
    PFN_vkGetPhysicalDeviceQueueFamilyProperties gqf =
        (PFN_vkGetPhysicalDeviceQueueFamilyProperties)gipa(inst, "vkGetPhysicalDeviceQueueFamilyProperties");
    PFN_vkDestroyInstance di = (PFN_vkDestroyInstance)gipa(inst, "vkDestroyInstance");
    uint32_t n = 0;
    if (epd) epd(inst, &n, NULL);
    kv("vk.physical_devices", "%u", n);
    VkPhysicalDevice devs[4];
    if (n > 4) n = 4;
    if (n && epd) epd(inst, &n, devs);
    char first[160] = "none";
    for (uint32_t i = 0; i < n; i++) {
        VkPhysicalDeviceProperties p;
        gpp(devs[i], &p);
        char av[32];
        ver_str(p.apiVersion, av, sizeof av);
        plog("vk.device[%u] = %s | api %s | driver 0x%08x | vendor 0x%04x device 0x%04x | type %d\n", i, p.deviceName,
             av, p.driverVersion, p.vendorID, p.deviceID, p.deviceType);
        if (i == 0) snprintf(first, sizeof first, "%s, Vulkan %s", p.deviceName, av);
        VkPhysicalDeviceLimits *L = &p.limits;
        plog("  limits: maxImageDimension2D %u, maxComputeSharedMemorySize %u, maxComputeWorkGroupInvocations %u, "
             "maxPerStageDescriptorSamplers %u, maxColorAttachments %u, framebufferColorSampleCounts 0x%x, "
             "timestampPeriod %.2f ns, maxPushConstantsSize %u\n",
             L->maxImageDimension2D, L->maxComputeSharedMemorySize, L->maxComputeWorkGroupInvocations,
             L->maxPerStageDescriptorSamplers, L->maxColorAttachments, L->framebufferColorSampleCounts,
             L->timestampPeriod, L->maxPushConstantsSize);
        if (gpf) {
            VkPhysicalDeviceFeatures f;
            gpf(devs[i], &f);
            plog("  features: geometryShader %u tessellationShader %u textureCompressionASTC_LDR %u "
                 "textureCompressionETC2 %u shaderFloat64 %u shaderInt16 %u fragmentStoresAndAtomics %u "
                 "sampleRateShading %u\n",
                 f.geometryShader, f.tessellationShader, f.textureCompressionASTC_LDR, f.textureCompressionETC2,
                 f.shaderFloat64, f.shaderInt16, f.fragmentStoresAndAtomics, f.sampleRateShading);
        }
        if (gpm) {
            VkPhysicalDeviceMemoryProperties m;
            gpm(devs[i], &m);
            for (uint32_t h = 0; h < m.memoryHeapCount; h++)
                plog("  heap[%u] = %.0f MB flags 0x%x\n", h, m.memoryHeaps[h].size / 1e6, m.memoryHeaps[h].flags);
            for (uint32_t t = 0; t < m.memoryTypeCount; t++)
                plog("  memtype[%u] heap %u flags 0x%x\n", t, m.memoryTypes[t].heapIndex, m.memoryTypes[t].propertyFlags);
        }
        if (gqf) {
            uint32_t nq = 0;
            gqf(devs[i], &nq, NULL);
            VkQueueFamilyProperties q[8];
            if (nq > 8) nq = 8;
            gqf(devs[i], &nq, q);
            for (uint32_t k = 0; k < nq; k++)
                plog("  queue_family[%u] flags 0x%x count %u timestampValidBits %u\n", k, q[k].queueFlags, q[k].queueCount,
                     q[k].timestampValidBits);
        }
        if (ede) {
            uint32_t ne = 0;
            ede(devs[i], NULL, &ne, NULL);
            VkExtensionProperties *e = calloc(ne ? ne : 1, sizeof *e);
            ede(devs[i], NULL, &ne, e);
            plog("  device extensions (%u):\n", ne);
            for (uint32_t k = 0; k < ne; k++) plog("    %s v%u\n", e[k].extensionName, e[k].specVersion);
            free(e);
        }
    }
    if (di) di(inst, NULL);
    summary("Vulkan: %s (via %s)", first, how);
    test_end();
}
