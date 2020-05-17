CFLAGS = -O3 -g -std=gnu11 -Isrc -DLUA_USE_POPEN
LFLAGS = -L src/lib/luajit/src -lSDL2 -lluajit -lm

objects = src/lib/stb/stb_truetype.o src/api/compat-5.3.o src/api/api.o src/api/renderer.o \
	src/api/renderer_font.o src/api/system.o src/rencache.o src/renderer.o \
	src/lib/amoeba/lua_amoeba.o \
	src/lib/stb/stb_image.o

all: $(objects) src/lib/luajit/src/libluajit.a
	$(CC) $(CFLAGS) $(LFLAGS) -o app $(objects) src/main.c

$(objects): %.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

src/lib/luajit/src/libluajit.a:
	$(MAKE) -C src/lib/luajit

clean:
	rm $(objects)
	$(MAKE) -C src/lib/luajit clean

test:
	busted -m ./data/?.lua data/**/*.test.lua