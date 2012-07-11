#ifndef _SURFACE_TABLE_H
#define _SURFACE_TABLE_H

#include <SDL.h>

int surface_table_insert(SDL_Surface *surface);
SDL_Surface *surface_table_lookup(int handle);
void surface_table_remove(int handle);

#endif
