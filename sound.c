#include <stdio.h>
#include <assert.h>
#include <SDL.h>
#include <SDL_mixer.h>

#include "sound.h"

#define SOUND_TABLE_SIZE 1024

static struct sound *sound_table[SOUND_TABLE_SIZE];

/*
 * HACK
 * We need to store some additional data with the Mix_Chunk, so we take
 * advantage of it being publicly defined and wrap it in struct sound.
 * This function takes ownership of the passed Mix_Chunk.
 */
struct sound *sound_create(Mix_Chunk *chunk)
{
    struct sound *sound = malloc(sizeof(*sound));
    sound->refcount = 1;
    sound->chunk = *chunk;
    SDL_free(chunk);
    //fprintf(stderr, "created sound %p\n", sound);
    return sound;
}

void sound_release(struct sound *sound)
{
    //fprintf(stderr, "releasing sound %p\n", sound);
    if (--sound->refcount <= 0) {
        //fprintf(stderr, "freeing sound %p\n", sound);
        SDL_free(sound->chunk.abuf);
        SDL_free(sound);
    }
}

int sound_table_insert(struct sound *sound)
{
    int i;
    for (i = 0; i < SOUND_TABLE_SIZE; i++) {
        if (sound_table[i] == NULL) {
            sound_table[i] = sound;
            sound->refcount++;
            return i;
        }
    }
    return -1;
}

struct sound *sound_table_lookup(int handle)
{
    if (handle < 0 || handle >= SOUND_TABLE_SIZE) {
        return NULL;
    }

    struct sound *sound = sound_table[handle];
    if (sound) {
      assert(sound->refcount > 0);
      sound->refcount++;
      //fprintf(stderr, "acquired sound %p\n", sound);
    }
    return sound;
}

void sound_table_remove(int handle)
{
    if (handle < 0 || handle >= SOUND_TABLE_SIZE) {
        return;
    }

    struct sound *sound = sound_table[handle];
    sound_release(sound);
    sound_table[handle] = NULL;
}
