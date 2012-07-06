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
    FILE *file = fopen(path, "r");
    if (!file) {
        fprintf(stderr, "failed to open file\n");
        return 1;
    }

    mrbc_context *c = mrbc_context_new(mrb);
    mrbc_filename(mrb, c, path);
    struct mrb_parser_state *p = mrb_parse_file(mrb, file, c);
    mrbc_context_free(mrb, c);
    if (!p || !p->tree || p->nerr) {
        fprintf(stderr, "failed to parse file\n");
        return 1;
    }

    int n = mrb_generate_code(mrb, p->tree);
    if (n < 0) {
        fprintf(stderr, "failed to generate code\n");
        return 1;
    }

    mrb_parser_free(p);

    api_register(mrb);

    SDL_Init(SDL_INIT_EVERYTHING);
    screen = SDL_SetVideoMode(640, 480, 32, SDL_SWSURFACE);
    color = 0xFFFFFFFF;

    mrb_run(mrb, mrb_proc_new(mrb, mrb->irep[n]), mrb_top_self(mrb));
    if (mrb->exc) {
        mrb_p(mrb, mrb_obj_value(mrb->exc));
    }

    SDL_Delay(1000);

    return 0;
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
    SDL_Flip(screen);
    SDL_Delay(100);
    return mrb_nil_value();
}

static void api_register(mrb_state *mrb)
{
  mrb_define_method(mrb, mrb->kernel_module, "color", api_color, ARGS_REQ(4));
  mrb_define_method(mrb, mrb->kernel_module, "line", api_line, ARGS_REQ(4));
}
