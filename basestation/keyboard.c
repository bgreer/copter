#include "header.h"

int handleKeydown (SDLKey key)
{
	float tempin;
//	printf("keydown: %d\n", key);
	switch (key)
	{
		case SDLK_ESCAPE:
			printf("Caught Escape Keydown, exiting.\n");
			return -1;
			break;
	}
}

void handleTouch (int x, int y, window *w, int numwindows, copterinfo *c)
{
	int ii;

	for (ii=0; ii<numwindows; ii++)
	{
		w[ii].click(x, y, w+ii, c);
	}
}
