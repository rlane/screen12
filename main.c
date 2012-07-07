#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>
#include <SDL.h>
#include <SDL_gfxPrimitives.h>

#include "mruby.h"
#include "mruby/proc.h"
#include "mruby/array.h"
#include "mruby/string.h"
#include "mruby/compile.h"
#include "mruby/dump.h"

static mrb_irep *parse_file(mrb_state *mrb, const char *filename);
static void api_register(mrb_state *mrb);

static SDL_Surface *screen;
static uint32_t color;

int main(int argc, char **argv)
{
    mrb_state *mrb = mrb_open();

    if (mrb == NULL) {
        fprintf(stderr, "Invalid mrb_state, exiting mruby");
        return EXIT_FAILURE;
    }

    char *path = argv[1];

    mrb_irep *lib_irep = parse_file(mrb, "lib.rb");
    if (lib_irep == NULL) {
        return 1;
    }

    mrb_irep *main_irep = parse_file(mrb, path);
    if (main_irep == NULL) {
        return 1;
    }

    api_register(mrb);

    SDL_Init(SDL_INIT_EVERYTHING);
    screen = SDL_SetVideoMode(640, 480, 32, SDL_SWSURFACE);
    color = 0xFFFFFFFF;

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

static mrb_value api_color(mrb_state *mrb, mrb_value self)
{
    mrb_int r, g, b, a;
    mrb_get_args(mrb, "iiii", &r, &g, &b, &a);
    color = (r<<24) | (g<<16) | (b<<8) | a;
    return mrb_nil_value();
}

static mrb_value api_line(mrb_state *mrb, mrb_value self)
{
    mrb_int x1, y1, x2, y2;
    mrb_get_args(mrb, "iiii", &x1, &y1, &x2, &y2);
    lineColor(screen, x1, y1, x2, y2, color);
    return mrb_nil_value();
}

static mrb_value api_flip(mrb_state *mrb, mrb_value self)
{
    SDL_Flip(screen);
    return mrb_nil_value();
}

static mrb_value api_delay(mrb_state *mrb, mrb_value self)
{
    mrb_int ms;
    mrb_get_args(mrb, "i", &ms);
    SDL_Delay(ms);
    return mrb_nil_value();
}

static void api_register(mrb_state *mrb)
{
    mrb_define_method(mrb, mrb->kernel_module, "color", api_color, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "line", api_line, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "delay", api_delay, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "flip", api_flip, ARGS_NONE());
}
