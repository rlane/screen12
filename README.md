Screen12
========

Screen12 is a game programming environment intended to get children interested in programming. The user writes code in the popular Ruby language and can call functions to draw basic shapes and take input from the user. This is enough to implement simple but fun games like the classic QBasic Nibbles and Gorillas. The idea is that children get hooked by playing the games, then find out they can change the rules and eventually write their own.

The ultimate goal is to have a web-based IDE with Screen12 integrated via Google Native Client, plus a way for users to share their games and let their friends play them with one click on a link. Right now only a command line / SDL interface is implemented.

What does "Screen12" mean?
--------------------------

`SCREEN 12` was the QBasic command to get a high-resolution (640x480) 16-color display. Screen12 was inspired by my own experience getting hooked by programming with QBasic, as well as the stalled Load81 project by Salvatore Sanfilippo.

Installation
------------

You need SDL and SDL_gfx installed.

 - Ubuntu: `sudo apt-get install libsdl1.2-dev libsdl-gfx1.2-dev`
 - Arch Linux: `sudo pacman -Sy sdl sdl_gfx`

Just run "make" in the source directory and you'll get a "screen12" binary.

Usage
-----

`./screen12 examples/pong.rb`

There are several games available to try in the examples directory.

API
---

 - `color(r, g, b, a)`: Sets the current color.
 - `clear`: Overwrite the whole screen with the current color.
 - `line(x1, y1, x2, y2, aa: bool)`: Draw a line.
 - `box(x1, y1, x2, y2, fill: bool)`: Draw a rectangle.
 - `circle(x, y, radius, fill: bool, aa: bool)`: Draw a circle.
 - `polygon([x1, y1, x2, y2, ...], aa: bool, fill: bool, position: [x,y],
   rotation: angle)`: Draw a polygon. The coordinates are given as an array.
 - `text(x, y, string)`: Draw text.
 - `delay(msecs)`: Sleep for the given number of milliseconds.
 - `flip`: Display the results of preceeding drawing commands to the user. This
   function should be removed and done implicitly.
 - `pressed_keys = keys`: Get an array with the names of the keys currently
   being pressed.
 - `SCREEN_WIDTH`, `SCREEN_HEIGHT`: Size of the screen. Always 800x600 to
   ensure games work across all computers.

TODO
----

 - More example games
 - Improve debugging
 - Framerate display
 - Clear screen API
 - Centered option for text
 - Point set/get API
 - Mouse input
 - Keyboard prompt input
 - Sound
 - Remove need for flip
 - Time API
 - Sprites
 - Draw to sprite
 - Fast assembly language equivalent
 - Move Ruby execution into its own thread
 - Decide between callback or main-loop programming model
 - Decide between keyword arguments or OpenGL-style state
 - Tutorials
 - Native Client port
 - Web-based IDE
 - Chrome app
 - Gallery to view other users' games

LICENSE
-------

Released under the BSD two-clause license. See COPYING for details.
