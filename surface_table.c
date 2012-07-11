#include "surface_table.h"

#define SURFACE_TABLE_SIZE 1024

SDL_Surface *surface_table[SURFACE_TABLE_SIZE];

int surface_table_insert(SDL_Surface *surface)
{
    int i;
    for (i = 0; i < SURFACE_TABLE_SIZE; i++) {
        if (surface_table[i] == NULL) {
            surface_table[i] = surface;
            return i;
        }
    }
    return -1;
}

SDL_Surface *surface_table_lookup(int handle)
{
    if (handle < 0 || handle >= SURFACE_TABLE_SIZE) {
        return NULL;
    }

    return surface_table[handle];
}

void surface_table_remove(int handle)
{
    if (handle < 0 || handle >= SURFACE_TABLE_SIZE) {
        return;
    }

    surface_table[handle] = NULL;
}
