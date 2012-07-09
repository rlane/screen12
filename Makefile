MRUBY := mruby
BIN := screen12

PKGS := sdl SDL_gfx
OBJS := screen12.o api.o

CFLAGS := -I $(MRUBY)/include -g -Os -Wall -Werror $(shell pkg-config --cflags $(PKGS))
LDFLAGS :=
LDLIBS := -L $(MRUBY)/lib -l mruby $(shell pkg-config --libs $(PKGS)) -lm

all: $(BIN)

$(BIN): $(OBJS) | $(MRUBY)/lib/libmruby.a

clean:
	rm -f $(BIN) *.o *.d

$(MRUBY)/lib/libmruby.a:
	make -C $(MRUBY)
