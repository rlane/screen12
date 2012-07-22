#ifndef _MAIN_H
#define _MAIN_H

#include <stdint.h>
#include <SDL.h>

extern SDL_Surface *screen;
extern uint32_t color;
extern int screen_width, screen_height;
extern int audio_sampling_freq, audio_max_amp;
extern int random_seed;

#endif
