
FLAGS = -O0
LIBS = -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -L/usr/lib -lSDL -lSDL_ttf -L/usr/local/lib/ -lSDL_draw

basestation : main.c keyboard.c windows.c header.h
	gcc ${FLAGS} ${LIBS} -o basestation main.c keyboard.c windows.c -lm

clean :
	rm -f *.o basestation
