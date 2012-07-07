MRUBY := mruby
BIN := foo

PKGS := sdl SDL_gfx

CFLAGS := -I $(MRUBY)/include -Wall -Werror $(shell pkg-config --cflags $(PKGS))
LDFLAGS :=
LDLIBS := -L $(MRUBY)/lib -l mruby $(shell pkg-config --libs $(PKGS)) -lm

all: $(BIN)

$(BIN): main.o api.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)

main.o: main.c | $(MRUBY)/lib/libmruby.a

clean:
	rm -f $(BIN) *.o

$(MRUBY)/lib/libmruby.a:
	make -C $(MRUBY)
