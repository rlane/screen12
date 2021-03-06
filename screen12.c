#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>
#include <stdbool.h>
#include <signal.h>
#include <time.h>
#include <SDL.h>
#include <SDL_gfxPrimitives.h>
#include <SDL_mixer.h>

#include "mruby.h"
#include "mruby/proc.h"
#include "mruby/array.h"
#include "mruby/string.h"
#include "mruby/compile.h"
#include "mruby/dump.h"
#include "mruby/hash.h"

#include "main.h"
#include "api.h"

static mrb_irep *parse_file(mrb_state *mrb, const char *filename);
static int lib_init(mrb_state *mrb);

SDL_Surface *screen;
uint32_t color = 0xFFFFFFFF;
int screen_width = 800, screen_height = 600;
int audio_sampling_freq = MIX_DEFAULT_FREQUENCY;
int audio_max_amp = 32767;
int random_seed;

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "usage: %s path/to/program.rb\n", argv[0]);
        return 1;
    }

    char *path = argv[1];

    mrb_state *mrb = mrb_open();

    if (mrb == NULL) {
        fprintf(stderr, "Failed to create Ruby interpreter\n");
        return EXIT_FAILURE;
    }
    
    mrb_irep *main_irep = parse_file(mrb, path);
    if (main_irep == NULL) {
        fprintf(stderr, "Failed to parse file\n");
        return 1;
    }

    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO);
    signal(SIGINT, SIG_DFL);

    screen = SDL_SetVideoMode(screen_width, screen_height, 0, SDL_SWSURFACE);

    if (Mix_OpenAudio(audio_sampling_freq, AUDIO_S16SYS, 1, 4096) < 0) {
        fprintf(stderr, "Mix_OpenAudio: %s\n", Mix_GetError());
        return 1;
    }

    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    random_seed = ts.tv_nsec;
    api_init(mrb);

    if (lib_init(mrb)) {
        fprintf(stderr, "Failed to initialize libraries\n");
        return 1;
    }

    mrb_run(mrb, mrb_proc_new(mrb, main_irep), mrb_top_self(mrb));
    if (mrb->exc) {
        fprintf(stderr, "Failed to run program\n");
        mrb_p(mrb, mrb_obj_value(mrb->exc));
        return 1;
    }

    Mix_CloseAudio();

    return 0;
}

static mrb_irep *parse_file(mrb_state *mrb, const char *filename)
{
    FILE *file = fopen(filename, "r");
    if (!file) {
        fprintf(stderr, "failed to open %s\n", filename);
        return NULL;
    }

    mrbc_context *c = mrbc_context_new(mrb);
    mrbc_filename(mrb, c, filename);
    struct mrb_parser_state *p = mrb_parse_file(mrb, file, c);
    mrbc_context_free(mrb, c);
    fclose(file);

    if (!p || !p->tree || p->nerr) {
        fprintf(stderr, "failed to parse %s\n", filename);
        return NULL;
    }

    int n = mrb_generate_code(mrb, p);
    if (n < 0) {
        fprintf(stderr, "failed to generate code for %s\n", filename);
        return NULL;
    }

    mrb_parser_free(p);

    return mrb->irep[n];
}

static int lib_init(mrb_state *mrb)
{
    const char *libs[] = {
        "lib/image.rb",
        "lib/math.rb",
        "lib/prng.rb",
        "lib/sound.rb",
        NULL,
    };

    int i;
    for (i = 0; libs[i]; i++) {
        mrb_irep *lib_irep = parse_file(mrb, libs[i]);
        if (lib_irep == NULL) {
            return 1;
        }

        mrb_run(mrb, mrb_proc_new(mrb, lib_irep), mrb_top_self(mrb));
        if (mrb->exc) {
            mrb_p(mrb, mrb_obj_value(mrb->exc));
            return 1;
        }
    }

    return 0;
}
