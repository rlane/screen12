#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>
#include <stdbool.h>
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

/* Symbols */
static mrb_value sym_fill, sym_round, sym_aa;

static void sym_init(mrb_state *mrb)
{
    sym_fill = mrb_symbol_value(mrb_intern(mrb, "fill"));
    sym_round = mrb_symbol_value(mrb_intern(mrb, "round"));
    sym_aa = mrb_symbol_value(mrb_intern(mrb, "aa"));
}


/* API functions */

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
    bool antialiased = false;
    mrb_value opts;
    int argc = mrb_get_args(mrb, "iiii|o", &x1, &y1, &x2, &y2, &opts);
    if (argc > 4) {
        antialiased = mrb_test(mrb_hash_get(mrb, opts, sym_aa));
    }
    if (antialiased) {
        aalineColor(screen, x1, y1, x2, y2, color);
    } else {
        lineColor(screen, x1, y1, x2, y2, color);
    }
    return mrb_nil_value();
}

static mrb_value api_box(mrb_state *mrb, mrb_value self)
{
    mrb_int x1, y1, x2, y2;
    mrb_value opts;
    int r = 0;
    bool fill = false, rounded = false;
    int argc = mrb_get_args(mrb, "iiii|o", &x1, &y1, &x2, &y2, &opts);
    if (argc > 4) {
        fill = mrb_test(mrb_hash_get(mrb, opts, sym_fill));
        rounded = mrb_test(mrb_hash_get(mrb, opts, sym_round));
    }
    if (rounded) {
      r = mrb_fixnum(mrb_hash_get(mrb, opts, sym_round)); // TODO check
    }
    if (fill) {
        if (rounded) {
            roundedBoxColor(screen, x1, y1, x2, y2, r, color);
        } else {
            boxColor(screen, x1, y1, x2, y2, color);
        }
    } else {
        if (rounded) {
            roundedRectangleColor(screen, x1, y1, x2, y2, r, color);
        } else {
            rectangleColor(screen, x1, y1, x2, y2, color);
        }
    }
    return mrb_nil_value();
}

static mrb_value api_circle(mrb_state *mrb, mrb_value self)
{
    mrb_int x, y, r;
    mrb_value opts;
    bool fill = false, antialiased = false;
    int argc = mrb_get_args(mrb, "iii|o", &x, &y, &r, &opts);
    if (argc > 3) {
        fill = mrb_test(mrb_hash_get(mrb, opts, sym_fill));
        antialiased = mrb_test(mrb_hash_get(mrb, opts, sym_aa));
    }
    if (fill) {
        if (antialiased) {
            // HACK SDL_gfx doesn't have an aafilledCircleColor function
            int alpha = color & 0xFF;
            if (alpha != 0xFF) {
                // Jitter antialiasing. TODO this is slow and low quality.
                const int num_passes = 4;
                int pass_color = (color & ~0xFF) | (alpha/num_passes);
                filledCircleColor(screen, x+1, y+1, r, pass_color);
                filledCircleColor(screen, x+1, y, r, pass_color);
                filledCircleColor(screen, x, y+1, r, pass_color);
                filledCircleColor(screen, x, y, r, pass_color);
            } else {
                filledCircleColor(screen, x, y, r, color);
                aacircleColor(screen, x, y, r, color);
            }
        } else {
            filledCircleColor(screen, x, y, r, color);
        }
    } else {
        if (antialiased) {
            aacircleColor(screen, x, y, r, color);
        } else {
            circleColor(screen, x, y, r, color);
        }
    }
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

void api_init(mrb_state *mrb)
{
    sym_init(mrb);

    mrb_define_method(mrb, mrb->kernel_module, "color", api_color, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "line", api_line, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "box", api_box, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "circle", api_circle, ARGS_REQ(3) | ARGS_OPT(1));
    mrb_define_method(mrb, mrb->kernel_module, "delay", api_delay, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "flip", api_flip, ARGS_NONE());

    mrb_define_const(mrb, mrb->kernel_module, "SCREEN_WIDTH", mrb_fixnum_value(screen_width));
    mrb_define_const(mrb, mrb->kernel_module, "SCREEN_HEIGHT", mrb_fixnum_value(screen_height));
}
