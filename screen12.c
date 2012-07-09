#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>
#include <stdbool.h>
#include <signal.h>
#include <SDL.h>
#include <SDL_gfxPrimitives.h>

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

SDL_Surface *screen;
uint32_t color = 0xFFFFFFFF;
int screen_width = 800, screen_height = 600;

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "usage: %s path/to/program.rb\n", argv[0]);
        return 1;
    }

    char *path = argv[1];

    mrb_state *mrb = mrb_open();

    if (mrb == NULL) {
        fprintf(stderr, "Invalid mrb_state, exiting mruby");
        return EXIT_FAILURE;
    }

    mrb_irep *lib_irep = parse_file(mrb, "lib.rb");
    if (lib_irep == NULL) {
        return 1;
    }

    mrb_irep *main_irep = parse_file(mrb, path);
    if (main_irep == NULL) {
        return 1;
    }

    SDL_Init(SDL_INIT_EVERYTHING);
    signal(SIGINT, SIG_DFL);

    screen = SDL_SetVideoMode(screen_width, screen_height, 0, SDL_SWSURFACE);

    api_init(mrb);

    mrb_run(mrb, mrb_proc_new(mrb, lib_irep), mrb_top_self(mrb));
    if (mrb->exc) {
        mrb_p(mrb, mrb_obj_value(mrb->exc));
        return 1;
    }

    mrb_run(mrb, mrb_proc_new(mrb, main_irep), mrb_top_self(mrb));
    if (mrb->exc) {
        mrb_p(mrb, mrb_obj_value(mrb->exc));
        return 1;
    }

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

    int n = mrb_generate_code(mrb, p->tree);
    if (n < 0) {
        fprintf(stderr, "failed to generate code for %s\n", filename);
        return NULL;
    }

    mrb_parser_free(p);

    return mrb->irep[n];
}
