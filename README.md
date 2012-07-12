Screen12
========

Screen12 is a game programming environment intended to get children interested in programming. The user writes code in the popular Ruby language and can call functions to draw basic shapes and take input from the user. This is enough to implement simple but fun games like the classic QBasic Nibbles and Gorillas. The idea is that children get hooked by playing the games, then find out they can change the rules and eventually write their own.

The ultimate goal is to have a web-based IDE with Screen12 integrated via Google Native Client, plus a way for users to share their games and let their friends play them with one click on a link. Right now only a command line / SDL interface is implemented.

What does "Screen12" mean?
--------------------------

`SCREEN 12` was the QBasic command to get a high-resolution (640x480) 16-color display. Screen12 was inspired by my own experience getting hooked by programming with QBasic, as well as the stalled Load81 project by Salvatore Sanfilippo.

Installation
------------

You need SDL, SDL_gfx, and SDL_image installed.

 - Ubuntu: `sudo apt-get install libsdl1.2-dev libsdl-gfx1.2-dev libsdl-image1.2-dev`
 - Arch Linux: `sudo pacman -Sy sdl sdl_gfx sdl_image`

To build the project:

```
git submodule update --init
make
```

You'll end up with a screen12 binary in the project's directory.

Usage
-----

`./screen12 examples/pong.rb`

There are several games available to try in the examples directory.

API
---

 - `color(r, g, b, a)`: Sets the current color.
 - `clear`: Set the whole screen to black.
 - `point(x, y)`: Draw a single pixel.
 - `line(x1, y1, x2, y2, aa: bool)`: Draw a line.
 - `box(x1, y1, x2, y2, fill: bool)`: Draw a rectangle.
 - `circle(x, y, radius, fill: bool, aa: bool)`: Draw a circle.
 - `polygon([x1, y1, x2, y2, ...], aa: bool, fill: bool, position: [x,y],
   rotation: angle)`: Draw a polygon. The coordinates are given as an array.
 - `text(x, y, string)`: Draw text.
 - `image(name, x, y)`: Draw a predefined image.
 - `msecs = time`: Return the number of milliseconds since the program started.
 - `delay(msecs)`: Sleep for the given number of milliseconds.
 - `display`: Display the results of preceeding drawing commands to the user. This
   function should be removed and done implicitly.
 - `pressed_keys = keys`: Get an array with the names of the keys currently
   being pressed.
 - `x, y = mouse_position`: Get the current mouse position.
 - `pressed_buttons = mouse_buttons`: Get an array with the mouse buttons
   currently being pressed. 1 = left, 2 = middle, 3 = right.
 - `SCREEN_WIDTH`, `SCREEN_HEIGHT`: Size of the screen. Always 800x600 to
   ensure games work across all computers.

Development
-----------

If you'd like to contribute to the project please fork rlane/screen12 on GitHub and send me a pull request. Also feel free to add bugs and feature requests to the issue tracker on GitHub.

Example code
------------

An important (and fun!) part of this project is writing games for new users to play and tinker with. We need to make sure that this code is simple and readable enough that someone with no programming experience can by trial and error make his own small changes. It's a challenge to make games fun and engaging while limiting complexity.

Below are a few recommendations for example code. These won't be enforced strictly. We may decide to group the example code into collections with more or less complexity. Many of these points are entirely at odds with good software engineering practices but serve to limit the number of abstractions the user has to wade through.

 - Avoid classes and use hashes instead.
 - Avoid indirect control flow. The user should be able to read the code from
   top to bottom and understand exactly what's going on.
 - Prefer redundant inline code to small helper methods.
 - Limit examples to 500 lines of code, excluding whitespace and comments. Less
   is better.
 - Prefer procedural programming techniques rather than object-oriented or
   functional.
 - Write many comments and use full sentences in simple language.
 - Put as many interesting tunable values as possible as constants at the top
   of the program with clear descriptive names.
 - Organize functions in the order they'll be called during the main loop.
 - Global variables are allowed and even encouraged.

TODO
----

 - More example games
 - Improve debugging
 - Document library functions
 - Framerate display
 - Centered option for text
 - Pixel read API
 - Keyboard prompt input
 - Sound
 - Remove need for `display`
 - Sprites
 - Draw to sprite
 - Fast assembly language equivalent
 - Move Ruby execution into its own thread
 - Decide between callback or main-loop programming model
 - Decide between keyword arguments or OpenGL-style state
 - Decide between degrees and radians
 - Tutorials
 - Native Client port
 - Web-based IDE
 - Chrome app
 - Resource (image, sound) browser
 - Gallery to view other users' games

LICENSE
-------

Released under the BSD two-clause license. See COPYING for details.
