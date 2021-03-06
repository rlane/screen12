#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>
#include <stdbool.h>
#include <malloc.h>
#include <SDL.h>
#include <SDL_gfxPrimitives.h>
#include <SDL_image.h>
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
#include "surface_table.h"
#include "sound.h"

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
        rotation = mrb_float(rotation_arg) * 2*M_PI/360;
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

/*
 * load_image(image_path, colorkey_red, colorkey_green, colorkey_blue)
 */
static mrb_value api_load_image(mrb_state *mrb, mrb_value self)
{
    mrb_value str;
    int kr, kg, kb;
    mrb_get_args(mrb, "oiii", &str, &kr, &kg, &kb);
    const char *path = mrb_string_value_cstr(mrb, &str);
    fprintf(stderr, "loading image %s\n", path);
    SDL_Surface *surface = IMG_Load(path);
    if (surface == NULL) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "failed to load image");
    }
    SDL_Surface *optimized_surface = SDL_DisplayFormat(surface);
    SDL_FreeSurface(surface);
    surface = NULL;
    if (optimized_surface == NULL) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "failed to optimize image");
    }
    if (kr >= 0) {
        Uint32 colorkey = SDL_MapRGB(optimized_surface->format, kr, kg, kb);
        SDL_SetColorKey(optimized_surface, SDL_SRCCOLORKEY, colorkey);
    }
    int surface_handle = surface_table_insert(optimized_surface);
    return mrb_fixnum_value(surface_handle);
}

static mrb_value api_free_surface(mrb_state *mrb, mrb_value self)
{
    int surface_handle;
    mrb_get_args(mrb, "i", &surface_handle);
    SDL_Surface *surface = surface_table_lookup(surface_handle);
    if (surface == NULL) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid surface handle");
    }
    surface_table_remove(surface_handle);
    SDL_FreeSurface(surface);
    return mrb_nil_value();
}

/*
 * api_blit(src_surface_handle, x, y, clip_x, clip_y, clip_w, clip_h);
 */
static mrb_value api_blit(mrb_state *mrb, mrb_value self)
{
    int src_surface_handle, x, y, cx = 0, cy = 0, cw = -1, ch = -1;
    mrb_get_args(mrb, "iii|iiii", &src_surface_handle, &x, &y, &cx, &cy, &cw, &ch);
    SDL_Surface *src_surface = surface_table_lookup(src_surface_handle);
    if (src_surface == NULL) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid source surface handle");
    }
    if (cw == -1) {
        cw = src_surface->w - cx;
    }
    if (ch == -1) {
        ch = src_surface->h - cy;
    }
    SDL_Rect clip = { .x = cx, .y = cy, .w = cw, .h = ch };
    SDL_Rect offset = { .x = x, .y = y };
    SDL_BlitSurface(src_surface, &clip, screen, &offset);
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

static void channel_finished_cb(int channel) {
    Mix_Chunk *chunk = Mix_GetChunk(channel);
    struct sound *sound = (struct sound *)chunk;
    //fprintf(stderr, "finished playing sound %p\n", sound);
    sound_release(sound);
}

static mrb_value api_load_sound(mrb_state *mrb, mrb_value self)
{
    mrb_value pathobj;
    mrb_get_args(mrb, "o", &pathobj);
    const char *path = mrb_string_value_cstr(mrb, &pathobj);
    fprintf(stderr, "loading sound %s\n", path);
    Mix_Chunk *chunk = Mix_LoadWAV(path);
    if (!chunk) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "sound not found");
    }

    struct sound *sound = sound_create(chunk);
    assert(sound);
    
    int sound_handle = sound_table_insert(sound);
    sound_release(sound);
    if (sound_handle == -1) {
        mrb_raise(mrb, E_ARGUMENT_ERROR /* XXX */, "too many sounds loaded");
    }

    return mrb_fixnum_value(sound_handle);
}

static mrb_value api_load_raw_sound(mrb_state *mrb, mrb_value self)
{
    mrb_value samples;
    mrb_get_args(mrb, "o", &samples);
    mrb_check_type(mrb, samples, MRB_TT_ARRAY);
    int n = RARRAY_LEN(samples);
    if (n == 0) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "empty samples array");
    }

    int16_t *tmp_samples = SDL_malloc(n * sizeof(*tmp_samples));
    assert(tmp_samples);
    mrb_value *samples_ptr = RARRAY_PTR(samples);
    int i;
    for (i = 0; i < n; i++) {
        mrb_value sample = samples_ptr[i];
        mrb_check_type(mrb, sample, MRB_TT_FIXNUM);
        tmp_samples[i] = mrb_fixnum(sample);
    }

    Mix_Chunk *chunk = Mix_QuickLoad_RAW((uint8_t*)tmp_samples, n * sizeof(*tmp_samples));
    assert(chunk);

    struct sound *sound = sound_create(chunk);
    assert(sound);
    
    int sound_handle = sound_table_insert(sound);
    sound_release(sound);
    if (sound_handle == -1) {
        mrb_raise(mrb, E_ARGUMENT_ERROR /* XXX */, "too many sounds loaded");
    }

    return mrb_fixnum_value(sound_handle);
}

static mrb_value api_release_sound(mrb_state *mrb, mrb_value self)
{
    int sound_handle;
    mrb_get_args(mrb, "i", &sound_handle);
    struct sound *sound = sound_table_lookup(sound_handle);
    if (sound == NULL) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid sound handle");
    }

    sound_table_remove(sound_handle);
    sound_release(sound);
    return mrb_nil_value();
}

static mrb_value api_play_sound(mrb_state *mrb, mrb_value self)
{
    int sound_handle;
    mrb_get_args(mrb, "i", &sound_handle);
    struct sound *sound = sound_table_lookup(sound_handle);
    if (sound == NULL) {
        mrb_raise(mrb, E_ARGUMENT_ERROR, "invalid sound handle");
    }

    if (Mix_PlayChannel(-1, &sound->chunk, 0) < 0) {
        /* No available channels. Ignore the error. */
        sound_release(sound);
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
    Mix_ChannelFinished(channel_finished_cb);
    Mix_AllocateChannels(256);

    sym_init(mrb);

    mrb_define_method(mrb, mrb->kernel_module, "color", api_color, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "clear", api_clear, ARGS_NONE());
    mrb_define_method(mrb, mrb->kernel_module, "point", api_point, ARGS_REQ(2));
    mrb_define_method(mrb, mrb->kernel_module, "line", api_line, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "box", api_box, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "circle", api_circle, ARGS_REQ(3) | ARGS_OPT(1));
    mrb_define_method(mrb, mrb->kernel_module, "polygon", api_polygon, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "text", api_text, ARGS_REQ(3));
    mrb_define_method(mrb, mrb->kernel_module, "load_image", api_load_image, ARGS_REQ(4));
    mrb_define_method(mrb, mrb->kernel_module, "free_surface", api_free_surface, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "blit", api_blit, ARGS_REQ(7));
    mrb_define_method(mrb, mrb->kernel_module, "time", api_time, ARGS_NONE());
    mrb_define_method(mrb, mrb->kernel_module, "delay", api_delay, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "load_sound", api_load_sound, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "load_raw_sound", api_load_raw_sound, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "release_sound", api_release_sound, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "play_sound", api_play_sound, ARGS_REQ(1));
    mrb_define_method(mrb, mrb->kernel_module, "display", api_display, ARGS_NONE());
    mrb_define_method(mrb, mrb->kernel_module, "keys", api_keys, ARGS_NONE());
    mrb_define_method(mrb, mrb->kernel_module, "mouse_position", api_mouse_position, ARGS_NONE());
    mrb_define_method(mrb, mrb->kernel_module, "mouse_buttons", api_mouse_buttons, ARGS_NONE());

    mrb_define_const(mrb, mrb->kernel_module, "SCREEN_WIDTH", mrb_fixnum_value(screen_width));
    mrb_define_const(mrb, mrb->kernel_module, "SCREEN_HEIGHT", mrb_fixnum_value(screen_height));
    mrb_define_const(mrb, mrb->kernel_module, "AUDIO_SAMPLING_FREQ", mrb_fixnum_value(audio_sampling_freq));
    mrb_define_const(mrb, mrb->kernel_module, "AUDIO_MAX_AMP", mrb_fixnum_value(audio_max_amp));
    mrb_define_const(mrb, mrb->kernel_module, "RANDOM_SEED", mrb_fixnum_value(random_seed));
}
