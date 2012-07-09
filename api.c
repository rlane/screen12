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
static mrb_value sym_fill, sym_aa, sym_position, sym_rotation;

static void sym_init(mrb_state *mrb)
{
    sym_fill = mrb_symbol_value(mrb_intern(mrb, "fill"));
    sym_aa = mrb_symbol_value(mrb_intern(mrb, "aa"));
    sym_position = mrb_symbol_value(mrb_intern(mrb, "position"));
    sym_rotation = mrb_symbol_value(mrb_intern(mrb, "rotation"));
}


/* SDL event handling */

struct pressed_key {
    bool valid;
    SDL_keysym keysym;
};

#define MAX_PRESSED_KEYS 16
struct pressed_key pressed_keys[MAX_PRESSED_KEYS];

/* TODO dont miss short keypresses */
static void handle_keyboard_event(const SDL_KeyboardEvent *event, bool down)
{
    if (event->keysym.sym == SDLK_ESCAPE) {
        exit(0);
    }

    //fprintf(stderr, "key '%s' %s\n", SDL_GetKeyName(event->keysym.sym), down ? "down": "up");

    int i;
    for (i = 0; i < MAX_PRESSED_KEYS; i++) {
        struct pressed_key *pk = &pressed_keys[i];
        if (down) {
            if (!pk->valid) {
                pk->keysym = event->keysym;
                pk->valid = true;
                //fprintf(stderr, "added key '%s' at index %d\n", SDL_GetKeyName(pk->keysym.sym), i);
                break;
            } 
        } else {
            if (pk->valid && pk->keysym.sym == event->keysym.sym) {
                pk->valid = false;
                //fprintf(stderr, "removed key '%s' at index %d\n", SDL_GetKeyName(pk->keysym.sym), i);
                /* Keep going to ensure unbalanced keydowns get cleaned up */
            }
        }
    }
}

static void process_events(void)
{
    SDL_Event event;

    while (SDL_PollEvent(&event)) {
        switch (event.type) {
        case SDL_QUIT:
            exit(0);
            break;
        case SDL_KEYDOWN:
        case SDL_KEYUP:
            handle_keyboard_event(&event.key, event.type == SDL_KEYDOWN);
            break;
        }
    }
}


/* API functions */

static mrb_value api_color(mrb_state *mrb, mrb_value self)
{
    mrb_int r, g, b, a;
    mrb_get_args(mrb, "iiii", &r, &g, &b, &a);
    color = (r<<24) | (g<<16) | (b<<8) | a;
    return mrb_nil_value();
}

static mrb_value api_clear(mrb_state *mrb, mrb_value self)
{
    boxColor(screen, 0, 0, screen_width, screen_height, 0xFF);
    return mrb_nil_value();
}

static mrb_value api_point(mrb_state *mrb, mrb_value self)
{
    mrb_int x, y;
    mrb_get_args(mrb, "ii", &x, &y);
    pixelColor(screen, x, y, color);
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
    bool fill = false;
    int argc = mrb_get_args(mrb, "iiii|o", &x1, &y1, &x2, &y2, &opts);
    if (argc > 4) {
        fill = mrb_test(mrb_hash_get(mrb, opts, sym_fill));
    }
    if (fill) {
        boxColor(screen, x1, y1, x2, y2, color);
    } else {
        rectangleColor(screen, x1, y1, x2, y2, color);
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

static mrb_value api_polygon(mrb_state *mrb, mrb_value self)
{
    mrb_value coords_arg, position_arg, rotation_arg, opts;
    bool fill = false, antialiased = false, translated = false, rotated = false;
    int argc = mrb_get_args(mrb, "o|o", &coords_arg, &opts);
    if (argc > 1) {
        fill = mrb_test(mrb_hash_get(mrb, opts, sym_fill));
        antialiased = mrb_test(mrb_hash_get(mrb, opts, sym_aa));
        position_arg = mrb_hash_get(mrb, opts, sym_position);
        translated = mrb_test(position_arg);
        rotation_arg = mrb_hash_get(mrb, opts, sym_rotation);
        rotated = mrb_test(rotation_arg);
    }

    int tx = 0, ty = 0;
    if (translated) {
        mrb_value position = mrb_check_array_type(mrb, position_arg);
        if (RARRAY_LEN(position) != 2) {
            mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid position array");
        }
        mrb_value xo = mrb_check_to_integer(mrb, RARRAY_PTR(position)[0], "to_i");
        mrb_check_type(mrb, xo, MRB_TT_FIXNUM);
        tx = mrb_fixnum(xo);
        mrb_value yo = mrb_check_to_integer(mrb, RARRAY_PTR(position)[1], "to_i");
        mrb_check_type(mrb, yo, MRB_TT_FIXNUM);
        ty = mrb_fixnum(yo);
    }

    double rotation = 0.0;
    if (rotated) {
        mrb_check_type(mrb, rotation_arg, MRB_TT_FLOAT);
        rotation = mrb_float(rotation_arg);
    }

    mrb_value coords = mrb_check_array_type(mrb, coords_arg);
    int n = RARRAY_LEN(coords) / 2;
    if (n < 3 || n * 2 != RARRAY_LEN(coords) || n > 1024) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid coordinates array");
    }

    int16_t *xs = alloca(n * sizeof(*xs));
    int16_t *ys = alloca(n * sizeof(*ys));
    int i;
    for (i = 0; i < n; i++) {
        mrb_float x = mrb_float(mrb_Float(mrb, RARRAY_PTR(coords)[2*i]));
        mrb_float y = mrb_float(mrb_Float(mrb, RARRAY_PTR(coords)[2*i+1]));
        xs[i] = (int)(tx + x*cos(rotation) - y*sin(rotation));
        ys[i] = (int)(ty + x*sin(rotation) + y*cos(rotation));
    }

    if (fill) {
        // TODO filled antialiased polygons
        filledPolygonColor(screen, xs, ys, n, color);
    } else {
        if (antialiased) {
            aapolygonColor(screen, xs, ys, n, color);
        } else {
            polygonColor(screen, xs, ys, n, color);
        }
    }

    return mrb_nil_value();
}

static mrb_value api_text(mrb_state *mrb, mrb_value self)
{
    int x, y;
    mrb_value str;
    mrb_get_args(mrb, "iio", &x, &y, &str);
    stringColor(screen, x, y, mrb_string_value_cstr(mrb, &str), color);
    return mrb_nil_value();
}

static mrb_value api_display(mrb_state *mrb, mrb_value self)
{
    SDL_Flip(screen);
    return mrb_nil_value();
}

static mrb_value api_time(mrb_state *mrb, mrb_value self)
{
    return mrb_fixnum_value((int)SDL_GetTicks());
}

static mrb_value api_delay(mrb_state *mrb, mrb_value self)
{
    mrb_int ms;
    mrb_get_args(mrb, "i", &ms);
    if (ms > 0) {
      SDL_Delay(ms);
    }
    return mrb_nil_value();
}

static mrb_value api_keys(mrb_state *mrb, mrb_value self)
{
    process_events();
    mrb_value keys = mrb_ary_new(mrb);

    int i;
    for (i = 0; i < MAX_PRESSED_KEYS; i++) {
        struct pressed_key *pk = &pressed_keys[i];
        if (!pk->valid) {
            continue;
        }
        mrb_ary_push(mrb, keys, mrb_str_new_cstr(mrb, SDL_GetKeyName(pk->keysym.sym)));
    }

    return keys;
}

static mrb_value api_mouse_position(mrb_state *mrb, mrb_value self)
{
    process_events();
    int x, y;
    SDL_GetMouseState(&x, &y);
    mrb_value pos = mrb_ary_new(mrb);
    mrb_ary_push(mrb, pos, mrb_fixnum_value(x));
    mrb_ary_push(mrb, pos, mrb_fixnum_value(y));
    return pos;
}

static mrb_value api_mouse_buttons(mrb_state *mrb, mrb_value self)
{
    process_events();
    uint8_t state = SDL_GetMouseState(NULL, NULL);
    mrb_value buttons = mrb_ary_new(mrb);
    int i;
    for (i = 1; i <= 3; i++) {
        if (state & SDL_BUTTON(i)) {
            mrb_ary_push(mrb, buttons, mrb_fixnum_value(i));
        }
    }
    return buttons;
}

void api_init(mrb_state *mrb)
{
    sym_init(mrb);

    mrb_define_method(mrb, mrb->kernel_module, "color", api_color, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "clear", api_clear, ARGS_NONE());
    mrb_define_method(mrb, mrb->kernel_module, "point", api_point, ARGS_REQ(2));
    mrb_define_method(mrb, mrb->kernel_module, "line", api_line, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "box", api_box, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "circle", api_circle, ARGS_REQ(3) | ARGS_OPT(1));
    mrb_define_method(mrb, mrb->kernel_module, "polygon", api_polygon, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "text", api_text, ARGS_REQ(3));
    mrb_define_method(mrb, mrb->kernel_module, "time", api_time, ARGS_NONE());
    mrb_define_method(mrb, mrb->kernel_module, "delay", api_delay, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "display", api_display, ARGS_NONE());
    mrb_define_method(mrb, mrb->kernel_module, "keys", api_keys, ARGS_NONE());
    mrb_define_method(mrb, mrb->kernel_module, "mouse_position", api_mouse_position, ARGS_NONE());
    mrb_define_method(mrb, mrb->kernel_module, "mouse_buttons", api_mouse_buttons, ARGS_NONE());

    mrb_define_const(mrb, mrb->kernel_module, "SCREEN_WIDTH", mrb_fixnum_value(screen_width));
    mrb_define_const(mrb, mrb->kernel_module, "SCREEN_HEIGHT", mrb_fixnum_value(screen_height));
}
