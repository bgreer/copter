#include <stdlib.h>
#include "SDL.h"
#include <stdio.h>
#include <math.h>

int main (int argc, char* argv[])
{
	SDL_Surface *screen;
	SDL_Event event;
	SDL_Joystick *joy;
	int quit;

	/* init video */
	if (SDL_Init(SDL_INIT_AUDIO|SDL_INIT_VIDEO|SDL_INIT_JOYSTICK) < 0)
	{
		printf("Unable to init SDL: %s\n", SDL_GetError());
		exit(EXIT_FAILURE);
	}

	/* at exit, call SDL quit */
	atexit(SDL_Quit);

	/* video settings */
	screen = SDL_SetVideoMode(400, 400, 16, SDL_SWSURFACE);
	if (screen == NULL)
	{
		printf("Unable to set video: %s\n", SDL_GetError());
		exit(EXIT_FAILURE);
	}

	/* grab pointer to screen buffer? */
	if (SDL_MUSTLOCK(screen))
	{
		SDL_UnlockSurface(screen);
	}

	/* get joystick */
	if (SDL_NumJoysticks()>0)
	{
		joy=SDL_JoystickOpen(0);
		if (joy)
		{
			printf("Opened joystick:\n");
			printf("\tName: %s\n", SDL_JoystickName(0));
		} else {
			printf("Could not open joystick.\n");
			exit(EXIT_FAILURE);
		}
	}

	/* loop until quit */
	quit = 0;
	while (!quit)
	{
		
		/* check SDL events */
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
				case SDL_QUIT:
					quit = 1;
					break;
				case SDL_KEYDOWN:
					handleKeydown(event.key.keysym.sym);
					break;
				case SDL_KEYUP:
					break;
				case SDL_JOYAXISMOTION:
					handleJoystick(event.jaxis.axis, event.jaxis.value);
					break;
				case SDL_JOYBUTTONDOWN:
					handleJoybuttondown(event.jbutton.button);
					break;
				case SDL_JOYBUTTONUP:
					handleJoybuttonup(event.jbutton.button);
					break;
			}
		}
	}

	/* close joystick connection */
	if (SDL_JoystickOpened(0))
		SDL_JoystickClose(joy);

	printf("Exiting.\n");
	return EXIT_SUCCESS;
}
