/* C declarations the toy uses, translated to Zig at build time (zig translate-c).
 * SDL2 and OpenGL ES are only *declared* here: both are loaded at run time with dlopen. */
#define GL_GLES_PROTOTYPES 0
#include <GLES3/gl32.h>
#include <SDL2/SDL.h>
#include <dlfcn.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
