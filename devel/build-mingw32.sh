#!/bin/bash -exu
rm -rf mruby.build screen12-win32

git clone mruby mruby.build
make -C mruby.build

make -C mruby clean
PKG_CONFIG_PATH=/usr/i486-mingw32/lib/pkgconfig make clean all CC=i486-mingw32-gcc LL=i486-mingw32-gcc AR=i486-mingw32-ar MRBC=$PWD/mruby.build/bin/mrbc

mkdir screen12-win32
cp screen12 screen12-win32/screen12.exe
cp /usr/i486-mingw32/bin/{SDL.dll,SDL_gfx.dll,SDL_image.dll,SDL_mixer.dll,zlib1.dll,libpng15-15.dll} screen12-win32/
cp lib.rb screen12-win32/
mkdir screen12-win32/resources
cp `git ls-tree -r --name-only HEAD resources` screen12-win32/resources/
mkdir screen12-win32/examples
cp examples/*.rb screen12-win32/examples/

zip -r screen12-win32.zip screen12-win32
