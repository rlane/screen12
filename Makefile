MRUBY := mruby
BIN := foo

CFLAGS := -I $(MRUBY)/include -Wall
LDFLAGS := -static
LDLIBS := -L $(MRUBY)/lib -l mruby -lm

all: $(BIN)

$(BIN): main.o
	$(CC) $(LDFLAGS) -o $@ $< $(LDLIBS)

main.o: main.c | $(MRUBY)/lib/libmruby.a

clean:
	rm -f $(BIN) *.o

$(MRUBY)/lib/libmruby.a:
	make -C $(MRUBY)
