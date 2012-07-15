#ifndef _SOUND_H
#define _SOUND_H

#include <SDL.h>
#include <SDL_mixer.h>

struct sound {
  Mix_Chunk chunk;
  int refcount;
};

struct sound *sound_create(Mix_Chunk *chunk);
void sound_release(struct sound *sound);

int sound_table_insert(struct sound *sound);
struct sound *sound_table_lookup(int handle);
void sound_table_remove(int handle);

#endif
